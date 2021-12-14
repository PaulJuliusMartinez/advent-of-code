#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)
str = grouped_strs[0][0]
rules = grouped_strs[1]

pairs = {}
rules.each do |rule|
  a, b = rule.split(" -> ")
  pairs[a.chars] = b
end

ITER1 = 10
ITER2 = 40

original_str = str

ITER1.times do
  s = ""
  (str.length - 1).times do |n|
    c1 = str[n]
    c2 = str[n + 1]

    s << c1
    if pairs[[c1, c2]]
      s << pairs[[c1, c2]]
    end
  end

  s << str[-1]

  str = s
end

counts = ZHash.new
str.chars.each {|ch| counts[ch] += 1}
min = counts.values.min
max = counts.values.max

puts "Part 1: #{max - min}"

rule_set = pairs

pairs = original_str.chars.each_cons(2).map {|c1, c2| "#{c1}#{c2}"}

pair_counts = ZHash.new
pairs.each {|p| pair_counts[p] += 1}
pair_counts[" #{original_str[0]}"] = 1
pair_counts["#{original_str[-1]} "] = 1


# puts rule_set.inspect
ITER2.times do
  new_counts = ZHash.new

  pair_counts.each do |pair, count|
    a, b = pair.chars

    # puts [a, b]
    if (insert = rule_set[[a, b]])
      # puts 'inserting'
      new_counts["#{a}#{insert}"] += count
      new_counts["#{insert}#{b}"] += count
    else
      new_counts[pair] += count
    end
  end

  # puts new_counts.inspect
  pair_counts = new_counts
end

ch_counts = ZHash.new

pair_counts.each do |pc, count|
  ch_counts[pc[0]] += count
  ch_counts[pc[1]] += count
end

ch_counts.delete(" ")
min = ch_counts.values.min
max = ch_counts.values.max

puts "Part 2: #{((max - min) / 2)}"
