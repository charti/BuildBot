require_relative 'Common/git_builder'

$project_root = File.dirname(__FILE__)

Kernel.system *%w<rake -f Rake/initial.rb>

gb = GitBuilder.new('invers.yaml')



