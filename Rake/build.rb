require 'rake'
require 'albacore'

require 'find'

task :build, [:gb, :current_commit] => [:init, :do_work] do |t|
	t.reenable
end

task :init, [:gb, :current_commit] do |t, args|
  $gb = args[:gb]
  $commit_sha = args[:current_commit]
  FileList['**/*.example'].each do |src|
    file 'C:/something.bla' => src do
      puts 'bla'
    end
  end
  mkdir_p "#{$gb.paths[:log][:r]}/build"
	t.reenable
end

task :do_work do |t|
	build_type = "build_types:#{$gb.config['Type']}"

	[build_type].each do |task_name|
		begin
			Rake.application[task_name].invoke
			LOGGER.info(task_name) { "Commit #{$commit_sha} task execution was successful." }
			Rake.application['testing:nunit'].invoke
		rescue => e
			LOGGER.error(task_name) { "Commit #{$commit_sha} task execution failed failed:" +
					"#{e.message.gsub!(/[^\S\r\n]{2,}/, '').gsub!(/[\r\n]+/, "\n\t")}" }
		end
		Rake.application[task_name].reenable
		Rake.application['testing:nunit'].reenable
	end

	t.reenable
end

namespace :testing do

  test_runner :nunit do |tr|
    tr.files = FileList["WorkingDir/internal/#{$gb.config['Name']}/#{$commit_sha}/*test*dll"]
    tr.exe = 'Tools/nunit/bin/nunit-console.exe'
  end

end

namespace :build_types do

  build :binary do |msb|
		msb.sln  = Dir.glob("#{$gb.paths[:source]}/*.sln").first

    msb.target = [ :Clean, :Build ]
		msb.add_parameter "/flp:LogFile=#{File.join("#{$gb.paths[:log][:r]}/build",
		                                            "#{$commit_sha}.log")};Verbosity=Detailed;"
	  msb.cores = 2
	  msb.prop :Outdir, "#{$gb.paths[:internal]}/#{$commit_sha}"
	  msb.nologo
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
    msb.nologo
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