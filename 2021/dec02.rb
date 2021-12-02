#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

x = 0
d = 0

strs.each do |str|
  cmd, n = str.split(" ")
  n = n.to_i

  x += n if cmd == "forward"
  d += n if cmd == "down"
  d -= n if cmd == "up"
end

puts "Part 1: #{x * d}"

x = 0
d = 0
aim = 0

strs.each do |str|
  cmd, n = str.split(" ")
  n = n.to_i

  if cmd == "forward"
    x += n
    d += aim * n
  end
  aim += n if cmd == "down"
  aim -= n if cmd == "up"
end

puts "Part 2: #{x * d}"
