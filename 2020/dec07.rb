#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

contains = {}
contained_by = {}

def bag_color(bag_str)
  a, b, _ = bag_str.split(" ")
  "#{a} #{b}"
end

strs.each do |str|
  out, inners = str.split(" contain ")
  out = bag_color(out)
  contains[out] = []

  next if str.include?('no other bags')

  inners = inners.split(",").map(&:strip)
  inners.each do |inner|
    first_space = inner.index(' ')
    count = inner.to_i
    bag_type = inner[(first_space + 1)..10000]
    bag_type = bag_color(bag_type)

    contains[out] << [bag_type, count]

    contained_by[bag_type] ||= []
    contained_by[bag_type] << out
  end
end

gcb = Set.new
to_process = ['shiny gold']

while !to_process.empty?
  bag = to_process.pop
  gcb << bag

  (contained_by[bag] || []).each do |b|
    to_process << b if !gcb.include?(b)
  end
end

puts "Part 1: #{gcb.count - 1}"

total_bags = 0
inside = [['shiny gold', 1]]
while !inside.empty?
  bag_type, count = inside.pop

  total_bags += count
  contains[bag_type].each do |contained|
    inside << [contained[0], contained[1] * count]
  end
end

puts "Part 2: #{total_bags - 1}"

