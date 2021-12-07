#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_single_line_input_int_arr(__FILE__, separator: ',')

best = (ints.min..ints.max).min_by do |dest|
  ints.map {|n| (n - dest).abs}.sum
end

fuel = ints.map {|n| (n - best).abs}.sum
puts "Part 1: #{fuel}"

best = (ints.min..ints.max).min_by do |avg|
  ints.map do |n|
    t = (n - avg).abs
    t * (t + 1) / 2
  end.sum
end

fuel = ints.map do |n|
  t = (n - best).abs
  t * (t + 1) / 2
end.sum

puts "Part 2: #{fuel}"
