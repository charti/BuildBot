require 'rake'
require 'albacore'

require '../configs/' + ARGV[0]

task :execute, :pipe, :csproj, :build_type, :current_branch, :current_commit do |t, args|
  args.each {|name, value| instance_variable_set("@#{name}", value)}
  begin
    @pipe.tasks[:start].invoke
  ensure
    @pipe.tasks[:start].all_prerequisite_tasks.each { |prereq| prereq.reenable }
    @pipe.tasks[:start].reenable
    @pipe.tasks[@build_type].reenable
    t.reenable
  end
  puts t
end

#TODO restliche abh�ngigkeiten
task :start => [:build] do |t|
  puts t
end

task :build => [:versioning, :copy_configs] do|t|
  puts t.name
  br = @current_branch.gsub('/','_')
  unless Dir.exist?("#{@pipe.git.paths[:log][:r]}/build/#{br}")
    mkdir_p %W(#{@pipe.git.paths[:log][:r]}/build/#{br} #{@pipe.git.paths[:internal]}/#{br}) #{@pipe.git.paths[:external]}/#{br}
  end
  @pipe.before_build

  begin
    @pipe.tasks[@build_type].invoke
  rescue => e
    puts e.message
    COUNTER += 1
  end
end

#TODO versioning
task :versioning do |t|
  puts "#{t} #{@pipe.versioning_required.to_s}"
  if @pipe.versioning_required

    assemblies = FileList.new("#{@pipe.git.paths[:source]}/*/AssemblyInfo.cs").each do |path|
      new_assembly = ""

      File.read(path).each_line do |line|
        version_type = /(AssemblyVersion|AssemblyFileVersion)/.match(line)
        if (version_type.nil? || line.include?('//'))
          new_assembly << line
        else
          @new_version = ""
          version      = /(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)[-\.](?<revision>[a-zA-Z\-\d+]+)/.match(line)

          @new_version = @pipe.increase_version(version)
          unless @new_version =~ /\d/
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
  config_examples = FileList.new("#{@pipe.git.paths[:source]}/*.config.example")
  next if config_examples.empty?

  config_examples.each do |example|
    dest = example.sub('.example', '')
    cp(example, dest)
    LOGGER.debug(:Copy) { "Copied #{example} to #{dest}" }
  end
end

build :binary do |msb|
  br = @current_branch.gsub('/', '_')

  msb.file = Dir.glob("#{@pipe.git.paths[:source]}/#{@csproj}").first
  msb.target = [:Build]
  msb.prop :Configuration, 'Release'
  msb.prop :DebugType, 'pdbonly'

  msb.prop :DebugType, 'pdbonly'
  msb.prop :ExcludeGeneratedDebugSymbol, false
  msb.add_parameter "/flp:LogFile=#{File.join("#{@pipe.git.paths[:log][:r]}/build/#{br}/",
                                              "#{@current_commit}.log")};Verbosity=detailed;"
  msb.cores = 2
  msb.prop :Outdir, "#{@pipe.git.paths[:internal]}/#{br}/#{@current_commit}/"
  msb.nologo
end

build :web_application do |msb|
  br = @current_branch.gsub('/', '_')

  msb.sln = Dir.glob("#{@pipe.git.paths[:source]}/#{@csproj}").first
  msb.prop 'WarningLevel', 2
  msb.cores  = 2
  msb.target = [:Build]

  msb.prop :Configuration, 'Release'
  msb.prop :DebugType, 'pdbonly'
  msb.prop :PrecompileBeforePublish, true
  msb.prop :EnableUpdateable, false
  msb.prop :AutoParameterizationWebConfigConnectionStrings, false
  msb.prop :ExcludeGeneratedDebugSymbol, false
  msb.prop :WebPublishMethod, 'FileSystem'
  msb.prop :DeleteExistingFiles, true
  msb.prop :DebugSymbols, true
  msb.prop :DeleteAppCodeCompiledFiles, true
  msb.prop :UseMerge, @merge
  msb.prop :WDPMergeOption, 'MergeAllOutputsToASingleAssembly'
  msb.prop :SingleAssemblyName, 'MergedHttpHandler'
  msb.prop :UseWPP_CopyWebApplication, true
  msb.prop :PipelineDependsOnBuild, false
  msb.prop :Webprojectoutputdir, "#{@pipe.git.paths[:IIS]}"
  msb.prop :Outdir, "#{@pipe.git.paths[:internal]}/#{br}/#{@current_commit}"
  msb.add_parameter "/flp:LogFile=#{File.join("#{@pipe.git.paths[:log][:r]}/build/#{br}/",
                                              "#{@current_commit}.log")};Verbosity=detailed;"
end