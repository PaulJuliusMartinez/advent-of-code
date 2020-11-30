#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'

strs = get_input_str_arr(__FILE__)

def exactly_n(str, n)
  h = {}
  str.split("").each do |ch|
    h[ch] ||= 0
    h[ch] += 1
  end

  h.values.any? {|v| v == n}
end

num2 = strs.count {|s| exactly_n(s, 2)}
num3 = strs.count {|s| exactly_n(s, 3)}

puts num2 * num3

def num_different(s1, s2)
  s1.chars.zip(s2.chars).count {|x, y| x != y}
end

strs.each do |s1|
  strs.each do |s2|
    if num_different(s1, s2) == 1
      s1.chars.zip(s2.chars).each do |x, y|
        print x if x == y
      end
      puts
      exit
    end
  end
end
