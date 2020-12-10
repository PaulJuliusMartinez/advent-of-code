#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_multi_line_input_int_arr(__FILE__)

built_in = ints.max + 3

ints.sort!

DIFFS = [0, 0, 0, 0]
DIFFS[ints[0]] += 1

ints.count.times do |i|
  curr = ints[i]
  n = ints[i + 1] || built_in
  DIFFS[n - curr] += 1
end

puts DIFFS[1] * DIFFS[3]

INTS = ints

def ways_to_add_adapters(arr, curr, idx, max)
  if idx == arr.count
    return 1 if max - curr <= 3
    return 0
  end

  return 0 if arr[idx] - curr > 3

  c = 0
  c += ways_to_add_adapters(arr, arr[idx], idx + 1, max)
  c += ways_to_add_adapters(arr, curr, idx + 1, max)

  c
end

chunks = []
ints << built_in

curr_chunk = [0]
prev = 0
ints.each do |i|
  if i == prev + 3
    chunks << curr_chunk
    curr_chunk = []
  end
  curr_chunk << i
  prev = i
end

ways_for_chunks = chunks.map do |chunk|
  ways_to_add_adapters(chunk, chunk[0], 1, chunk.last + 3)
end

p = 1
ways_for_chunks.each {|n| p *= n}
puts p


# Dynamic Programming Solution
num_ways = [0] * (ints.count + 1)
num_ways[0] = 1

(1..ints.count).each do |i|
  n = 0
  val = ints[i] || built_in
  n += num_ways[i - 3] if i - 3 >= 0 && val - ints[i - 3] <= 3
  n += num_ways[i - 2] if i - 2 >= 0 && val - ints[i - 2] <= 3
  n += num_ways[i - 1] if i - 1 >= 0 && val - ints[i - 1] <= 3
  num_ways[i] = n
end

puts num_ways.last
