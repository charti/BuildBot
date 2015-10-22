#require_relative 'pipe'
puts 'run'
#require_relative 'pipe'
require_relative '../configs/' + ARGV[0]

Tools::edit_file('test.txt', 'testmod.txt') do |lines|
  lines
end

instance = Pipe.new
puts instance.pretty_inspect
#
#CIPipe::execute_pipe

#puts ARGV