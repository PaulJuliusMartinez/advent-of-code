#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'

strs = get_input_str_arr(__FILE__)

num = strs.count do |pw|
  counts, letter, pw = pw.split(" ")
  min, max = counts.split("-").map(&:to_i)
  letter = letter[0]

  c = Hash.new {|h, k| h[k] = 0}
  pw.chars.each do |ch|
    c[ch] ||= 0
    c[ch] += 1
  end

  min <= c[letter] && c[letter] <= max
end

puts "Part 1: #{num}"

num = 0
strs.each do |pw|
  counts, letter, pw = pw.split(" ")
  min, max = counts.split("-").map(&:to_i)
  letter = letter[0]

  a = pw[min - 1] == letter
  b = pw[max - 1] == letter

  if (a && !b) || (!a && b)
    num += 1
  end
end

puts "Part 2: #{num}"
