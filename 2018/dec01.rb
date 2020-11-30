#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'

# Part 1: 1:28 (~94)
# Part 2: 5:21 (~95)

deltas = get_multi_line_input_int_arr(__FILE__)

frequencies = Set.new
frequencies << 0

sum = 0
loop do
  deltas.each do |delta|
    sum += delta
    if frequencies.include?(sum)
      puts sum
      exit(0)
    end
    frequencies << sum
  end
end
