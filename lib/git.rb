require 'git'
require 'date'
require 'logger'
require 'rake'
#require_relative '../Rake/build'

class GitWorker

	attr_reader :git, :commits, :config, :paths

	# @param [String] repo_config 'filename.yaml'
	def initialize(repo_config)
		initialize_config(repo_config)
    LOGGER.info(:Git) {"Start Build Process with configuration: '#{@paths[:config]}'"}
    load_git
    load_branch_story
  end

  # Creates a new [Logger] for 'target' in log dir.
  # @param [Symbol] target
  # @return Logger
  def create_logger(target)
    unless @paths[:log].nil?
      @paths.store(:log, Hash.new)
      @paths[:log].store(:r, File.expand_path("../WorkingDir/log/#{@config[:repo]}/"))
      FileUtils.mkpath @paths[:log][:r]
    end
    unless @paths[:log].key?(target)
      @paths[:log].store(target, "#{@paths[:log][:r]}/#{target}-#{Time.new.strftime("%Y-%m-%d_%H%M%S")}.log")
      return Logger.new(@paths[:log][target])
    end
    raise "targeted Logger #{target} already exists!"
  end

  def commit_merge_ff(commit)
    @git.merge(commit)
  end

  def all_commits_do
    @commits.each_pair do |branch, commits|
      next unless commits.is_a?(Array)

      LOGGER.info(:Git) { "Check Branch '#{branch}' #{commits.last}..#{commits.first}" }

      commits.reverse_each do |commit|
        LOGGER.info(:Git) {"Check #{commit}"}
        @git.merge(commit)

        yield branch, commit
      end

      # rebase --hard to +ReleaseBranch+ Commit
      @git.reset_hard(@commits[:master].sha)
      @git.reset_hard(@commits[:master].sha)
    end unless @commits.nil?
  end

  private
  # Loads +@git+ as [Git::Base]
  # Clones the repo if necessary. Fetches changes from remote and resets --hard to +ReleaseBranch+
  def load_git
		@paths.store(:git, File.dirname('../WorkingDir/repos/' +
		                                "#{@config[:repo]}/.git/*"))
		unless File.directory?(@paths[:git])
      Git.clone(@config[:uri], @config[:repo], { :path   => "../WorkingDir/repos",
                                                 :branch => @config[:base_branch] })
		end

		@git = Git.open("../WorkingDir/repos/#{@config[:repo]}",
                    :log => create_logger(:git))
    @git.fetch('origin')
		@commits = { :master => @git.gcommit(@git.object('origin/' + @config[:base_branch])) }
		@git.reset_hard(@commits[:master].sha)

    LOGGER.info(:Git) { "#{@config[:repo]} successfully loaded on Branch: #{@git.current_branch}" }
  end

  # Gets the commit story of all +MergeBranches+, who are ahead of +ReleaseBranch+
	def load_branch_story
		@config[:branches_to_build].each do |branch|
      begin
        commits = get_commit_story(branch)
        unless commits.empty?
          @commits[branch] = commits
        else
          LOGGER.debug(:Git) {"No commits found. Branch: #{branch} is not ahead of #{@config[:ReleaseBranch]}"}
        end
      rescue
        LOGGER.error(:Git) { "Branch: '#{branch}' doesn't exist." }
      end
		end

		msg = @commits.keys.keep_if { |k| @commits[k].is_a?(Array) }
		LOGGER.info(:Git) { "Branches to merge: #{msg}" }
  end

  # Finds all commits from given Branch down to the +ReleaseBranch+ Head.
  # @param [String] branch
  # @return [Array]
  def get_commit_story(branch)
    commits = Array.new
    @git.log.between(@commits[:master].sha, @git.object('origin/' + branch).sha)
        .each { |commit| commits << commit }
    commits
  end

	def initialize_config(repo_config)
		@config = repo_config

    @paths = { :log => File.expand_path(@config[:repo], '../WorkingDir/log/'),
							:internal => File.expand_path(@config[:repo], '../WorkingDir/internal/'),
							:external => File.expand_path(@config[:repo], '../WorkingDir/external/'),
							:source => File.expand_path(@config[:repo], '../WorkingDir/repos/'),
							:IIS => File.expand_path('WorkingDir/IIS') }


		# paths.each_pair do |k, v|
		# 	@paths.store(k, v)
		# end
	end

end