require 'rake'
require 'tempfile'
require 'yaml'

require_relative '../lib/git'

# Globally available Methods. They can be considered as helpers.
module Tools
  module Generate
    def self.rake_application
			Rake.load_rakefile('../lib/rake/initial.rake')
			Rake.application[:init].invoke
			return Rake.application
    end
  end


	def self.edit_file(src, out = src)
		edited = [ ]

		if File.exist?(src)
			File.open(src, 'r') do |file|
				edited = yield file
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
		# File.open(out, 'w') do |file|
		# 	edited.each { |line| file.write(line) }
		# end

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
    rake = Tools::Generate.rake_application
    setup_repo

  end

  def setup_repo
    config = Hash.new
    instance_variables.each do |klass_var|
      var = klass_var.to_s.delete('@').to_sym
      config.store(var, instance_variable_get(klass_var))
    end

    @git = GitWorker.new(config)
  end

end

class BasePipe
	include PipeMethods

  attr_accessor :repo, :uri,
                :target_branch, :base_branch,
                :branches_to_build

  def initialize
    # @repo = 'repo'
    # @target_branch = 'target_branch'
    # @base_branch = 'base_branch'
    # @branches_to_build = %w<branches to build>
    puts 'Pipe init'
    start
  end

end