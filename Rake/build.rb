require 'rake'
require 'albacore'

task :default, [:gb] => [:init, :do_work]

task :init, [:gb] do |t, args|
  gb = args[:gb]
end

task :do_work do

end

namespace :build do
  build :binary do

  end

  build :library do

  end
end