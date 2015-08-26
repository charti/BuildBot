require 'rake'
require 'albacore'
require_relative '../Common/git_builder'

gb = nil

task :default, [:gb] => [:init, :do_work]

task :init, [:gb] do |t, args|
  gb = args[:gb]
end

task :do_work do
  puts gb
end

namespace :build do
  build :library do

  end
end