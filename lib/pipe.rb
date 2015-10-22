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


	def self.edit_file(src, out = src)
		edited = [ ]

		if File.exist?(src)
			File.open(src, 'r') do |file|
				edited_line = yield file
        edited << edited_line
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

	# def	setup_repo
  #
	# end

	def build_commit

	end

	def test_commit

	end

	def increase_version

	end

	def publish_branch

	end

end


module PipeMethods
	include VirtualPipeMethods

  def start
    self.setup
    @tasks = Tools::Generate.rake_application
    @tasks[:init].invoke

    setup_repo
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
                :git,
                :tasks

  def initialize
    puts 'Pipe init'
    start
  end

end