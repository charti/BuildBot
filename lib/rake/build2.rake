require 'rake'
require 'albacore'

require '../configs/' + ARGV[0]

pipe = nil

task :execute, :pipe, :csproj, :build_type, :current_branch, :current_commit,
     :do_versioning do |t, args|
  args.each {|name, value| instance_variable_set("@#{name}", value)}
  begin
    @pipe.tasks[:start].invoke

    br = @current_branch.gsub('/','_')
    mkdir_p %W(#{@pipe.git.paths[:log][:r]}/build/#{br} #{@pipe.git.paths[:internal]}/#{br}) #{@pipe.git.paths[:external]}/#{br}

  ensure
    @pipe.tasks[:start].all_prerequisite_tasks.each { |prereq| prereq.reenable }
    @pipe.tasks[:start].reenable
    t.reenable
  end
  puts t
end

#TODO restliche abhängigkeiten
task :start => [:build] do |t|
  puts t
end

task :build => [:versioning, :copy_configs] do|t|
  puts t
  raise 'something'
end

#TODO versioning
task :versioning do
  puts :versioning
end

#TODO copy_configs
task :copy_configs do
  puts :copy_configs
end