require_relative '../lib/pipe'

class Pipe < BasePipe
  def setup
    @repo = 'invers'
    @uri = 'https://github.com/charti/InVers.git'
    @target_branch = 'master'
    @base_branch = 'master'
    @branches_to_build = %w<cc/pu cc/test cc/broken>
  end
end