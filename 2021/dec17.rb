#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

str = get_input_str_arr(__FILE__)[0]

_, xs, ys = str.split('=')
$xmin, $xmax = xs.split("..").map(&:to_i)
$ymin, $ymax = ys.split("..").map(&:to_i)

def shoot(vx, vy, log: false)
  y = 0
  x = 0
  max_y = 0
  first_far_enough = false

  loop do
    x += vx
    y += vy
    puts "  x, y = (#{x}, #{y})" if log
    max_y = [y, max_y].max
    vx -= 1 if vx != 0
    vy -= 1

    return [:insufficient_vx, nil] if vx == 0 && x < $xmin

    if x > $xmax
      return [:too_high, nil] if y > $ymax
      return [:miss, nil]
    end

    return [:hit, max_y] if $xmin <= x && x <= $xmax && $ymin <= y && y <= $ymax

    if x >= $xmin
      if y < $ymin
        return [:too_low, nil] if first_far_enough
        return [:miss, nil]
      end

      first_far_enough = true
    end
  end
end

max_h = 0
init_vx = 1

num_hits = 0

true_ymax = [$ymin.abs, $ymax.abs].max

while init_vx <= $xmax do
  init_vy = -true_ymax

  while init_vy.abs <= true_ymax do
    res, max_height = shoot(init_vx, init_vy)

    break if res == :insufficient_vx
    break if res == :too_high

    num_hits += 1 if max_height

    if max_height && max_height > max_h
      # shoot(init_vx, init_vy, log: true)
      # puts "New max height: #{max_height}"
      max_h = max_height
    end

    # puts "Trying init velocity (#{init_vx}, #{init_vy}): #{res}, #{max_height}" if res == :hit
    # puts "#{init_vx},#{init_vy}" if res == :hit
    init_vy += 1
  end

  init_vx += 1
  # puts "incrementing vx (now #{init_vx})"
end

puts "Part 1: #{max_h}"
puts "Part 2: #{num_hits}"
