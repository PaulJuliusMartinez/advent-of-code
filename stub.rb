#! /usr/bin/env ruby

require './intcode.rb'
require './input.rb'

strs = get_input_str_arr(__FILE__)
str = get_input_str(__FILE__)
ints1 = get_single_line_input_int_arr(__FILE__, separator: ',')
ints2 = get_multi_line_input_int_arr(__FILE__)

puts strs.inspect
puts str.inspect
puts ints1.inspect
puts ints2.inspect

__END__
hello,2,3
1234
