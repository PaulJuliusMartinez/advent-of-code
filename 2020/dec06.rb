#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

total_count = 0
seen = Set.new

strs.each do |str|
  if str == ''
    total_count += seen.count
    seen = Set.new
    next
  end

  str.chars.each do |ch|
    seen << ch
  end
end

total_count += seen.count

puts "Part 1: #{total_count}"

total_count = 0
seen = ZHash.new
people = 0

strs.each do |str|
  if str == ''
    total_count += seen.values.count {|v| v == people}
    seen = ZHash.new
    people = 0
    next
  end

  str.chars.each do |ch|
    seen[ch] += 1
  end
  people += 1
end

total_count += seen.values.count {|v| v == people}

puts "Part 2: #{total_count}"
