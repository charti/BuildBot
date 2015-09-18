require 'rake'
require 'albacore'
require_relative '../Common/git_builder'

#
# Albacore work flow controlling tasks
#
desc 'Iterates over any commit and invokes :start task.'
task :execute_pipeline do |t|
  puts t
  mkdir_p "#{GB.paths[:log][:r]}/build"

  GitBuilder.all_commits_do do |branch, commit|
    @current_commit = commit
    @versioning_required = branch != @current_branch
    @current_branch = branch

    puts "#{:all_commits_do} versioning_required:#{@versioning_required}"

    begin
      Rake.application[:start].invoke
      LOGGER.info(@current_branch) { "Commit #{@current_commit} check was successful." }
    rescue => e
      LOGGER.error(@current_branch) { "Commit #{@current_commit} check failed:" +
                                    "#{e.message.gsub!(/[^\S\r\n]{2,}/, '').gsub!(/[\r\n]+/, "\n\t")}" }
    end

    Rake.application[:start].all_prerequisite_tasks.each { |prereq| prereq.reenable }
    Rake.application[:start].reenable

  end
end

desc 'building => testing => deploying'
task :start => [:build, :test, :deploy] do |t|
end

desc 'versioning => compiling'
task :build => [:versioning, :copy_configs] do |t|
  puts t
	Rake.application[GB.config[:Type]].execute
	LOGGER.info(:Build) { 'Build was successful.' }
end

task :copy_configs => '.config' do |t|
	examples = FileList.new("#{GB.paths[:source]}/**/*.config.example")

	examples.each do |config|
		file config.sub('.example', '') => config do |dest|
			puts 'bla'
		end
		file 'foo.txt' => 'test.test' do
			touch 'foo.txt'
		end
	end

	file :configs => examples

end

file '.config' => FileList.new() do |t|
	puts :bla
end

desc 'run unit tests'
task :test do |t|
	puts t
	LOGGER.info(:Test) { 'Testing was successful.' }
end

desc 'bumps version'
task :versioning do |t|
	next unless @versioning_required
	puts t
	assemblies = FileList.new("#{GB.paths[:source]}/**/AssemblyInfo.cs").each do |path|
		new_assembly = ""

		File.read(path).each_line do |line|
			version_type = /(AssemblyVersion|AssemblyFileVersion)/.match(line)
			if(version_type.nil? || line.include?('//'))
				new_assembly << line
			else
				new_version = ""
				version = /(?<major>\d+)\.(?<minor>\d+)\.(?<build>\d+)\.(?<revision>[a-zA-Z\-\d+]+)/.match(line)

				version.names.each do |group|
					unless group.to_sym.eql?(GB.config[version_type[1].to_sym])
						new_version << "#{version[group]}"
					else
						new_version << "#{version[group].to_i + 1}"
					end
					new_version << "#{'.' unless group.to_sym.eql?(:revision)}"
				end

				new_assembly << line.gsub(/(?<=")(.*)(?=")/, new_version)
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
	msb.sln  = Dir.glob("#{GB.paths[:source]}/*.sln").first

	msb.target = [ :Clean, :Build ]
	msb.add_parameter "/flp:LogFile=#{File.join("#{GB.paths[:log][:r]}/build",
	                                            "#{@current_commit}.log")};Verbosity=detailed;"
	msb.cores = 2
	msb.prop :Outdir, "#{GB.paths[:internal]}/#{@current_commit}/"
	msb.nologo
end

build :web_application do |msb|
	msb.sln = Dir.glob("#{GB.paths[:source]}/*.sln").first
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
	msb.prop :Outdir, "#{GB.paths[:internal]}/#{@current_commit}"
	msb.prop :Webprojectoutputdir, "#{GB.paths[:external]}/#{@current_commit}"
	msb.add_parameter "/flp:LogFile=#{log_file('publish')}"
end