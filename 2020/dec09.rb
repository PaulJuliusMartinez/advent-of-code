#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_multi_line_input_int_arr(__FILE__)

prev_25 = ints[0..24]

part1 = nil

ints[25..10000].each do |next_i|
  found_sum = false
  (0..24).each do |i|
    (i..24).each do |j|
      next if i == j
      a = prev_25[i]
      b = prev_25[j]

      if a + b == next_i
        found_sum = true
        break
      end
    end

    break if found_sum
  end

  if !found_sum
    puts "Part 1: #{next_i}"
    part1 = next_i
    break
  end

  prev_25.shift
  prev_25 << next_i
end


start = 0

loop do
  sum = ints[start] + ints[start + 1]
  stop = start + 1

  while sum < part1
    stop += 1
    sum += ints[stop]
  end

  if sum == part1
    range = ints[start..stop]
    puts "Part 2: #{range.min + range.max}"
    break
  end

  start += 1
end

### Alternate linear-time solution for part 2

start = 0
stop = 0
sum = ints[0]

loop do
  if sum < part1
    stop += 1
    sum += ints[stop]
  elsif sum > part1
    sum -= ints[start]
    start += 1
  else
    range = ints[start..stop]
    puts "Part 2 (alternate approach): #{range.min + range.max}"
    break
  end
end
