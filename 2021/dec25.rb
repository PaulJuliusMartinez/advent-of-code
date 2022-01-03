#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)


map = {}
strs.each.with_index do |str, y|
  str.chars.each.with_index do |ch, x|
    map[[x, y]] = ch if ch != '.'
  end
end

WIDTH = strs[0].length
HEIGHT = strs.length

steps = 0
loop do
  steps += 1

  empty_easts = []
  map.each do |coord, sc|
    next if sc == 'v'

    x, y = coord
    x = (x + 1) % WIDTH

    empty_easts << [coord, [x, y]] if !map.key?([x, y])
  end

  # move easts
  empty_easts.each do |(before, after)|
    map.delete(before)
    map[after] = '>'
  end

  empty_souths = []
  map.each do |coord, sc|
    next if sc == '>'

    x, y = coord
    y = (y + 1) % HEIGHT

    empty_souths << [coord, [x, y]] if !map.key?([x, y])
  end

  # move souths
  empty_souths.each do |(before, after)|
    map.delete(before)
    map[after] = 'v'
  end

  break if empty_easts.empty? && empty_souths.empty?
end

puts "Part 1: #{steps}"
