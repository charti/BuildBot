require 'rubygems'
require 'bundler/setup'
require 'jira'
require_relative 'Rake/build'

#Jira testticket: TEST-51

options = { :username => 'Christian.Chartron',
            :password => '#Ch5377422',
            :site => 'http://jira.dako.de',
            :context_path => '',
            :auth_type => :basic,
            :use_ssl => false
}

client = JIRA::Client.new(options)

issue = client.Issue.find('TEST-51')
issue.save({"fields"=>{"summary"=> ''}})

threads = []

threads << Thread.new { Kernel.system *%w<rake -f Rake/initial.rb default[bootcamp.yaml]> }
#threads << Thread.new { Kernel.system *%w<rake -f Rake/initial.rb default['bootcamp.yaml']> }


threads.each {|t| t.join }