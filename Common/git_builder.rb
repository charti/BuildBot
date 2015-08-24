require 'git'
require 'date'
require 'yaml'
require 'logger'
require 'rake'

class GitBuilder
  def initialize(repo_config)
    @paths = { :config => File.expand_path(repo_config, $project_root + '/ProjectConfigurations/')}
    @config = YAML.load(File.read(@paths[:config]))
    @logger = create_logger(:system)
    @logger.info("Start Build Process with configuration: #{@paths[:config]}")
    load_git
    get_branch_commits
    puts @commits
  end
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
  def load_git
    if File.directory?("WorkingDir/repos/#{@config['Name']}/clone/#{@config['Name']}/.git")
      @git = Git.open(
        "WorkingDir/repos/#{@config['Name']}/clone/#{@config['Name']}/",
        :log => create_logger(:git))
      @git.fetch('origin')
    else
      @git = Git.clone(@config['Uri'], @config['Name'], :path => "WorkingDir/repos/#{@config['Name']}/clone")
    end
    @commits = { 'master' => @git.gcommit(@git.object(@config['ReleaseBranch']).sha) }
    @git.reset_hard(@commits['master'])
    @logger.info("Git Repo: #{@config['Name']} successfully loaded")
  end
	def get_branch_commits
		@config['MergeBranches'].each do |branch|
      begin
        commits = get_commits(branch) if @git.object(branch)
        @commits[branch] = commits unless commits.empty?
      rescue
        @logger.error("No Head for Remote Branch: #{branch}. Check #{@paths[:config]}")
      end
		end
  end
  def get_commits(branch)
    commits = Array.new
    parent = @git.gcommit(@git.object(branch).sha)
    until parent.sha == @commits['master'].sha
      commits << parent
      parent = @git.gcommit(parent.parent)
    end
    if commits.empty?
      @logger.debug("Branch: '#{branch}' has no commits to merge.")
      return nil
    else
      return commits
    end
  end
end