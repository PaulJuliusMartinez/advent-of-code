#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

$map = {}

strs.each.with_index do |str, y|
  str.chars.each.with_index do |ch, x|
    $map[[x, y]] = ch
  end
end

WIDTH = strs[0].length
HEIGHT = strs.length

def count_for_slope(dx, dy)
  x, y = [dx, dy]

  width = WIDTH

  num_trees = 0

  while y < HEIGHT do
    if $map[[x, y]] == '#'
      num_trees += 1
    end

    x += dx
    x = x % width
    y += dy
  end

  num_trees
end

counts = [
  [1, 1],
  [3, 1],
  [5, 1],
  [7, 1],
  [1, 2],
].map do |x, y|
  count_for_slope(x, y)
end

puts "Part 1: #{count_for_slope(3, 1)}"

n = 1
counts.each {|x| n = n * x}

puts "Part 2: #{n}"
