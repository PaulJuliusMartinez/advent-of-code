#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'

strs = get_input_str_arr(__FILE__)
puts strs.inspect

str = get_input_str(__FILE__)
puts str.inspect

ints2 = get_multi_line_input_int_arr(__FILE__)
puts ints2.inspect

ints = get_single_line_input_int_arr(__FILE__, separator: ',')
