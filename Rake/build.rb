require 'rake'
require 'albacore'
require_relative '../Common/git_builder'

#
# Albacore work flow controlling tasks
#
desc 'Iterates over any commit and invokes :start task.'
task :execute_pipeline do |t|
  puts t

  GB.all_commits_do do |branch, commit|
    @current_commit = commit
    @versioning_required = branch != @current_branch
    @current_branch = branch

    br = @current_branch.gsub('/','_')
    mkdir_p %W(#{GB.paths[:log][:r]}/build/#{br} #{GB.paths[:internal]}/#{br}
               #{GB.paths[:externel]}/#{br})

    puts "#{:all_commits_do} versioning_required:#{@versioning_required}"

    begin
      Rake.application[:start].invoke
      LOGGER.info(@current_branch) { "Commit #{@current_commit} check was successful." }
    rescue => e
      unless e.nil?
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

task :copy_configs do |t|
  config_examples = FileList.new("#{GB.paths[:source]}/**/*.config.example")
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

	tr.files = FileList["WorkingDir/internal/#{GB.config[:Name]}/#{br}/#{@current_commit}/*test*.dll"]
	tr.exe = 'Tools/nunit/bin/nunit-console.exe'
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
						break
					end
					new_version << "#{'.' unless group.to_sym.eql?(:revision)}"
				end

				(3 - new_version.count('.')).times { new_version << '.0'}

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
	br = @current_branch.gsub('/','_')

	msb.sln  = Dir.glob("#{GB.paths[:source]}/*.sln").first
	msb.target = [ :Clean, :Build ]
	msb.add_parameter "/flp:LogFile=#{File.join("#{GB.paths[:log][:r]}/build/#{br}/",
	                                            "#{@current_commit}.log")};Verbosity=detailed;"
	msb.cores = 2
	msb.prop :Outdir, "#{GB.paths[:internal]}/#{br}/#{@current_commit}/"
	msb.nologo
end

build :web_application do |msb|
	br = @current_branch.gsub('/','_')

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
	msb.prop :Outdir, "#{GB.paths[:internal]}/#{br}/#{@current_commit}"
	msb.prop :Webprojectoutputdir, "#{GB.paths[:IIS]}"
	msb.add_parameter "/flp:LogFile=#{log_file('publish')}"
end

def reenable_pipeline
	Rake.application[:start].all_prerequisite_tasks.each { |prereq| prereq.reenable }
	Rake.application[:start].reenable
end