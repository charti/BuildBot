require 'rake'
require 'albacore'

require '../configs/' + ARGV[0]

task :execute, [:pipe, :csproj, :unit_test,
                :build_type, :current_branch,
                :current_commit] do |t, args|
  args.each {|name, value| instance_variable_set("@#{name}", value)}
  @new_version = @pipe.new_version.nil? ? '' : @pipe.new_version
  begin
    @pipe.tasks[:start].invoke
    LOGGER.info(:Build) { "Build for Branch:#{@current_branch}, Commit:#{@current_commit.sha} was succesful." }
    @pipe.new_version = @new_version unless @new_version.empty?
  ensure
    @pipe.tasks[:start].all_prerequisite_tasks.each { |prereq| prereq.reenable }
    @pipe.tasks[:start].reenable
    @pipe.tasks[@build_type].reenable
    t.reenable
  end
  puts t
end

task :start => [:clean, :build, :unit_test, :inspections] do |t|
  puts t
end

task :clean do |t|
	#mv "#{@pipe.git.paths[:internal]}/*CodeAnalysisLog.xml", "@git.paths[:log][:r]/#{}"
  FileUtils.rm_rf(Dir.glob("#{@pipe.git.paths[:internal]}/*"))
  FileUtils.rm_rf(Dir.glob("#{@pipe.git.paths[:IIS]}/*"))
end

task :build => [:versioning, :copy_configs] do|t|
  puts t.name
  br = @current_branch.gsub('/','_')
  unless Dir.exist?("#{@pipe.git.paths[:log][:r]}/build/")
    mkdir_p %W(#{@pipe.git.paths[:log][:r]}/build/ #{@pipe.git.paths[:internal]}/
								#{@pipe.git.paths[:log][:r]}/inspections/) #{@pipe.git
		# .paths[:external]}/#{br}
  end
  @pipe.before_build

  @pipe.tasks[@build_type].invoke

	puts :test
end

task :versioning do |t|
  puts "#{t} #{@pipe.versioning_required.to_s}"
  if @pipe.versioning_required

    assemblies = FileList.new("#{@pipe.git.paths[:source]}/*/Properties/AssemblyInfo.cs")
                     .each do |path|
      new_assembly = ""

      File.read(path).each_line do |line|
        version_type = /(AssemblyVersion|AssemblyFileVersion)/.match(line)
        if (version_type.nil? || line.include?('//'))
          new_assembly << line
        else
          version = /(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)[-\.](?<revision>[a-zA-Z\-\d+]+)/
                        .match(line)

          @new_version = @pipe.increase_version(version) if @new_version.empty?
          unless @new_version =~ /\d+/
            @new_version = "#{version[1]}.#{version[2]}.#{version[3]}." +
                "#{version[4].to_i + 1}"
          end

          new_assembly << line.gsub(/(?<=")(.*)(?=")/, @new_version)
        end
      end
      File.write(path, new_assembly)
    end
    LOGGER.info(:Versioning) { "Bumped version for Assemblies:\n\t#{assemblies * "\n\t"}" }
  end
end

#TODO copy_configs
task :copy_configs do
  puts :copy_configs
  config_examples = FileList.new("#{@pipe.git.paths[:source]}/*/*.example")
  next if config_examples.empty?

  config_examples.each do |example|
    dest = example.sub('.example', '')
    cp(example, dest)
    LOGGER.debug(:copy_configs) { "Copied #{example} to #{dest}" }
  end
end

task :unit_test => [:test_project, :nunit]

test_runner :nunit do |tr|
  br = @current_branch.gsub('/', '_')
  dir = @build_type.eql?(:binary) ? "#{@pipe.git.paths[:internal]}" : "#{@pipe.git.paths[:IIS]}"
	test_file = "#{dir}/#{@unit_test.gsub(/csproj/, '*')}"

  tr.files = FileList[test_file].exclude {|f| File.absolute_path(f) unless /exe|dll/.match(f)}
  tr.exe   = File.absolute_path '../Tools/nunit/bin/nunit-console.exe'
	tr.add_parameter "/result=#{@pipe.git.paths[:log][:r]}/build/#{@current_commit}-test_result.xml"
	tr.add_parameter "/nologo"
end

build :binary do |msb|
  br = @current_branch.gsub('/', '_')

  msb.file = Dir.glob("#{@pipe.git.paths[:source]}/*/#{@csproj}").first
  msb.target = [:Build]
  msb.prop :Configuration, 'Release'
  msb.prop :DebugType, 'pdbonly'

  msb.prop :DebugType, 'pdbonly'
  msb.prop :ExcludeGeneratedDebugSymbol, false
  msb.add_parameter "/flp:LogFile=#{File.join("#{@pipe.git.paths[:log][:r]}/build/",
                                              "#{@current_commit}-#{@csproj}.log")};Verbosity=detailed;"
	#msb.add_parameter "/p:RunCodeAnalysis=True;CodeAnalysisRuleSet=AllRules.ruleset"
  msb.cores = 2
  msb.prop :Outdir, "#{@pipe.git.paths[:internal]}/"
  msb.nologo
