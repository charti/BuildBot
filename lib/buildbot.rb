require 'rubygems'
require 'bundler/setup'

config = '../configs/' + ARGV[0] + '.rb'

if File.exist?(config)
	require_relative config

	begin
		instance = Pipe.new
	rescue => e
		puts e.pretty_inspect
		puts instance.pretty_inspect
	end
else
	puts %(
Please specify a valid Configuration
These are the available Configurations, located in #{File.expand_path('../configs')}:

)
	Dir.glob('../configs/*.rb').each do |config|
		puts File.basename(config)
	end
end