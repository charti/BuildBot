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
			File.open(src, 'r').readlines.each do |line|
				edit = yield line
				edited << edit
			end
		else
			raise "The File #{src} doesn't exist."
		end

		File.open(out, 'w') do |file|
			edited.each { |line| file.puts(line) }
		end
	end
end

module VirtualPipeMethods

  def before_build msb
    false
  end

  def before_test nunit
    false
  end

	def increase_version version
    false
	end

	def publish_branch
    false
	end

end

module BuildMethods

  def build_all_commits
    git.all_commits do |branch, commit|
			@versioning_required = branch != @current_branch
			@current_branch = branch
			@current_commit = commit
			puts "#{@current_branch} #{@current_commit}"
			begin
				build_commit
			rescue => e
				LOGGER.error(:Build) { e.message.gsub(/[^\S\r\n]{2,}/, '').gsub(/[\r\n]+/, "\n\t") }
				@git.skip_branch(branch)
			end
    end
	end

	def merge_branches
    reset_branch = @base_branch
    @versioning_required = true
    git.merge_branches(@new_version)
    # git.merge_branches(@new_version) do |branch, commit, merged|
    #   next unless merged
		#
    #   @current_branch = branch
    #   @current_commit = commit
    #   begin
    #     build_commit
    #     reset_branch = @target_branch
    #   rescue => e
    #     LOGGER.error(:Build) { "merge failed #{e.message.gsub(/[^\S\r\n]{2,}/, '').gsub(/[\r\n]+/, "\n\t")}" }
    #     @git.reset_to reset_branch
    #   end
    # end
	end

  def build_binary(csproj, test_csproj='')
    begin
      @tasks[:execute].invoke(self, csproj, test_csproj, :binary, @current_branch,
                              @current_commit, @versioning_required)
    rescue => e
      puts e
			raise e
    end
  end

  def build_web_application(csproj, test_csproj='')
    begin
      @tasks[:execute].invoke(self, csproj, test_csproj, :web_application, @current_branch,
                              @current_commit, @versioning_required)
    rescue => e
      puts e
      raise e
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

		merge_branches
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
                :tasks,
                :versioning_required,
                :new_version,
                :publish

  def initialize
    puts 'Pipe init'
    @new_version = nil
    @publish = false
    start
  end

end