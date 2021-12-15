#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

og_grid = strs.map do |str|
  str.chars.map(&:to_i)
end

def fastest(grid)
  fastest_path = ZHash.new

  height = grid.length
  width = grid[0].length
  puts "#{height}, #{width}"
  fastest_path[[height - 1, width - 1]] = grid[height - 1][width - 1]

  max_sum = width + height - 2
  max_sum.times do |n|
    sum = max_sum - n

    (sum + 1).times do |x|
      y = sum - x

      next if x >= width || y >= height
      next if x == width - 1 && y == height - 1

      # puts "Considering: #{x}, #{y}"

      cost = grid[y][x]
      routes = []
      if y + 1 < height
        routes << fastest_path[[y + 1, x]]
      end
      if x + 1 < width
        routes << fastest_path[[y, x + 1]]
      end

      puts "Consider: #{x}, #{y}, cost: #{cost}, opts: #{routes}"
      fastest_path[[y, x]] = cost + routes.min
    end
    puts '**'
  end

  [fastest_path[[0, 1]], fastest_path[[1, 0]]].min
end

def fastest2(grid)
  fastest_path = Hash.new {|h, k| h[k] = 9999999999}

  height = grid.length
  width = grid[0].length

  to_consider = [[0, 0]]
  fastest_path[[0, 0]] = 0

  while next_node = to_consider.shift
    x, y = next_node
    cost = fastest_path[[y, x]]

    # puts "Consider paths from #{y},#{x}"
    [[1, 0], [-1, 0], [0, 1], [0, -1]].each do |dx, dy|
      nx = x + dx
      ny = y + dy
      next if nx < 0 || ny < 0 || nx >= width || ny >= height

      neighbor_cost = grid[ny][nx]
      if cost + neighbor_cost < fastest_path[[ny, nx]]
        fastest_path[[ny, nx]] = cost + neighbor_cost
        # puts "fastest to get to #{ny}, #{nx} is #{cost + neighbor_cost}"
        to_consider << [nx, ny]
      end
    end
  end

  fastest_path[[height - 1, width - 1]]
end

# og_grid.map {|r| puts r.join}
puts "Part 1: #{fastest2(og_grid)}"

super_grid = (og_grid.length * 5).times.map { Array.new(og_grid[0].length * 5) }

og_grid.length.times do |y|
  og_grid[0].length.times do |x|
    start = og_grid[y][x]

    5.times do |dx|
      5.times do |dy|

        val = start
        sy = y + og_grid.length * dy
        sx = x + og_grid[0].length * dx
        incrs = dx + dy

        while incrs > 0
          val += 1
          val = 1 if val > 9
          incrs -= 1
        end

        super_grid[sy][sx] = val
      end
    end
  end
end

# super_grid.map {|r| puts r.join}

puts "Part 2: #{fastest2(super_grid)}"
