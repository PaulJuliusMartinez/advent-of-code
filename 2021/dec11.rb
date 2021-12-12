#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

p1 = 0
p2 = 0

grid = strs.map do |str|
  str.chars.map(&:to_i)
end

iter = 0
loop do
  iter += 1
  flashed = Set.new

  will_flash = []
  10.times do |x|
    10.times do |y|
      # print grid[x][y]
      grid[x][y] += 1
      if grid[x][y] > 9
        will_flash << [x, y]
      end
    end
    # puts
  end
  # puts '***'

  while will_flash.any?
    x, y = will_flash.pop
    next if flashed.include?([x, y])
    flashed << [x, y]

    p1 += 1 if iter <= 100

    [-1, 0, 1].each do |dx|
      [-1, 0, 1].each do |dy|
        next if dx == 0 && dy == 0

        if 0 <= x + dx && x + dx < 10 && 0 <= y + dy && y + dy < 10
          grid[x + dx][y + dy] += 1
          if grid[x + dx][y + dy] > 9
            will_flash << [x + dx, y + dy]
          end
        end
      end
    end
  end

  flashed.to_a.each do |(x, y)|
    grid[x][y] = 0
  end

  break if flashed.size == 100
end

puts "Part 1: #{p1}"
puts "Part 2: #{iter}"
