require 'jira'
require 'pp'
require 'yaml'

CONSUMER_KEY = 'test'
SITE         = 'https://testrest.atlassian.net/'

class JiraWorker
	attr_accessor :client

	def initialize
		config = YAML.load_file(File.expand_path('../jira.yaml'))

		if config.values.any? {|v| v.eql?''}
		  raise "Set Login credentials in #{}"
		end

		@client = JIRA::Client.new(
		    { :username => config[:user],
		      :password => config[:password],
		      :site => config[:url],
		      :context_path => '',
		      :auth_type => :basic,
		      :use_ssl => false
		    })


		# options = {
		# 		:private_key_file => "rsakey.pem",
		# 		:context_path     => '',
		# 		:consumer_key     => CONSUMER_KEY,
		# 		:site             => SITE
		# }
    #
		# @client = JIRA::Client.new(options)
		# access_token = @client.set_access_token('0U5MW7Bq4iZlZbhPRR3IE0F2D6O8VfKA', 'YBOiMI4ZHWMrlX87N1Dv3LnYQuNq1obL')


		#http://buildbot-1.dev.tachoweb.eu/logs/tachoweb-2015-03-02-15-25/top-build.log
		project = @client.Project.find('TEST')


		testcommitmsg = "Blie bla bulbsadas dadsad asd asd\n jira:TEST-55/done"

		issue = @client.Issue.find('TEST-55')

		issue.transitions.build.save("transition" => {"id" => '5'})

		comment.save!(:body => "new comment")



		pp issue
	end

	def add_merged_commit commit

	end

	def add_failed_commit commit
	end

	private

	def ticket_done(commit_message)
		ticket = /jira:\s?(?<ticket>[\w]+-\d+)\/(?<operation>done|)/
				.match(commit_message)
		unless ticket[:ticket].empty?
			msg = %(

			)
			issue = @client.Issue.find(ticket[:ticket])
			issue.comment.save(:body => msg)
		end
	end

	def ticket_merged(commit_message)

	end

	private
	def self.comments(msg)

		comment = @issue.comments.build
		comment.save!(msg)
	end

end