#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

dests = Hash.new {|h, k| h[k] = Set.new}
big_caves = Set.new
small_caves = Set.new

strs.each do |str|
  s, e = str.split('-')

  dests[s] << e
  dests[e] << s

  if s == s.downcase
    small_caves << s
  else
    big_caves << s
  end

  if e == e.downcase
    small_caves << e
  else
    big_caves << e
  end
end

paths = Set.new

partial_paths = [[['start'], Set.new]]

while partial_paths.any?
  path, visited = partial_paths.pop

  current = path.last
  visited << current if small_caves.include?(current)

  dests[current].each do |dest|
    if dest == 'end'
      full_path = path + ['end']
      paths << full_path
      # puts "found path: #{full_path.join(',')}"
    else
      if !small_caves.include?(dest) || !visited.include?(dest)
        partial_paths << [
          path + [dest],
          visited.dup,
        ]
      end
    end
  end
end


puts "Part 1: #{paths.count}"




paths = Set.new

counts = ZHash.new
counts['start'] = 2
partial_paths = [[['start'], counts, false]]

while partial_paths.any?
  path, visited_counts, visited_twice = partial_paths.pop

  current = path.last
  if current != 'start' && small_caves.include?(current)
    visited_counts[current] += 1
    if visited_counts[current] == 2
      next if visited_twice
      visited_twice = true
    end
  end

  dests[current].each do |dest|
    if dest == 'end'
      full_path = path + ['end']
      paths << full_path
    else
      if !small_caves.include?(dest) || visited_counts[dest] < 2
        partial_paths << [
          path + [dest],
          visited_counts.dup,
          visited_twice,
        ]
      end
    end
  end
end


puts "Part 2: #{paths.count}"
