require 'rake'
require 'fileutils'
require 'logger'


task :init => [:run]

directory '../WorkingDir' do |t|
	FileUtils.makedirs %w<../WorkingDir/external ../WorkingDir/internal ../WorkingDir/log ../WorkingDir/IIS>
end

directory '../Tools' do
	mkdir '../Tools'
end

task :run => ['../WorkingDir', '../Tools', :setup]

task :setup do |t, args|
	LOGGER = init_system_log

	LOGGER.info(:Setup) { "\n\n#{'=' * 80}\n#{ARGV[0] + '.rb'}" }

end

def init_system_log
	mkdir_p "../WorkingDir/log/#{ARGV[0]}"

	sys_log = Logger.new("../WorkingDir/log/#{ARGV[0]}/" +
											 "system#{Time.new.strftime("%Y-%m-%d")}.log", 'daily')
	sys_log.formatter = proc do |severity, datetime, progname, msg|
		"#{severity[0]},\t[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{progname}: #{msg}\n"
	end

	#STDOUT.reopen File.new(File::NULL, 'w')

	sys_log
end