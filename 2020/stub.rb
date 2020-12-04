#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)
str = get_input_str(__FILE__)
ints = get_multi_line_input_int_arr(__FILE__)
ints = get_single_line_input_int_arr(__FILE__, separator: ',')
grid, HEIGHT, WIDTH = get_grid_input(__FILE__)
