require 'jira'
require 'pp'

CONSUMER_KEY = 'test'
SITE         = 'https://testrest.atlassian.net/'

class JiraWorker
	attr_accessor :client

	def initialize
    # credentials = YAML.load(File.read('credentials.yaml'))
		#
    # if credentials.values.any? {|v| v.eql?''}
    #   raise "Set Login credentials in #{File.expand_path('credentials.yaml')}"
    # end
		#
    # @client = JIRA::Client.new(
    #     { :username => credentials[:username],
    #       :password => credentials[:password],
    #       :site => 'http://jira.dako.de',
    #       :context_path => '',
    #       :auth_type => :basic,
    #       :use_ssl => false
    #     })


    options = {
        :private_key_file => "rsakey.pem",
        :context_path     => '',
        :consumer_key     => CONSUMER_KEY,
        :site             => SITE
    }

    @client = JIRA::Client.new(options)
    access_token = @client.set_access_token('0U5MW7Bq4iZlZbhPRR3IE0F2D6O8VfKA', 'YBOiMI4ZHWMrlX87N1Dv3LnYQuNq1obL')

		project = @client.Project.find('TES')

		issue = @client.Issue.find('TES-1')



		pp issue
	end

  def ticket_done(commit_message)
    /jira:\s?(?<ticket>[\w]+-\d+)\/(?<operation>done|time)/
  end

  def ticket_merged(commit_message)

  end

	private
	def self.comments(msg)

		comment = @issue.comments.build
		comment.save!(msg)
	end

end