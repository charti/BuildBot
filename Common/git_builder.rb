require 'git'
require 'date'
require 'yaml'
require 'logger'

class GitBuilder
  def initialize(repo_config)
    @paths = Hash.new
    @config = YAML.load(File.read(File.expand_path(repo_config, $project_root + '/ProjectConfigurations/')))
    load_git
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
    @branch = Array.new
		@config['Branches'].each { |branch| @branch << @git.branch(branch) }
		@remote = @git.remotes.each {|remote| remote}
    @git.reset_hard('origin/master')

    first = @git.gcommit(@git.object('origin/master').sha)
    @testObject = @git.object('origin/cc/test')
    puts "CC/TEST: #{@testObject.sha}"
    found = false
    parent = @git.gcommit(@testObject.sha)
    @commits = Array.new
    @commits << parent.sha
    i = 0
    puts "MASTERCOMMIT: #{first.sha}"
    until found
      i      = i + 1
      parent = @git.gcommit(parent.parent)
      puts "PARENT #{i.to_s}: #{parent.sha}\nequals: #{parent.sha == first.sha}"
      found = parent.sha == first.sha
      unless found
        found = false
        @commits << parent.sha
      else
        found = true
      end
    end

		puts "#{@commits}\n\n\n"

		puts"\n\n\n COUNT #{i} #{@commits}"
  end
end