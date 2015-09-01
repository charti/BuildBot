require 'git'
require 'date'
require 'yaml'
require 'logger'
require 'rake'
require_relative '../Rake/build'

class GitBuilder

	attr_reader :git, :commits, :config, :paths, :logger

	# @param [String] repo_config 'filename.yaml'
	def initialize(repo_config)
		initilize_config(repo_config)
    @logger = create_logger(:system)
    @logger.info("Start Build Process with configuration: #{@paths[:config]}")
    load_git
    load_branch_story
    each_branch_check
  end

  def check_commits(branch)
    @commits[branch].each do |commit|
      commit_merge_ff(commit)
      Rake::Task(:default).invoke(self)
    end
  end

  # Creates a new [Logger] for 'target' in log dir.
  # @param [Symbol] target
  # @return Logger
  def create_logger(target)
    unless @paths[:log].nil?
      @paths.store(:log, Hash.new)
      @paths[:log].store(:r, File.expand_path("WorkingDir/log/#{@config['Name']}/"))
      FileUtils.mkpath @paths[:log][:r]
    end
    unless @paths[:log].key?(target)
      @paths[:log].store(target, "#{@paths[:log][:r]}/#{target}-#{Time.new.strftime("%Y-%m-%d_%H%M%S")}.log")
      return Logger.new(@paths[:log][target])
    end
    raise "targeted Logger #{target} already exists!"
  end

  # Is the Head in detached state?
  def detached?
    @git.describe('HEAD', {:all => true}) != 'heads/master'
  end

  def checkout_commit(commit)
    sha = commit.is_a?(Git::Object::Commit) ? commit.sha : commit
    @git.checkout(sha)
    @logger.debug("Detached Head while checkout commit: #{sha}") if detached?
  end

  def commit_merge_ff(commit)
    @git.merge(commit)
  end

	# Merges -ff each Commit on each Branch and tries to build each Commit to WorkingDir/internal/'CommitSha'
  def each_branch_check
    # each branches commits, except start commit
		@commits.each_pair do |branch, commits|
			next unless commits.is_a?(Array)

      @logger.debug("Check Branch #{branch}")

			commits.reverse_each do |commit|
        @logger.debug("check commit: #{commit}")
        @git.merge(commit)

        # build Commit
        Rake.application[:default].invoke(self, commit)
			end

			# rebase --hard to +ReleaseBranch+ Commit
			@git.reset_hard(@commits['master'].sha)
    end
  end

  private
  # Loads +@git+ as [Git::Base]
  # Clones the repo if necessary. Fetches changes from remote and resets --hard to +ReleaseBranch+
  def load_git
		@paths.store(:git, File.dirname("#{$project_root}/WorkingDir/repos/" +
		                                "#{@config['Name']}/.git/*"))
		unless File.directory?(@paths[:git])
			Git.clone(@config['Uri'], @config['Name'], { :path   => "WorkingDir/repos",
			                                             :branch => @config['ReleaseBranch'].slice!("@config['Remote']/") })
		end

		@git = Git.open("WorkingDir/repos/#{@config['Name']}",
                    :log => create_logger(:git))
    @git.fetch(@config['Remote'])
		@commits = { 'master' => @git.gcommit(@git.object(@config['ReleaseBranch'])) }
		@git.reset_hard(@commits['master'].sha)

    @logger.info("Git Repo: #{@config['Name']} successfully loaded on Branch: #{@git.current_branch}")
  end

  # Gets the commit story of all +MergeBranches+, who are ahead of +ReleaseBranch+
	def load_branch_story
		@config['MergeBranches'].each do |branch|
      begin
        commits = get_commit_story(branch) if @git.object(branch)
        @commits[branch] = commits unless commits.empty?
      rescue
        @logger.error("No Head found for Remote Branch: #{branch}. Check #{@paths[:config]}")
      end
		end
  end

  # Finds all commits from given Branch down to the +ReleaseBranch+ Head.
  # @param [String] branch
  # @return [Array]
  def get_commit_story(branch)
    commits = Array.new
    @git.log.between(@git.object(@config['ReleaseBranch']).sha, @git.object(branch).sha)
        .each { |commit| commits << commit }
    commits
  end

	def initilize_config(repo_config)
		@paths = { :config => File.expand_path(repo_config, $project_root + '/ProjectConfigurations/') }
		@config = YAML.load(File.read(@paths[:config]))
		@paths = { :log => File.expand_path(@config['Name'], $project_root + '/WorkingDir/log/'),
               :internal => File.expand_path(@config['Name'], $project_root + '/WorkingDir/internal/'),
               :external => File.expand_path(@config['Name'], $project_root + '/WorkingDir/external/'),
               :source => File.expand_path(@config['Name'], $project_root + '/WorkingDir/repos/') }
	end

end