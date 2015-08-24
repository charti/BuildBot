require_relative 'Common/git_builder'
require_relative 'Rake/work'
require 'git'
require 'rake'

$project_root = File.dirname(__FILE__)

Kernel.system *%w<rake -f Rake/initial.rb>

gb = GitBuilder.new('invers.yaml')

Rake::Task["work:do"].invoke(gb)

# puts gb.to_yaml



