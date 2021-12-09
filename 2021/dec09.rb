#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

heights = Hash.new {|h, k| h[k] = 10}

strs.each.with_index do |str, y|
  str.chars.each.with_index do |h, x|
    heights[[x, y]] = h.to_i
  end
end

low = 0

low_points = []

# Easier to do: points = heights.keys
strs.length.times do |y|
  strs[0].length.times do |x|
    deltas = [[0, 1], [0, -1], [1, 0], [-1, 0]]
    h = heights[[x, y]]
    if deltas.all? {|(dx, dy)| heights[[x + dx, y + dy]] > h}
      low_points << [x, y]
      low += h + 1
    end
  end
end

puts "Part 1: #{low}"

basin_sizes = low_points.map do |lp|
  edges = [lp]
  seen = Set.new

  while (p = edges.pop)
    seen << p
    ph = heights[p]
    x, y = p
    deltas = [[0, 1], [0, -1], [1, 0], [-1, 0]]

    deltas.each do |(dx, dy)|
      neighbor = [x + dx, y + dy]
      nh = heights[neighbor]
      if nh < 9 && nh > ph && !seen.include?(neighbor)
        edges << neighbor
      end
    end
  end

  seen.count
end

sizes = basin_sizes.sort.reverse

puts "Part 2: #{sizes[0] * sizes[1] * sizes[2]}"

