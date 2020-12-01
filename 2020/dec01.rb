#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'

ints = get_multi_line_input_int_arr(__FILE__)

seen = {}

ints.each do |i|
  if seen.key?(2020 - i)
    puts i
    puts 2020 - i
    puts "Part 1: #{i * (2020 - i)}"
    break
  end
  seen[i] = true
end

# Part 2 is buggy! Everything needs to be added to seen.
# It will fail to find a solution if all three values
# come after the two values in Part 1.
#
# (I didn't have this line originally)
# ints.each {|i| seen[i] = true}

ints.each.with_index do |i, a|
  ints.each.with_index do |j, b|
    if a != b && seen.key?(2020 - i - j)
      puts i
      puts j
      puts 2020 - i - j
      puts "Part 2: #{i * j * (2020 - i - j)}"
      exit
    end
  end
end
