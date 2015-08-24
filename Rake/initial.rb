require 'rake'

task :default => [:init]

task :init => [:init_dirs]
task :clean do |t, args|

end

file :init_dirs do
  mkdir_p 'WorkingDir/repos'
  mkdir_p 'WorkingDir/internal'
  mkdir_p 'WorkingDir/external'
  mkdir_p 'WorkingDir/log/'
end