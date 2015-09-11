require 'rake'
require_relative '../Common/git_builder'

namespace :work do

	gb = nil

	task :do, [:work_path] => [:init, :prepare_commit_dir] do |t, args|
		puts t.to_s
	end

	task :init, :gb do |t, args|
		$gb = args[:gb]
		$gb.logger.debug('Starte Initialisierung in Task :work')
	end

	task :prepare_commit_dir do |t|
		$path_internal = "WorkingDir/internal/#{$gb.config['Name']}"
		rm_rf $path_internal

		$gb.commits.each_key do |branch|
			next if branch == 'master'
			mkdir_p File.expand_path("#{$path_internal}/#{branch.gsub('/', '-')}")
		end
	end

end