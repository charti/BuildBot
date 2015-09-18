require 'rake'
require 'fileutils'
require 'logger'
require 'net/http'
require 'zip/zip'
require 'open-uri'
require 'open_uri_redirections'

require_relative '../Common/git_builder'
require_relative '../Rake/build'


task :default, [:config] => [:run]

directory 'WorkingDir' do
	FileUtils.makedirs %w<WorkingDir/external WorkingDir/internal WorkingDir/log>
end

directory 'Tools' do
	mkdir 'Tools'
end

task :run, [:config] => ['WorkingDir', :setup] do
  # config = 'invers.yaml'
  #
  # LOGGER.info(:RAKE) { "Task ':run' started with configuration '#{config}'" }
  # gb = GitBuilder.new(config)

  Rake.application[:execute_pipeline].invoke
end

task :setup, [:config] => %w<WorkingDir Tools> do |t, args|
  PROJECT_ROOT = File.expand_path './'

  LOGGER = Logger.new('system.log') #, 'daily'
	LOGGER.formatter  = proc do |severity, datetime, progname, msg|
		"#{severity[0]},\t[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{progname}: #{msg}\n"
  end

  config = args[:config]
  LOGGER.info(:RAKE) { "Task ':run' started with configuration '#{config}'" }
  GB = GitBuilder.new(config)

  #STDOUT.reopen File.new(File::NULL, 'w')
end