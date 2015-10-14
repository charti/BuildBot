require 'rubygems'
require 'bundler/setup'
require 'jira'
require_relative 'Rake/build'
require_relative 'Common/jira_worker'

jw = JiraWorker.new

jw.client.Project.all.each do |proj|
	puts proj
end

begin

  transition_review = issue.transitions.build
  transition_review.save!("transition" => {"id" => '5'})

  #comment = issue.comments.build
  #comment.save!(:body => "Das ist ein ruby generierter Kommentar.")

rescue => e
  puts e
end

threads = []

threads << Thread.new { Kernel.system *%w<rake -f Rake/initial.rb default[bootcamp.yaml]> }
#threads << Thread.new { Kernel.system *%w<rake -f Rake/initial.rb default['bootcamp.yaml']> }


threads.each {|t| t.join }