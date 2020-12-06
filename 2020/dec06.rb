#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

total_count = 0

grouped_strs.each do |group|
  seen = Set.new
  group.each do |str|
    str.chars.each do |ch|
      seen << ch
    end
  end
  total_count += seen.count
end

puts "Part 1: #{total_count}"

total_count = 0

grouped_strs.each do |group|
  seen = ZHash.new
  group.each do |str|
    str.chars.each do |ch|
      seen[ch] += 1
    end
  end
  total_count += seen.values.count {|v| v == group.count}
end

puts "Part 2: #{total_count}"
