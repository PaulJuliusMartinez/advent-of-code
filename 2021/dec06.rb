#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_single_line_input_int_arr(__FILE__, separator: ',')

at_stage = ZHash.new

ints.each do |n|
  at_stage[n] += 1
end

256.times do |n|
  puts "Part 1: #{at_stage.values.sum}" if n == 80
  new_at_stage = ZHash.new

  new_at_stage[8] = at_stage[0]
  new_at_stage[6] = at_stage[0]

  (1..8).each do |s|
    new_at_stage[s - 1] += at_stage[s]
  end

  at_stage = new_at_stage
end

puts "Part 2: #{at_stage.values.sum}"
