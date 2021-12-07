#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

lines = strs.map do |s|
  p1, p2 = s.split(" -> ")
  x1, y1 = p1.split(",").map(&:to_i)
  x2, y2 = p2.split(",").map(&:to_i)

  [[x1, y1], [x2, y2]]
end

hv = lines.select do |l|
  l[0][0] == l[1][0] || l[0][1] == l[1][1]
end

counts = ZHash.new

hv.each do |line|
  x1, y1 = line[0]
  x2, y2 = line[1]

  x1, x2 = [x1, x2].minmax
  y1, y2 = [y1, y2].minmax

  (x1..x2).each do |x|
    (y1..y2).each do |y|
      counts[[x, y]] += 1
    end
  end
end

puts "Part 1: #{counts.values.count {|n| n >= 2}}"

counts = ZHash.new

lines.each do |line|
  x1, y1 = line[0]
  x2, y2 = line[1]

  dx = if x1 == x2
         0
       elsif x1 < x2
         1
       else
         -1
       end
  dy = if y1 == y2
         0
       elsif y1 < y2
         1
       else
         -1
       end

  dist = [x2 - x1, y2 - y1].map(&:abs).max

  (dist + 1).times do
    counts[[x1, y1]] += 1
    x1 += dx
    y1 += dy
  end
end

puts "Part 2: #{counts.values.count {|n| n >= 2}}"
