#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

grid, $HEIGHT, $WIDTH = G.get_grid_input(__FILE__)

def iterate_seating(grid, immediate_only:, too_many_neighbors:)
  loop do
    next_grid = G.empty

    any_changes = false

    $WIDTH.times do |x|
      $HEIGHT.times do |y|
        if grid[x][y] == '.'
          next_grid[x][y] = '.'
          next
        end

        num_occupied = 0
        G.directions.each do |dx, dy|
          next if !G.in_bounds?(x + dx, y + dy)

          if immediate_only
            num_occupied += 1 if grid[x + dx][y + dy] == '#'
          else
            cx = x
            cy = y

            seen = false
            while G.in_bounds?(cx + dx, cy + dy)
              seat = grid[cx + dx][cy + dy]
              break if seat == 'L'

              if seat == '#'
                seen = true
                break
              end

              cx += dx
              cy += dy
            end

            num_occupied += 1 if seen
          end
        end

        occupied = grid[x][y] == '#'
        if occupied
          if num_occupied >= too_many_neighbors
            next_occupied = false
          else
            next_occupied = occupied
          end
        else
          if num_occupied == 0
            next_occupied = true
          else
            next_occupied = false
          end
        end

        if occupied != next_occupied
          any_changes = true
        end

        next_grid[x][y] = next_occupied ? '#' : 'L'
      end
    end

    break if !any_changes

    grid = next_grid
  end

  G.values(grid).count {|s| s == '#'}
end


puts "Part 1: #{iterate_seating(grid, immediate_only: true, too_many_neighbors: 4)}"
puts "Part 2: #{iterate_seating(grid, immediate_only: false, too_many_neighbors: 5)}"
