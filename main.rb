require File.dirname(__FILE__) + '/Common/git_builder.rb'
require File.dirname(__FILE__) + '/RepoScripts/libtachoweb.yaml'
require 'git'
require 'fileutils'
require 'rake'
require 'albacore'

task :default => [:msbuild]

desc "MsBuild Task"
build :msbuild do |msb|
  msb.sln = "D:/Projects/svservice/svservice/svservice.sln"
  msb.target = ['Clean', 'Rebuild']
  msb.prop 'Configuration', 'Release'
  msb.prop 'WarningLevel', 2
  msb.cores = 4
  msb.logging = 'detailed'
  msb.prop 'Outdir', 'C:/test/bin/'
  msb.add_parameter "/flp:LogFile=#{log_file('build')}"
end

def log_file(log_file_name)
  log_file_name + ".log"
end

working_dir = File.absolute_path('D:/Bachelor/Build/libTachoweb')

$top_build_dir = File.absolute_path('D:/DailyBuild/git/')
$top_log_dir = File.absolute_path('D:/DailyBuild/logs/')
$archive_dir = File.absolute_path('D:/DailyBuild/archive/')

#create directories
[$top_build_dir, $top_log_dir, $archive_dir].each { |dir| FileUtils::makedirs(dir) unless File.exists?(dir) }



# Rake::Task[:default].invoke

puts "++++++++++++++++++++++" + working_dir

