#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

map = {}

xr = [0, 0]
yr = [0, 0]
zr = [-1, 1]
wr = [-1, 1]

def update_range(r, val)
  [[r[0], val - 1].min, [r[1], val + 1].max]
end

strs.each_with_index do |str, y|
  str.chars.each_with_index do |ch, x|
    if ch == '#'
      map[[x, y, 0, 0]] = true

      xr = update_range(xr, x)
      yr = update_range(yr, y)
    end
  end
end

original_map = map

(1..2).each do |part|
  map = original_map

  6.times do
    new_map = {}

    w_range = part == 1 ? (0..0) : (wr[0]..wr[1])

    (xr[0]..xr[1]).each do |x|
      (yr[0]..yr[1]).each do |y|
        (zr[0]..zr[1]).each do |z|
          w_range.each do |w|

            num_neighbors = 0
            (-1..1).each do |dx|
              (-1..1).each do |dy|
                (-1..1).each do |dz|
                  (-1..1).each do |dw|
                    next if dx == 0 && dy == 0 && dz == 0 && dw == 0

                    next if part == 1 && dw != 0

                    if map[[x + dx, y + dy, z + dz, w + dw]]
                      num_neighbors += 1
                    end
                  end
                end
              end
            end

            new_state = nil
            if map[[x, y, z, w]]
              if num_neighbors == 2 || num_neighbors == 3
                new_state = true
              else
                new_state = false
              end
            else
              if num_neighbors == 3
                new_state = true
              else
                new_state = false
              end
            end

            new_map[[x, y, z, w]] = new_state

            if new_state
              xr = update_range(xr, x)
              yr = update_range(yr, y)
              zr = update_range(zr, z)
              wr = update_range(wr, w)
            end
          end
        end
      end
    end

    map = new_map
  end

  puts "Part #{part}: #{map.values.count(&:itself)}"
end
