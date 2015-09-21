require 'rake'
require 'fileutils'
require 'logger'

require_relative '../Common/git_builder'
require_relative '../Rake/build'


task :default, [:config] => [:run]

directory 'WorkingDir' do
	FileUtils.makedirs %w<WorkingDir/external WorkingDir/internal WorkingDir/log WorkingDir/IIS>
end

directory 'Tools' do
	mkdir 'Tools'
end

task :run, [:config] => ['WorkingDir', :setup] do
	GB.start
  Rake.application[:execute_pipeline].invoke
end

task :setup, [:config] => %w<WorkingDir Tools> do |t, args|
  config = args[:config]

  GB = GitBuilder.new(config)

  LOGGER = init_system_log

  LOGGER.info(:Setup) { "\n\n#{'=' * 80}\n#{config}" }

end

def init_system_log
	mkdir_p "WorkingDir/log/#{GB.config[:Name]}"

	sys_log = Logger.new("WorkingDir/log/#{GB.config[:Name]}/" +
			           "system#{Time.new.strftime("%Y-%m-%d")}.log", 'daily')
	sys_log.formatter  = proc do |severity, datetime, progname, msg|
		"#{severity[0]},\t[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{progname}: #{msg}\n"
	end

	#STDOUT.reopen File.new(File::NULL, 'w')

	sys_log
end