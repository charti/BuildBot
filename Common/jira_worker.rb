require 'jira'

class JiraWorker
  def initialize
    credentials = YAML.load(File.read('credentials.yaml'))

    if credentials.values.any? {|v| v.eql?''}
      raise "Set Login credentials in #{File.expand_path('credentials.yaml')}"
    end

    @client = JIRA::Client.new(
        { :username => credentials[:username],
          :password => credentials[:password],
          :site => 'http://jira.dako.de',
          :context_path => '',
          :auth_type => :basic,
          :use_ssl => false
        })
  end

  def ticket_done(commit_message)
    /jira:\s?(?<ticket>[\w]+-\d+)\/(?<operation>done|time)/
  end

end