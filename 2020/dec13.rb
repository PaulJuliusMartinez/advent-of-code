#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

id = strs[0].to_i

in_service = strs[1].split(",").map(&:to_i).select {|x| x > 0}


delays = in_service.map do |bus_id|
  # id % bus_id = how many minutes since last departure of bus_id
  bus_id - (id % bus_id)
end

delay = delays.min
taken_bus_id = in_service[delays.index(delay)]

puts "Part 1: #{taken_bus_id * delay}"



# [[17, 0], [41, 7], ...
# Array of bus_id and delay (mod)
in_service = strs[1].split(",").map(&:to_i)
  .map.with_index {|n, x| [n, x]}
  .select {|n, _| n > 0}

t = 0
prod = 1

in_service.each do |n, mod|
  while (t + mod) % n != 0
    t += prod
  end

  prod *= n
end

puts "Part 2: #{t}"

in_service.each do |n, mod|
  # puts "Want (t + #{mod}) % #{n} = 0, got #{t % n}"
end

# 7, 1
# 5, 2
#
# -> 22
#
# 1 8 15 22 29
# 2 7 12 17 22
