require_relative 'Common/git_builder'
require_relative 'Rake/build'
require_relative 'Rake/playground'
require 'git'
require 'rake'


Rake::Task[:bla].invoke
$project_root = File.dirname(__FILE__)

Kernel.system *%w<rake -f Rake/initial.rb>

gb = GitBuilder.new('bootcamp.yaml')

# puts gb.to_yaml