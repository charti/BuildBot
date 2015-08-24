require 'git'
require 'date'
require 'yaml'
require 'logger'
require 'rake'
require 'pathname'

class GitBuilder

	attr_reader :git, :commits, :config, :paths

	# @param [String] repo_config 'filename.yaml'
	def initialize(repo_config)
    @paths = { :config => File.expand_path(repo_config, $project_root + '/ProjectConfigurations/')}
    @config = YAML.load(File.read(@paths[:config]))
    @logger = create_logger(:system)
    @logger.info("Start Build Process with configuration: #{@paths[:config]}")
    load_git
    load_branch_story
  end

  # Creates a new [Logger] for 'target' in log dir.
  # @param [Symbol] target
  # @return [Logger]
  def create_logger(target)
    unless @paths.key?(:log)
      @paths.store(:log, Hash.new)
      @paths[:log].store(:r, "WorkingDir/log/#{@config['Name']}/")
      FileUtils.mkpath @paths[:log][:r]
    end
    unless @paths[:log].key?(target)
      @paths[:log].store(target, "#{@paths[:log][:r]}#{target}-#{Time.new.strftime("%Y-%m-%d_%H%M%S")}.log")
      return Logger.new(@paths[:log][target])
    end
    raise "targeted Logger #{target} already exists!"
  end

  private
  # Loads '@git' as [Git::Base']
  # Clones the repo if necessary. Fetches changes from remote and resets --hard to
  # 'ReleaseBranch'
  def load_git
		@paths.store(:git, File.dirname("#{$project_root}/WorkingDir/repos/" +
		                                "#{@config['Name']}/clone/#{@config['Name']}/.git/*"))
		unless File.directory?(@paths[:git])
			Git.clone(@config['Uri'], @config['Name'], { :path   => "WorkingDir/repos/#{@config['Name']}/clone",
			                                             :branch => @config['ReleaseBranch'].slice!("@config['Remote']/") })
		end

		@git = Git.open("WorkingDir/repos/#{@config['Name']}/clone/#{@config['Name']}", :log => create_logger(:git))
    @git.fetch(@config['Remote'])
		@commits = { 'master' => @git.gcommit(@git.object(@config['ReleaseBranch'])) }
		@git.reset_hard(@commits['master'].sha)

    @logger.info("Git Repo: #{@config['Name']} successfully loaded on Branch: #{@git.current_branch}")
  end

  # Gets the commit story of all 'MergeBranches', who are ahead of @config'ReleaseBranch'
	def load_branch_story
		@config['MergeBranches'].each do |branch|
      begin
        commits = get_commit_story(branch) if @git.object(branch)
        @commits[branch] = commits unless commits.empty?
      rescue
        @logger.error("No Head for Remote Branch: #{branch}. Check #{@paths[:config]}")
      end
		end
  end

  # Finds all commits from given Branch down to the 'ReleaseBranch' Head.
  # @param [String] branch
  # @return [Array]
  def get_commit_story(branch)
    commits = Array.new
    parent = @git.gcommit(@git.object(branch).sha)
    until parent.sha == @commits['master'].sha
      commits << parent
      parent = @git.gcommit(parent.parent)
    end
    commits.empty?
    @logger.debug("Branch: '#{branch}' has no commits to merge.") if commits.empty?
    return commits
  end
end