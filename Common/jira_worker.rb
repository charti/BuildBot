require 'jira'

class JiraWorker
  def initialize

    @client = JIRA::Client.new(options)
  end
end