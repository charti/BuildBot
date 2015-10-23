require 'rake'
require 'tempfile'
require 'yaml'

require_relative '../lib/git'

# Globally available Methods. They can be considered as helpers.
module Tools
  module Generate
    def self.rake_application
      FileList.new('../lib/rake/*.rake').each do |file|
        Rake.load_rakefile(file)
      end
			return Rake.application
    end
  end


	def self.edit_file(src, out = src, &block)
		edited = [ ]

    if File.exist?(src)
			File.open(src, 'r') do |file|
        block.call(file)
        puts file
			end
		else
			raise "The File #{src} doesn't exist."
		end

		# File.open(out, 'w') do |file|
		# 	edited.each { |line| file.write(line) }
		# end
		# if File.exist?(src)
		# 	File.open(src, 'r').readlines.each do |line|
		# 		edit = yield line
		# 		edited << edit
		# 	end
		# else
		# 	raise "The File #{src} doesn't exist."
		# end
    #
		File.open(out, 'w') do |file|
			edited.each { |line| file.write(line) }
		end

	end
end

module VirtualPipeMethods

	def build_commit
    false
	end

	def test_commit
    false
	end

	def increase_version
    false
	end

	def publish_branch
    false
	end

end

module BuildMethods

  def build_all_commits
    git.all_commits_do do |branch, commit|
      @versioning_required = branch != @current_branch
      @current_branch = branch
      @current_commit = commit
      puts @current_branch, @current_commit
      build_commit
    end
  end

  def build_binary(csproj)
    begin
      @tasks[:execute].invoke(self, csproj, :binary, @current_branch,
                              @current_commit, @versioning_required)
    rescue => e
      puts e
    end
  end

  def build_web_application(csproj)
    begin
      @tasks[:execute].invoke(self, csproj, :web_application, @current_branch,
                              @current_commit, @versioning_required)
    rescue => e
      puts e
    end
  end

end


module PipeMethods
	include VirtualPipeMethods, BuildMethods

  def start
    self.setup
    @tasks = Tools::Generate.rake_application
    @tasks[:init].invoke

    setup_repo
    build_all_commits
  end

  def setup_repo
    @git = GitWorker.new( { :repo => @repo,
                            :uri => @uri,
                            :target_branch => @target_branch,
                            :base_branch => @base_branch,
                            :branches_to_build => @branches_to_build } )
  end

end

class BasePipe
	include PipeMethods

  attr_accessor :repo,
                :uri,
                :target_branch,
                :base_branch,
                :branches_to_build,
                :build_type,
                :git,
                :tasks

  def initialize
    puts 'Pipe init'
    start
  end

end