require 'git'
require 'yaml'
require 'logger'
require 'rake'
require_relative 'jira_worker'
require_relative '../Rake/build'

class GitBuilder

	attr_reader :git, :commits, :config, :paths

	# @param [String] repo_config 'filename.yaml'
	def initialize(repo_config)
		initialize_config(repo_config)
		@jira = JiraWorker.new
	end

	def start
		LOGGER.info(:Git) { "Start CI Process with configuration: '#{@paths[:config]}'" }
		load_git
		load_branch_story
	end

	# Creates a new [Logger] for 'target' in log dir.
	# @param [Symbol] target
	# @return Logger
	def create_logger(target)
		unless @paths[:log].nil?
			@paths.store(:log, Hash.new)
			@paths[:log].store(:r, File.expand_path("WorkingDir/log/#{@config[:Name]}/"))
			FileUtils.mkpath @paths[:log][:r]
		end
		unless @paths[:log].key?(target)
			@paths[:log].store(target, "#{@paths[:log][:r]}/#{target}-#{Time.new.strftime("%Y-%m-%d_%H%M%S")}.log")
			return Logger.new(@paths[:log][target])
		end
	end

	def all_commits_do
		@commits.each_pair do |branch, commits|
			next unless commits.is_a?(Array)

			LOGGER.info(:Git) { "Check Branch '#{branch}' #{commits.last}..#{commits.first}" }

			commits.reverse_each do |commit|
				LOGGER.info(:Git) { "Check #{commit}" }
				@git.merge(commit)

				begin
					yield branch, commit
					@merge_branches << branch
				rescue
					LOGGER.error(:Merge) { "Skipping #{branch} for merging. Reason:#{commit.to_s}" +
							"\n\t#{commit.author.name}: #{commit.author.email}\n\t#{commit.message.to_s}" }
					@merge_branches -= [branch]
					break
				end

			end

			# rebase --hard to +ReleaseBranch+ Commit
			@git.reset_hard(@commits[:master].sha)
		end unless @commits.nil?
	end

	def merge_branches(new_version=nil)
		merged = Array.new
		if @merge_branches.empty?
			LOGGER.info(:Git) { "There are no qualified branches to merge. Please consult the log for the reason." }
			return nil
		end
		@merge_branches.each do |branch|
			begin
				@git.merge(branch, "Merge remote-tracking branch #{branch} into #{@git.current_branch}")
				LOGGER.debug(:Git) { "Merge remote-tracking branch #{branch} into #{@git.current_branch}" }
				merged << branch
			rescue => e
				LOGGER.error(:Git) { "Could not merge Branch: '#{branch}'\n\t#{e.message.gsub!(/[\r\n]+/, "\n\t")}" }
				@git.reset_hard(@git.current_branch)
			end
			puts merged
		end
		remotes = @git.remotes
		master  = @git.remote('cc/master')

		@git.add_tag(new_version) unless new_version.nil?
		@git.push(@config[:Remote], @git.current_branch)
		return merged
	end

	private

	def initialize_config(repo_config)
		@paths  = { :config => File.expand_path(repo_config, 'ProjectConfigurations/') }
		@config = YAML.load(File.read(@paths[:config]))

		paths = { :log      => File.expand_path(@config[:Name], 'WorkingDir/log/'),
							:internal => File.expand_path(@config[:Name], 'WorkingDir/internal/'),
							:external => File.expand_path(@config[:Name], 'WorkingDir/external/'),
							:source   => File.expand_path(@config[:Name], 'WorkingDir/repos/'),
							:IIS      => File.expand_path('WorkingDir/IIS') }

		paths.each_pair do |k, v|
			@paths.store(k, v)
		end
	end

	# Finds all commits from given Branch down to the +ReleaseBranch+ Head.
	# @param [String] branch
	# @return [Array]
	def get_commit_story(branch)
		commits = Array.new
		@git.log.between(@git.object(@config[:ReleaseBranch]).sha, @git.object(branch).sha)
				.each { |commit| commits << commit }
		commits
	end

	# Loads +@git+ as [Git::Base]
	# Clones the repo if necessary. Fetches changes from remote and resets --hard to +ReleaseBranch+
	def load_git
		@paths.store(:git, File.expand_path("WorkingDir/repos/#{@config[:Name]}/.git"))
		unless File.directory?(@paths[:git])
			Git.clone(@config[:Uri], @config[:Name], { :path   => "WorkingDir/repos",
																								 :branch => @config[:ReleaseBranch].sub("#{@config[:Remote]}/", '') })
		end

		@git = Git.open("WorkingDir/repos/#{@config[:Name]}",
										:log => create_logger(:git))
		@git.fetch(@config[:Remote])
		@commits = { :master => @git.gcommit(@git.object(@config[:ReleaseBranch])) }
		@git.reset_hard(@commits[:master].sha)

		LOGGER.info(:Git) { "#{@config[:Name]} successfully loaded on Branch: #{@git.current_branch}" }
	end

	# Gets the commit story of all +MergeBranches+, who are ahead of +ReleaseBranch+
	def load_branch_story
		@config[:MergeBranches].each do |branch|
			begin
				commits = get_commit_story(branch) if @git.object(branch)
				unless commits.empty?
					@commits[branch] = commits
				else
					LOGGER.debug(:Git) { "No commits found. Branch: #{branch} is not ahead of #{@config[:ReleaseBranch]}" }
				end
			rescue
				LOGGER.error(:Git) { "Branch: '#{branch}' doesn't exist." }
			end
		end

		msg = @commits.keys.keep_if { |k| @commits[k].is_a?(Array) }
		LOGGER.info(:Git) { "Branches to merge: #{msg}" }
	end

end