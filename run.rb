require 'rubygems'
require 'bundler/setup'

require_relative 'Rake/build'

threads = []

threads << Thread.new { Kernel.system *%w<rake -f Rake/initial.rb default[bootcamp.yaml]> }
#threads << Thread.new { Kernel.system *%w<rake -f Rake/initial.rb default['bootcamp.yaml']> }


threads.each {|t| t.join }