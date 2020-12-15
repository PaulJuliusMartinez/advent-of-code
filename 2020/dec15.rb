#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_single_line_input_int_arr(__FILE__, separator: ',')

last_spoken = {}

ints.each_with_index do |n, i|
  last_spoken[n] = [1, i]
end

turn = ints.length
last_num = ints.last

(turn..29999999).each do |t|
  last = last_spoken[last_num]
  # puts "last_spoken[#{last_num}]: #{last.inspect}"

  if last[0] == 1
    next_num = 0
  else
    next_num = t - last[1] - 1
  end
  last[1] = t - 1

  last_spoken[next_num] ||= [0, t]
  last_spoken[next_num][0] += 1

  last_num = next_num
  puts "Part 1: #{last_num}" if t == 2019
end

puts "Part 2: #{last_num}"



### CLEANER (???) SOLUTION

spoken_at = {}
last_spoken = nil

COUNT = 30000000

(0..COUNT - 1).each do |i|
  if i < ints.count
    next_num = ints[i]
  else
    if !spoken_at[last_spoken]
      next_num = 0
    else
      next_num = (i - 1) - spoken_at[last_spoken]
    end
  end
  spoken_at[last_spoken] = i - 1

  last_spoken = next_num

  puts "Part 1: #{last_spoken}" if i == 2019
end

puts "Part 2: #{last_spoken}"
