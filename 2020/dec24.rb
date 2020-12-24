#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)


#     A     B     C
#           |  /
#     D  -  E  -  F
#        /  |
#     G     H     I
#
# East: 1, 0
# West: -1, 0
# SouthEast: 0, -1
# SouthWest: -1, -1
# NorthEast: 1, 1
# NorthWest: 0, 1

flipped_coords = ZHash.new

strs.each do |steps|
  i = 0

  x = 0
  y = 0
  while i < steps.length
    if steps[i] == 'e'
      x += 1
      i += 1
    elsif steps[i] == 'w'
      x -= 1
      i += 1
    elsif steps[i] == 's'
      if steps[i + 1] == 'e'
        # se
        y -= 1
      elsif steps[i + 1] == 'w'
        # sw
        x -= 1
        y -= 1
      end
      i += 2
    elsif steps[i] == 'n'
      if steps[i + 1] == 'e'
        # ne
        x += 1
        y += 1
      elsif steps[i + 1] == 'w'
        # nw
        y += 1
      end
      i += 2
    end
  end

  # puts "steps: #{steps} leads to #{x}, #{y}"
  flipped_coords[[x, y]] += 1
end

puts "Part 1: #{flipped_coords.count {|_, v| v % 2 == 1}}"


black = flipped_coords.select {|k, v| v % 2 == 1}

black_tiles = Set.new(black.keys)

100.times do |n|
  num_black_neighbors = ZHash.new

  black_tiles.to_a.each do |x, y|
    num_black_neighbors[[x + 1, y]] += 1
    num_black_neighbors[[x - 1, y]] += 1

    # north
    num_black_neighbors[[x + 1, y + 1]] += 1
    num_black_neighbors[[x, y + 1]] += 1

    # south
    num_black_neighbors[[x - 1, y - 1]] += 1
    num_black_neighbors[[x, y - 1]] += 1
  end

  new_black_tiles = Set.new

  num_black_neighbors.each do |(x, y), num_neighbors|
    if black_tiles.include?([x, y])
      if num_neighbors == 0 || num_neighbors > 2
        # white
      else
        new_black_tiles << [x, y]
      end
    else
      if num_neighbors == 2
        new_black_tiles << [x, y]
      end
    end
  end

  black_tiles = new_black_tiles
end

puts "Part 2: #{black_tiles.count}"
