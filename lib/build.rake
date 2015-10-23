require 'rake'
require 'albacore'

#
# Albacore work flow controlling tasks
#
desc 'Iterates over any commit and invokes :start task.'
task :execute_pipeline, :pipe, :csproj do |t, args|
  puts t
  @target_proj = args[:csproj]
  @pipe = args[:pipe]

  @pipe.all_commits_do do |branch, commit|
    @current_commit = commit
    @versioning_required = branch != @current_branch
    @current_branch = branch
    @merge = false

    br = @current_branch.gsub('/','_')
    mkdir_p %W(#{@pipe.git.paths[:log][:r]}/build/#{br} #{@pipe.git.paths[:internal]}/#{br}) #{@pipe.git.paths[:external]}/#{br}

    puts "#{:all_commits_do} versioning_required:#{@versioning_required}"

    begin
      @pipe.tasks[:start].invoke
      LOGGER.info(@current_branch) { "Commit #{@current_commit} check was successful." }
    rescue => e
      unless e.nil? || e.message.nil?
        LOGGER.error(@current_branch) { "Commit #{@current_commit} check failed:" +
                                    "#{e.message.gsub!(/[^\S\r\n]{2,}/, '').gsub!(/[\r\n]+/, "\n\t")}" }
      else
        LOGGER.unknown(@current_branch) { "#{e}" }
      end

      reenable_pipeline

			raise e

    end

    reenable_pipeline

  end

  @pipe.git.merge_branches(@new_version)
end

desc 'building => testing => deploying'
task :start => [:build,
                :test,
                :deploy] do |t|
end

desc 'versioning => compiling'
task :build => [:versioning, :copy_configs] do |t|
  puts t
	@pipe.tasks[@pipe.build_type].execute
	LOGGER.info(:Build) { 'Build was successful.' }
end

task :copy_configs do |t|
  config_examples = FileList.new("#{@pipe.git.paths[:source]}/**/*.config.example")
  next if config_examples.empty?

  puts t
  config_examples.each do |example|
    dest = example.sub('.example', '')
    cp(example, dest)
    LOGGER.debug(:Copy) { "Copied #{example} to #{dest}" }
  end
end

desc 'run unit tests'
task :test => :nunit do |t|
	LOGGER.info(:Test) { 'Testing was successful.' }
end

test_runner :nunit do |tr|
	br = @current_branch.gsub('/','_')

	tr.files = FileList["WorkingDir/internal/#{@pipe.git.config[:Name]}/#{br}/#{@current_commit}/*test*.dll"]
	tr.exe = 'Tools/nunit/bin/nunit-console.exe'
end

desc 'bumps version'
task :versioning do |t|
  next
	next unless @versioning_required
	puts t
	assemblies = FileList.new("#{@pipe.git.paths[:source]}/**/AssemblyInfo.cs").each do |path|
		new_assembly = ""

		File.read(path).each_line do |line|
			version_type = /(AssemblyVersion|AssemblyFileVersion)/.match(line)
			if(version_type.nil? || line.include?('//'))
				new_assembly << line
			else
				@new_version = ""
				version = /(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)[-\.](?<revision>[a-zA-Z\-\d+]+)/.match(line)

				version.names.each do |group|
					unless group.to_sym.eql?(@pipe.git.config[version_type[1].to_sym])
						@new_version << "#{version[group]}"
					else
						@new_version << "#{version[group].to_i + 1}"
						break
					end
					@new_version << "#{'.' unless group.to_sym.eql?(:revision)}"
				end

				(3 - @new_version.count('.')).times { @new_version << '.0'}

				new_assembly << line.gsub(/(?<=")(.*)(?=")/, @new_version)
			end
		end

		File.write(path, new_assembly)
	end

	LOGGER.info(:Versioning) {"Bumped version for Assemblies:\n\t#{assemblies * "\n\t"}"}
end

task :merge do |t|

end

desc 'deployes new version'
task :deploy do |t|
  puts t
end

build :binary do |msb|
	br = @current_branch.gsub('/','_')

	msb.sln  = Dir.glob("#{@pipe.git.paths[:source]}/*.sln").first
	msb.target = [:Clean, :Build]

  msb.prop :DebugType, 'pdbonly'
  msb.prop :ExcludeGeneratedDebugSymbol, false
	msb.add_parameter "/flp:LogFile=#{File.join("#{@pipe.git.paths[:log][:r]}/build/#{br}/",
	                                            "#{@current_commit}.log")};Verbosity=detailed;"
	msb.cores = 2
	msb.prop :Outdir, "#{@pipe.git.paths[:internal]}/#{br}/#{@current_commit}/"
	msb.nologo
end

build :web_application do |msb|
	br = @current_branch.gsub('/','_')

	msb.sln = Dir.glob("#{@pipe.git.paths[:source]}/*.sln").first
	msb.prop 'WarningLevel', 2
	msb.cores = 2
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

def reenable_pipeline
	Rake.application[:start].all_prerequisite_tasks.each { |prereq| prereq.reenable }
	Rake.application[:start].reenable
end