end

build :web_application do |msb|
  br = @current_branch.gsub('/', '_')

  msb.file = Dir.glob("#{@pipe.git.paths[:source]}/*/#{@csproj}").first
  msb.prop 'WarningLevel', 2
  msb.cores  = 2
  msb.target = [:Build]

	if @pipe.publish
    msb.prop :PrecompileBeforePublish, true
    msb.prop :WebPublishMethod, 'FileSystem'
    msb.prop :UseMerge, true
    msb.prop :WDPMergeOption, 'MergeAllOutputsToASingleAssembly'
    msb.prop :SingleAssemblyName, 'MergedHttpHandler'
    msb.prop :UseWPP_CopyWebApplication, true
    msb.prop :Webprojectoutputdir, "#{@pipe.git.paths[:external]}"
	end

  msb.prop :Configuration, 'Release'
  msb.prop :DebugType, 'pdbonly'
  msb.prop :EnableUpdateable, false
  msb.prop :AutoParameterizationWebConfigConnectionStrings, false
  msb.prop :ExcludeGeneratedDebugSymbol, false
  msb.prop :DeleteExistingFiles, true
  msb.prop :DebugSymbols, true
  msb.prop :DeleteAppCodeCompiledFiles, true
  msb.prop :PipelineDependsOnBuild, false
  msb.prop :Outdir, "#{@pipe.git.paths[:IIS]}/"
  msb.add_parameter "/flp:LogFile=#{File.join("#{@pipe.git.paths[:log][:r]}/build/",
                                              "#{@current_commit}-#{@csproj}.log")};Verbosity=detailed;"
  #msb.add_parameter "/p:RunCodeAnalysis=True;CodeAnalysisRuleSet=AllRules.ruleset"
end

build :test_project do |msb|
  br = @current_branch.gsub('/', '_')

  msb.file = Dir.glob("#{@pipe.git.paths[:source]}/*/#{@unit_test}").first
  msb.target = [:Build]
  msb.prop :Configuration, 'Release'
  msb.prop :DebugType, 'pdbonly'

  msb.prop :DebugType, 'pdbonly'
  msb.prop :ExcludeGeneratedDebugSymbol, false
  msb.add_parameter "/flp:LogFile=#{File.join("#{@pipe.git.paths[:log][:r]}/build/",
                                              "#{@current_commit}-#{@unit_test}.log")};Verbosity=detailed;"
  msb.cores = 2
  msb.prop :Outdir, @build_type.eql?(:binary) ? "#{@pipe.git.paths[:internal]}/" : "#{@pipe.git.paths[:IIS]}/"
  msb.nologo
end

task :inspections do |t|
	begin
		dir = @build_type.eql?(:binary) ? "#{@pipe.git.paths[:internal]}" : "#{@pipe.git.paths[:IIS]}"
		case_insansitive = File::FNM_CASEFOLD
		files = Dir.glob("#{dir}/#{@csproj.gsub('.csproj', '')}.{exe,dll}", case_insansitive)

		files.each do |file|
			basename = File.basename(file)
			system *%W(
      ../Tools/FxCop/metrics.exe /f:#{file}
			/o:#{@pipe.git.paths[:log][:r]}/inspections/#{@current_commit}-#{basename}.xml )
		end
	rescue => e
		LOGGER.error(:Build) { "Inspections failed: #{e.message}" }
	end
end