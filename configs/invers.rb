require_relative '../lib/pipe'

class Pipe < BasePipe
  def setup
    @repo = 'invers'
    @uri = 'https://charti:+Ch5377422@github.com/charti/InVers.git'
    @target_branch = 'master'
    @base_branch = 'master'
    @branches_to_build = %w<cc/merge1 cc/merge2> #cc/pu cc/test cc/broken
  end

  # +version+ contains the old version
  # version[0] == 1.0.0.0
  # version[1||:major] == 1
  # version[2||:minor] == 0
  # version[3||:build] == 0
  # version[4||:revision] == 0
  # optional - default will increase :revision by 1
  def increase_version version
    puts 'increased'
    new_version = "#{version[1]}.#{version[2]}.#{version[3]}." +
        "#{version[4].to_i + 1}"
  end

  def build_commit
    build_binary('InVers.csproj', 'invers-test.csproj')
    #build_web_application('InVers.csproj', '')
  end

end