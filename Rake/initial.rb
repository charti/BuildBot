require 'rake'
require 'fileutils'
require 'logger'
require 'net/http'
require 'zip/zip'
require 'open-uri'
require 'open_uri_redirections'

require_relative '../Common/git_builder'

task :default => [:run]

directory 'WorkingDir' do
	FileUtils.makedirs %w<WorkingDir/external WorkingDir/internal WorkingDir/log>
end

directory 'Tools' do
	mkdir 'Tools'
end

task :run => ['WorkingDir', :setup] do
	config = 'invers.yaml'
	LOGGER.info(:RAKE) { "Task ':run' started with configuration '#{config}'" }
	gb = GitBuilder.new(config)
end#

task :setup => %w<WorkingDir Tools> do
	PROJECT_ROOT = File.expand_path './'

	STDOUT.reopen File.new(File::NULL, 'w')

	LOGGER = Logger.new('system.log', 'daily')
	LOGGER.formatter  = proc do |severity, datetime, progname, msg|
		"#{severity[0]},\t[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{progname}: #{msg}\n"
	end
end