require 'rake'
require 'albacore'

require 'find'

task :default, [:gb, :current_commit] => [:init, :do_work] do |t|
	t.reenable
end

task :init, [:gb, :current_commit] do |t, args|
  puts "in rake"
  $gb = args[:gb]
  $commit_sha = args[:current_commit]
  mkdir_p "#{$gb.paths[:log][:r]}/build"
	t.reenable
end

task :do_work do |t|
  puts "do_work"
	bla = Rake.application["build_types:#{$gb.config['Type']}"].invoke
  Rake.application["build_types:#{$gb.config['Type']}"].reenable
	t.reenable
end

namespace :build_types do

	asmver :versioning do
		puts "bla"
	end

  build :binary do |msb|
		msb.sln  = Dir.glob("#{$gb.paths[:source]}/*.sln").first

		msb.add_parameter "/flp:LogFile=#{File.join("#{$gb.paths[:log][:r]}/build",
		                                            "#{$commit_sha}.log")};Verbosity=Detailed;"
	  msb.cores = 2
	  msb.prop 'outdir', "#{$gb.paths[:internal]}/#{$commit_sha}"
  end

  build :library do

  end
end