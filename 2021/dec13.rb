#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)
dots = grouped_strs[0]
insts = grouped_strs[1]

pts = Set.new

dots.each do |dot|
  x, y = dot.split(",").map(&:to_i)
  pts << [x, y]
end

first = true
insts.map do |inst|
  _, _, inst = inst.split(" ")
  axis, val = inst.split("=")
  val = val.to_i

  new_pts = Set.new

  pts.each do |pt|
    if axis == 'x'
      x, y = pt
      if x > val
        x = val - (x - val)
      end
      new_pts << [x, y]
    else
      x, y = pt
      if y > val
        y = val - (y - val)
      end
      new_pts << [x, y]
    end
  end

  puts "Part 1: #{new_pts.size}" if first
  first = false

  pts = new_pts
end

x_max = pts.to_a.map(&:first).max
y_max = pts.to_a.map(&:last).max

puts "Part 2:"
(0..y_max).each do |y|
  (0..x_max).each do |x|
    if pts.include?([x, y])
      print '#'
    else
      print ' '
    end
  end
  puts
end
