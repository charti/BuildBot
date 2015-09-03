require 'rake'
require 'albacore'

require 'find'

task :default, [:gb, :current_commit] => [:init, :clean, :do_work] do |t|
	t.reenable
end

task :init, [:gb, :current_commit] do |t, args|
  $gb = args[:gb]
  $commit_sha = args[:current_commit]
  mkdir_p "#{$gb.paths[:log][:r]}/build"
	t.reenable
end

task :clean

task :do_work do |t|
	Rake.application["build_types:#{$gb.config['Type']}"].invoke
  Rake.application["build_types:#{$gb.config['Type']}"].reenable
	t.reenable
end

namespace :build_types do

  build :binary do |msb|
		msb.sln  = Dir.glob("#{$gb.paths[:source]}/*.sln").first

    msb.target = [ :Clean, :Build ]
		msb.add_parameter "/flp:LogFile=#{File.join("#{$gb.paths[:log][:r]}/build",
		                                            "#{$commit_sha}.log")};Verbosity=Detailed;"
	  msb.cores = 2
	  msb.prop :Outdir, "#{$gb.paths[:internal]}/#{$commit_sha}"
  end

  build :web_application do |msb|
    msb.sln = Dir.glob("#{$gb.paths[:source]}/*.sln").first
    msb.target = ['Clean', 'Rebuild']
    msb.prop :Configuration, 'Release'
    msb.prop :WarningLevel, 2
    msb.prop :Outdir, "#{$gb.paths[:internal]}/#{$commit_sha}"
    msb.cores = 2
    msb.add_parameter "/flp:LogFile=#{File.join("#{$gb.paths[:log][:r]}/build",
                                                "#{$commit_sha}.log")};Verbosity=Detailed;"
  end

end

namespace :publish_types do

  build :web_application do |msb|
    msb.sln = Dir.glob("#{$gb.paths[:source]}/*.sln").first
    msb.prop 'WarningLevel', 2
    msb.cores = 2
    msb.target = ['Clean', 'Rebuild']

    msb.prop :Configuration, 'Release'
    msb.prop :PrecompileBeforePublish, true
    msb.prop :EnableUpdateable, false
    msb.prop :WDPMergeOption, 'MergeAllOutputsToASingleAssembly'
    msb.prop :SingleAssemblyName, 'MergedHttpHandler.dll'
    msb.prop :UseWPP_CopyWebApplication, true
    msb.prop :PipelineDependsOnBuild, false
    msb.prop :Outdir, "#{$gb.paths[:internal]}/#{$commit_sha}"
    msb.prop :Webprojectoutputdir, "#{$gb.paths[:external]}/#{$commit_sha}"
    msb.add_parameter "/flp:LogFile=#{log_file('publish')}"
  end

end