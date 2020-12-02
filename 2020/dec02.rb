#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

num = strs.count do |s|
  min, max, letter, pw = s.scanf("%d-%d %c: %s")

  c = Hash.new {|h, k| h[k] = 0}
  pw.chars.each do |ch|
    c[ch] ||= 0
    c[ch] += 1
  end

  min <= c[letter] && c[letter] <= max
end

puts "Part 1: #{num}"

num = 0
strs.each do |s|
  i1, i2, letter, pw = s.scanf("%d-%d %c: %s")

  a = pw[i1 - 1] == letter
  b = pw[i2 - 1] == letter

  if (a && !b) || (!a && b)
    num += 1
  end
end

puts "Part 2: #{num}"
