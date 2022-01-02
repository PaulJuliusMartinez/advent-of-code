#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

cubes = [false] * 101 * 101 * 101

xmin = 0
xmax = 0
ymin = 0
ymax = 0
zmin = 0
zmax = 0

strs.each do |cmd|
  # puts "Processing #{cmd}"
  inst, ranges = cmd.split(" ")
  xc, yc, zc = ranges.split(",").map do |range|
    range = range[2..]
    range.split('..').map(&:to_i)
  end

  xmin = [xc[0], xmin].min
  xmax = [xc[1], xmax].max
  ymin = [yc[0], ymin].min
  ymax = [yc[1], ymax].max
  zmin = [zc[0], zmin].min
  zmax = [zc[1], zmax].max

  out_of_range = false
  [xc, yc, zc].each do |c|
    if c[1] < -50 || c[0] > 50
      out_of_range = true
    end

    c[0] = [c[0], -50].max
    c[1] = [c[1], 50].min
  end

  if out_of_range
    # puts "Skipping #{cmd}"
    next
  end
  new_val = inst == "on"

  (xc[0]..xc[1]).each do |x|
    sx = x * 101 * 101
    (yc[0]..yc[1]).each do |y|
      sy = y * 101
      (zc[0]..zc[1]).each do |z|
        i = sx + sy + z
        cubes[i] = new_val
      end
    end
  end
end

puts "Part 1: #{cubes.count {|x| x}}"

N_INFINITY = [xmin, ymin, zmin].min - 1
INFINITY = [xmax, ymax, zmax].max + 1


def cuboids_intersect?(c1, c2)
  c1.zip(c2).all? do |r1, r2|
    ranges_overlap?(r1, r2)
  end
end

# ---
# ------               X
# --------------       X
#      ---             X
#      ----------      X
#              ------
#     --------
def ranges_overlap?(r1, r2)
  r1min, r1max = r1
  r2min, r2max = r2

  return false if r1max < r2min
  return false if r2max < r1min

  true
end

def intersect_range(r1, r2)
  return nil if !ranges_overlap?(r1, r2)

  r1min, r1max = r1
  r2min, r2max = r2

  [
    [r1min, r2min].max,
    [r1max, r2max].min,
  ]
end

def side_of_range(range, selection)
  case selection
  when :left then [N_INFINITY, range[0] - 1]
  when :overlap then range
  when :right then [range[1] + 1, INFINITY]
  end
end

#                  |  |
#                  |  |
# r     +------+   |  |
# r     |      |   |  |
# r     |      |      |  |
# r     |      |      |     |
# r     +------+      |     |
#                     |     |
#                     |
#
# r ------               X
# r --------------       X
# r      ---             X
# r      ----------      X
def break_up_cuboid(cuboid, minus)
  parts = []

  [:left, :overlap, :right].each do |select_x|
    x_intersection = intersect_range(cuboid[0], side_of_range(minus[0], select_x))
    next if !x_intersection

    [:left, :overlap, :right].each do |select_y|
      y_intersection = intersect_range(cuboid[1], side_of_range(minus[1], select_y))
      next if !y_intersection

      [:left, :overlap, :right].each do |select_z|
        z_intersection = intersect_range(cuboid[2], side_of_range(minus[2], select_z))
        next if !z_intersection

        next if select_x == :overlap && select_y == :overlap && select_z == :overlap

        parts << [x_intersection, y_intersection, z_intersection]
      end
    end
  end

  parts
end


cuboid_states = {}
cuboid_states[[[xmin, xmax], [ymin, ymax], [zmin, zmax]]] = false

strs.each do |cmd|
  # puts "Processing #{cmd}"
  inst, ranges = cmd.split(" ")
  xr, yr, zr = ranges.split(",").map do |range|
    range = range[2..]
    range.split('..').map(&:to_i)
  end

  set_cuboid = [xr, yr, zr]

  new_cuboid_states = {}

  new_state = inst == "on"

  cuboid_states.each do |cuboid, state|
    if cuboids_intersect?(cuboid, set_cuboid)
      parts = break_up_cuboid(cuboid, set_cuboid)
      # puts "Had cuboid: #{cuboid.inspect}"
      # puts "Removed:    #{set_cuboid.inspect}"
      # puts (parts.empty? ? "Got nothing" : "Got:")

      # parts.each do |part|
      #   puts "  #{part.inspect}"
      # end
      # puts

      parts.each do |part|
        new_cuboid_states[part] = state
      end
    else
      new_cuboid_states[cuboid] = state
    end
  end

  new_cuboid_states[set_cuboid] = new_state

  cuboid_states = new_cuboid_states
end

total_on = 0
cuboid_states.each do |cuboid, state|
  next if !state

  size = 1
  cuboid.each do |(l, r)|
    size *= r - l + 1
  end
  total_on += size
end

puts "Part 2: #{total_on}"
