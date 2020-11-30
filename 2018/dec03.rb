#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'

# Part 1: 5:05 (~47)
# Part 2: 6:20 (~25)

strs = get_input_str_arr(__FILE__)

claims = strs.map do |str|
  num, at, offset, size = str.split(" ")
  x, y = offset.split(",").map(&:to_i)
  w, h = size.split("x").map(&:to_i)

  [x, y, w, h, num]
end

counts = {}

claims.each do |claim|
  x, y, w, h, num = claim

  (0..(w - 1)).each do |dx|
    (0..(h - 1)).each do |dy|
      counts[[x + dx, y + dy]] ||= 0
      counts[[x + dx, y + dy]] += 1
    end
  end
end

print "Part 1: "
puts counts.values.count {|n| n > 1}

claims.each do |claim|
  x, y, w, h, num = claim
  overlaps = false

  (0..(w - 1)).each do |dx|
    (0..(h - 1)).each do |dy|
      if counts[[x + dx, y + dy]] > 1
        overlaps = true
      end
    end
  end

  if !overlaps
    print "Part 2: "
    puts num
    break
  end
end
