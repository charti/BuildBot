require 'jira'
require 'git'
require 'pp'

class JiraWorker
	attr_accessor :client

	def initialize
		credentials = YAML.load(File.read('../configs/jira.yaml'))

		if credentials.values.any? {|v| v.eql?''}
		  raise "Set Login credentials in #{File.expand_path('../configs/jira.yaml')}"
		end

		@client = JIRA::Client.new(
		    { :username => credentials[:user],
		      :password => credentials[:password],
		      :site => credentials[:url],
		      :context_path => '',
		      :auth_type => :basic,
		      :use_ssl => false
		    })

		LOGGER.info(:Jira) {"Successfully initilized."}
	end

	def ticket_failed commit
		match = /jira:\s?(?<ticket>[\w]+-\d+)\/(?<operation>done)/.match(commit_message)

		return if match[0].nil? ||match[1].nil?

		issue = @client.Issue.find(match[0])
		comment = issue.comments.build
		comment.save!("Der Arbeitsstand #{commit.sha} wurde nicht in die Mainline integriert.")
		transition_review = issue.transitions.build
		transition_review.save!("transition" => {"id" => '3'})
	end

	def ticket_done(commit, publish)
		match = /jira:\s?(?<ticket>[\w]+-\d+)\/(?<operation>done)/.match(commit_message)

		return if match[0].nil? ||match[1].nil?

		issue = @client.Issue.find(match[0])
		comment = issue.comments.build
		comment.save!("Der Arbeitsstand #{commit.sha} wurde erfolgreich geprüft und kann nun"+
											"getestet werden.")
		transition_review = issue.transitions.build
		transition_review.save!("transition" => {"id" => '5'})
	end
end