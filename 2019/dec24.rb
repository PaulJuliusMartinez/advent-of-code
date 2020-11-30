#! /usr/bin/env ruby

require './intcode-v3.rb'
require './input.rb'
require 'set'

strs = get_input_str_arr(__FILE__)

world = {}
strs.each.with_index do |line, y|
  line.split('').each.with_index do |ch, x|
    world[[x, y]] = ch
  end
end

def biodiversity(w)
  sum = 0
  (0...25).each do |val|
    x = val % 5
    y = val / 5
    sum += 2 ** val if w[[x, y]] == '#'
  end
  sum
end

DIRS = [[1, 0], [-1, 0], [0, 1], [0, -1]]

def next_world(w)
  next_w = {}
  w.keys.each do |pos|
    n = 0
    DIRS.each do |dir|
      x = pos[0] + dir[0]
      y = pos[1] + dir[1]
      n += 1 if w[[x, y]] == '#'
    end

    if w[pos] == '#'
      next_w[pos] = n == 1 ? '#' : '.'
    else
      next_w[pos] = (n == 1 || n == 2) ? '#' : '.'
    end
  end

  next_w
end



# Eris isn't a very large place; a scan of the entire area fits into a 5x5 grid (your puzzle input). The scan shows bugs (#) and empty spaces (.).
#
# Each minute, The bugs live and die based on the number of bugs in the four adjacent tiles:
#
# A bug dies (becoming an empty space) unless there is exactly one bug adjacent to it.
# An empty space becomes infested with a bug if exactly one or two bugs are adjacent to it.

bds = Set.new


w = world
bds << biodiversity(w)

loop do
  # (0...5).each do |y|
  #   (0...5).each do |x|
  #     print w[[x, y]]
  #   end
  #   puts
  # end
  # puts '----'
  w = next_world(w)

  bd = biodiversity(w)
  if bds.include?(bd)
    puts bd
    break
  end
  bds << bd
end

# NOT: 33159167
#
MINUTES = 200
N_WORLDS = MINUTES * 2 + 1

def print_world(w)
  (0...5).each do |y|
    (0...5).each do |x|
      if [x, y] == [2, 2]
        print '?'
      else
        print w[[x, y]]
      end
    end
    puts
  end
end

worlds = N_WORLDS.times.map {{}}
worlds[MINUTES] = world

def next_worlds(ws)
  ws.map.with_index do |pw, level|
    next_w = {}

    (0...25).each do |val|
      x = val % 5
      y = val / 5
      pos = [x, y]
      next if pos == [2, 2]

      n = 0
      DIRS.each do |dir|
        x = pos[0] + dir[0]
        y = pos[1] + dir[1]

        if x == 2 && y == 2
          lower_level_w = ws[level - 1] || {}

          if pos == [2, 1]
            n += (0...5).count {|lx| lower_level_w[[lx, 0]] == '#'}
          elsif pos == [2, 3]
            n += (0...5).count {|lx| lower_level_w[[lx, 4]] == '#'}
          elsif pos == [1, 2]
            n += (0...5).count {|ly| lower_level_w[[0, ly]] == '#'}
          elsif pos == [3, 2]
            n += (0...5).count {|ly| lower_level_w[[4, ly]] == '#'}
          end

        elsif x == -1 && dir == [-1, 0]
          n += 1 if (ws[level + 1] || {})[[1, 2]] == '#'
        elsif x == 5 && dir == [1, 0]
          n += 1 if (ws[level + 1] || {})[[3, 2]] == '#'
        elsif y == -1 && dir == [0, -1]
          n += 1 if (ws[level + 1] || {})[[2, 1]] == '#'
        elsif y == 5 && dir == [0, 1]
          n += 1 if (ws[level + 1] || {})[[2, 3]] == '#'
        else
          n += 1 if pw[[x, y]] == '#'
        end
      end

      if pw[pos] == '#'
        next_w[pos] = n == 1 ? '#' : '.'
      else
        next_w[pos] = (n == 1 || n == 2) ? '#' : '.'
      end
    end

    next_w
  end
end

#      |     |         |     |
#   1  |  2  |    3    |  4  |  5
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#   6  |  7  |    8    |  9  |  10
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |A|B|C|D|E|     |
#      |     |-+-+-+-+-|     |
#      |     |F|G|H|I|J|     |
#      |     |-+-+-+-+-|     |
#  11  | 12  |K|L|?|N|O|  14 |  15
#      |     |-+-+-+-+-|     |
#      |     |P|Q|R|S|T|     |
#      |     |-+-+-+-+-|     |
#      |     |U|V|W|X|Y|     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#  16  | 17  |    18   |  19 |  20
#      |     |         |     |
# -----+-----+---------+-----+-----
#      |     |         |     |
#  21  | 22  |    23   |  24 |  25
#      |     |         |     |


MINUTES.times do |n|
  worlds = next_worlds(worlds)
end

puts worlds.flat_map(&:values).count {|val| val == '#'}

# not 3468
# not 3379


__END__
.##.#
###..
#...#
##.#.
.###.
