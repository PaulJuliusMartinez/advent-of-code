#! /usr/bin/env ruby

require './intcode.rb'
require './input.rb'

strs = get_input_str_arr(__FILE__)

$W = strs[0].length
$H = strs.length


def get_asteroids_visible_from(map, x, y)
  visible = []

  (0..($W - 1)).each do |px|
    (0..($H - 1)).each do |py|
      next if x == px && y == py
      next if map[py][px] == '.'
      can_see = true

      dx = px - x
      dy = py - y

      (2..([dx, dy].map(&:abs).max)).each do |p|
        if dx % p == 0 && dy % p == 0
          (1..(p - 1)).each do |c|
            if map[y + (dy / p) * c][x + (dx / p) * c] == '#'
              can_see = false
              # puts "Can't actually see (#{px}, #{py}) from (#{x}, #{y})"
            end
          end
        end
      end

      visible << [px, py] if can_see
    end
  end

  visible
end


num_visible =
  (0..($H - 1)).flat_map do |y|
    (0..($W - 1)).map do |x|
      if strs[y][x] == '.'
        nil
      else
        [get_asteroids_visible_from(strs, x, y).count, [x, y]]
      end
    end
  end
    .compact

num_visible.each do |a|
  # puts "#{a[0]} visible from (#{a[1][0]}, #{a[1][1]})"
end

num_visible.sort!

# Part 1
puts num_visible.last[0]
# puts num_visible.last[1].inspect

##########
# Part 2 #
##########

def vaporize_asteroids(map, x, y)
  vaporized_order = []
  loop do
    vaporized = get_asteroids_visible_from(map, x, y)
    break if vaporized.empty?

    vaporized_order += vaporized.map do |asteroid|
      ax, ay = asteroid
      dx = ax - x
      dy = ay - y

      # -1, -1          1, -1
      #
      #
      # -1, 1           1, 1

      section = 0 if dx == 0 && dy < 0
      section = 4 if dx == 0 && dy > 0
      section = 2 if dx > 0 && dy == 0
      section = 6 if dx < 0 && dy == 0
      section = 1 if dx > 0 && dy < 0
      section = 3 if dx > 0 && dy > 0
      section = 5 if dx < 0 && dy > 0
      section = 7 if dx < 0 && dy < 0

      slope = 0 if [0, 2, 4, 6].include?(section)

      slope = dy * 1.0 / dx

      [section, slope, asteroid]
    end
      .sort

    # I guess we don't need to support multiple rotations...
    break

    vaporized.each do |asteroid|
      ax, ay = asteroid
      map[ay][ax] = '.'
    end
  end

  vaporized_order
end

viewings = vaporize_asteroids(strs, num_visible.last[1][0], num_visible.last[1][1])
viewing200 = viewings[199]
puts viewing200[2][0] * 100 + viewing200[2][1]

__END__
.###.###.###.#####.#
#####.##.###..###..#
.#...####.###.######
######.###.####.####
#####..###..########
#.##.###########.#.#
##.###.######..#.#.#
.#.##.###.#.####.###
##..#.#.##.#########
###.#######.###..##.
###.###.##.##..####.
.##.####.##########.
#######.##.###.#####
#####.##..####.#####
##.#.#####.##.#.#..#
###########.#######.
#.##..#####.#####..#
#####..#####.###.###
####.#.############.
####.#.#.##########.
