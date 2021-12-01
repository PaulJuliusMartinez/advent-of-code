#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_multi_line_input_int_arr(__FILE__)

prev = ints[0]

i = 0
ints.each do |int|
  if int > prev
    i += 1
  end

  prev = int
end

puts "Part 1: #{i}"

i = 0
(ints.length - 3).times do |index|
  if ints[index + 3] > ints[index]
    i += 1
  end
end

puts "Part 2: #{i}"
