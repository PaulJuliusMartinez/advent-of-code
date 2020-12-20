#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

$edge_counts = ZHash.new

$tiles_to_edges = {}

$edge_vals_to_tiles = Hash.new {|h, k| h[k] = []}

def edge_to_i(edge)
  n = 0

  edge.chars.each_with_index do |ch, i|
    n += 2 ** i if ch == '#'
  end

  n
end

$tile_nums_to_outer_tile = {}
$tile_nums_to_inner_tile = {}

grouped_strs.each do |tile|
  tile_num = tile[0].split(" ")[1].to_i

  tile.shift

  tile.each {|row| row.reverse!}

  edge0 = tile[0]
  edge1 = tile.last
  edge2 = tile.map(&:chars).map(&:first).join("")
  edge3 = tile.map(&:chars).map(&:last).join("")

  all = []
  [edge0, edge1, edge2, edge3].each do |edge|
    all << edge_to_i(edge)
    all << edge_to_i(edge.reverse)
  end

  all = all.uniq

  all.each do |val|
    $edge_counts[val] += 1
    $edge_vals_to_tiles[val] << tile_num
  end

  inner_tile = tile[1..-2]
  inner_tile.map! {|str| str[1..-2]}

  $tile_nums_to_inner_tile[tile_num] = inner_tile
  $tile_nums_to_outer_tile[tile_num] = tile

  $tiles_to_edges[tile_num] = all
end

corner_tile = nil

prod = 1
$tiles_to_edges.each do |tile_num, edge_vals|
  num_matching = edge_vals.count do |edge|
    $edge_counts[edge] == 2
  end
  # puts "Tile #{tile_num} has #{num_matching} matching edges"
  if edge_vals.count {|edge| $edge_counts[edge] == 2} == 4
    corner_tile = tile_num
    prod *= tile_num
  end
end

puts prod

# Reassemble image


def get_neighbors_of_tile(tile_num)
  s = Set.new

  $tiles_to_edges[tile_num].each do |edge|
    $edge_vals_to_tiles[edge].each do |neighbor_tile|
      s << neighbor_tile if neighbor_tile != tile_num
    end
  end

  s
end

NUM_TILES = $tiles_to_edges.count # 144
SIZE = Math.sqrt(NUM_TILES).to_i
image = []
SIZE.times {image << Array.new(SIZE)}

image[0][0] = corner_tile
# corner_neighbors = get_neighbors_of_tile(corner_tile).to_a
# image[0][1] = corner_neighbors[0]
# image[1][0] = corner_neighbors[1]

puts corner_tile
puts get_neighbors_of_tile(corner_tile).inspect
puts image.inspect

used_tiles = Set.new
used_tiles << corner_tile

# Assemble image in layers of squares
(SIZE - 1).times do |layer|
  # Fill right side
  x = layer + 1
  (layer + 1).times do |y|
    left = (image[y] || [])[x - 1]
    above = (image[y - 1] || [])[x]

    left_possibilities = get_neighbors_of_tile(left)
    # puts "Around left: #{left_possibilities.to_a}"
    left_possibilities.to_a.each {|t| left_possibilities.delete(t) if used_tiles.include?(t)}
    # puts "Around left (and unused): #{left_possibilities.to_a}"

    if above
      above_possibilities = get_neighbors_of_tile(above)
      # puts "Around above: #{above_possibilities.to_a}"
      above_possibilities.to_a.each {|t| above_possibilities.delete(t) if used_tiles.include?(t)}
      # puts "Around above (and unused): #{above_possibilities.to_a}"

      left_possibilities &= above_possibilities
    end

    # puts "Remaining poss.: #{left_possibilities.to_a}"

    # puts "Putting #{left_possibilities.to_a[0]} at (#{x}, #{y})"
    image[y][x] = left_possibilities.to_a[0]
    used_tiles << image[y][x]
  end

  # Fill left side
  y = layer + 1
  (layer + 1).times do |x|
    left = (image[y] || [])[x - 1]
    above = (image[y - 1] || [])[x]

    above_possibilities = get_neighbors_of_tile(above)
    # puts "Around above: #{above_possibilities.to_a}"
    above_possibilities.to_a.each {|t| above_possibilities.delete(t) if used_tiles.include?(t)}
    # puts "Around above (and unused): #{above_possibilities.to_a}"

    if left
      left_possibilities = get_neighbors_of_tile(left)
      # puts "Around left: #{left_possibilities.to_a}"
      left_possibilities.to_a.each {|t| left_possibilities.delete(t) if used_tiles.include?(t)}
      # puts "Around left (and unused): #{left_possibilities.to_a}"

      above_possibilities &= left_possibilities
    end

    # puts "Remaining poss.: #{above_possibilities.to_a}"

    # puts "Putting #{above_possibilities.to_a[0]} at (#{x}, #{y})"
    image[y][x] = above_possibilities.to_a[0]
    used_tiles << image[y][x]
  end

  # Fill in corner
  # layer = 0, want above = (y: 0, x: 1), left: (y: 1, x: 0)
  n1 = image[layer][layer + 1]
  n2 = image[layer + 1][layer]

  n1_possibilities = get_neighbors_of_tile(n1)
  # puts "Around n1: #{n1_possibilities.to_a}"
  n1_possibilities.to_a.each {|t| n1_possibilities.delete(t) if used_tiles.include?(t)}
  # puts "Around n1 (and unused): #{n1_possibilities.to_a}"

  if n2
    n2_possibilities = get_neighbors_of_tile(n2)
    # puts "Around n2: #{n2_possibilities.to_a}"
    n2_possibilities.to_a.each {|t| n2_possibilities.delete(t) if used_tiles.include?(t)}
    # puts "Around n2 (and unused): #{n2_possibilities.to_a}"

    n1_possibilities &= n2_possibilities
  end

  # puts "Remaining poss.: #{n1_possibilities.to_a}"

  # puts "Putting #{n1_possibilities.to_a[0]} at (#{layer + 1}, #{layer + 1})"
  image[layer + 1][layer + 1] = n1_possibilities.to_a[0]
  used_tiles << image[layer + 1][layer + 1]
end


def matching_edge_between_tiles(tile1, tile2)
  $tiles_to_edges[tile1].each do |edge|
    $edge_vals_to_tiles[edge].each do |neighbor_tile|
      return edge if neighbor_tile == tile2
    end
  end

  puts "NO MATCHING EDGE"
  exit(1)
end

def rotate_tile_left(tile)
  width = tile[0].length
  height = tile.length
  new_tile = Array.new(width) {Array.new(height)}

  height.times do |y|
    width.times do |x|
      # top right: y:0, x:w to y:0, x: 0
      # top left: y:0, x:0 to y:w, x: 0
      # bottom left: y:l, x:0 to y:l, x: l
      # bottom right: y:l, x:l to y:0, x:l
      new_tile[width - 1 - x][y] = tile[y][x]
    end
  end

  new_tile.each_with_index do |row, i|
    new_tile[i] = row.join("")
  end

  new_tile
end

def rotate_tile_180(tile)
  rotate_tile_left(rotate_tile_left(tile))
end

def rotate_tile_right(tile)
  rotate_tile_left(rotate_tile_left(rotate_tile_left(tile)))
end

def flip_horizontal(tile)
  tile.map {|s| s.reverse}
end

def flip_vertical(tile)
  tile.reverse
end

image.each do |row|
  puts row.join("  ")
end

oriented_tiles = Array.new(SIZE) {Array.new(SIZE)}
oriented_outer_tiles = Array.new(SIZE) {Array.new(SIZE)}

# My input
oriented_tiles[0][0] = rotate_tile_left($tile_nums_to_inner_tile[image[0][0]])
oriented_outer_tiles[0][0] = rotate_tile_left($tile_nums_to_outer_tile[image[0][0]])

# Ex1
# oriented_tiles[0][0] = rotate_tile_left(flip_horizontal($tile_nums_to_inner_tile[image[0][0]]))
# oriented_outer_tiles[0][0] = rotate_tile_left(flip_horizontal($tile_nums_to_outer_tile[image[0][0]]))

def put_inner_tile_num(tile_num)
  put_tile($tile_nums_to_inner_tile[tile_num])
end

def put_outer_tile_num(tile_num)
  put_tile($tile_nums_to_outer_tile[tile_num])
end

def put_tile(tile)
  tile.each {|s| puts s}
end

put_tile(oriented_outer_tiles[0][0])

puts "****************"
puts image[0][0]
put_outer_tile_num(image[0][0])
puts "****************"
puts image[0][1]
put_outer_tile_num(image[0][1])

puts "****************"


# Fill in top row
(SIZE - 1).times do |x|
  x = x + 1
  me = image[0][x]

  my_inner_tile = $tile_nums_to_inner_tile[me]
  my_outer_tile = $tile_nums_to_outer_tile[me]

  right_edge = oriented_outer_tiles[0][x-1].map(&:chars).map(&:last).join("")

  # puts "right edge: #{right_edge}"

  found_orientation = false
  [false, true].each do |should_flip|
    [0, 1, 2, 3].each do |rotate|
      # puts "flip?: #{should_flip}, times: #{rotate}"

      o_inner = my_inner_tile
      o_outer = my_outer_tile
      o_inner = flip_horizontal(o_inner) if should_flip
      o_outer = flip_horizontal(o_outer) if should_flip
      rotate.times do
        o_inner = rotate_tile_left(o_inner)
        o_outer = rotate_tile_left(o_outer)
      end

      left_edge = o_outer.map {|s| s[0]}.join("")

      # puts "left edge (of below): #{left_edge}"
      # puts '---'
      # put_tile(o_outer)
      # puts '---'

      if right_edge == left_edge
        oriented_tiles[0][x] = o_inner
        oriented_outer_tiles[0][x] = o_outer
        found_orientation = true
        # puts "found orientation!: rotate?: #{should_flip}, times: #{rotate}"
        break
      end
    end
    break if found_orientation
  end

  if !found_orientation
    puts "Didn't find orientation"
  end
end

puts "FILLING IN ROWS BELOW"

(SIZE - 1).times do |y|
  y = y + 1
  SIZE.times do |x|
    me = image[y][x]

    # puts "TRYING TO orient y:#{y}, x:#{x}"

    my_inner_tile = $tile_nums_to_inner_tile[me]
    my_outer_tile = $tile_nums_to_outer_tile[me]

    bottom_edge = oriented_outer_tiles[y - 1][x].last

    # puts "bottom edge: #{bottom_edge}"

    found_orientation = false
    [false, true].each do |should_flip|
      [0, 1, 2, 3].each do |rotate|
        # puts "flip?: #{should_flip}, times: #{rotate}"

        o_inner = my_inner_tile
        o_outer = my_outer_tile
        o_inner = flip_horizontal(o_inner) if should_flip
        o_outer = flip_horizontal(o_outer) if should_flip
        rotate.times do
          o_inner = rotate_tile_left(o_inner)
          o_outer = rotate_tile_left(o_outer)
        end

        top_edge = o_outer[0]

        # puts "top edge (of above): #{top_edge}"
        # puts '---'
        # put_tile(o_outer)
        # puts '---'

        if bottom_edge == top_edge
          oriented_tiles[y][x] = o_inner
          oriented_outer_tiles[y][x] = o_outer
          found_orientation = true
          # puts "found orientation!: rotate?: #{should_flip}, times: #{rotate}"
          break
        end
      end
      break if found_orientation
    end

    if !found_orientation
      puts "Didn't find orientation"
    end
  end
end

def put_spaced_inner_tiles(tiles)
  SIZE.times do |outer_y|
    8.times do |inner_y|
      SIZE.times do |x|
        print tiles[outer_y][x][inner_y]
        print " "
      end
      puts
    end
    puts
  end
end

def put_spaced_outer_tiles(tiles)
  SIZE.times do |outer_y|
    10.times do |inner_y|
      SIZE.times do |x|
        print tiles[outer_y][x][inner_y]
        print " "
      end
      puts
    end
    puts
  end
end

put_spaced_outer_tiles(oriented_outer_tiles)
puts '**********'
put_spaced_inner_tiles(oriented_tiles)


final_grid = []

SIZE.times do |outer_y|
  8.times do |inner_y|
    row = ""
    SIZE.times do |x|
      row += oriented_tiles[outer_y][x][inner_y]
    end
    final_grid << row
  end
end

puts final_grid[0]
puts final_grid.last


SEA_MONSTER = [
  "                  # ",
  "#    ##    ##    ###",
  " #  #  #  #  #  #   ",
]

puts final_grid.length
puts final_grid[0].length

is_sea_monster = Array.new(96) {Array.new(96) {false}}

put_tile(final_grid)

[false, true].each do |should_flip|
  [0, 1, 2, 3].each do |rotate|
    sm = SEA_MONSTER
    sm = flip_horizontal(sm) if should_flip
    rotate.times {sm = rotate_tile_left(sm)}

    # puts "Looking for Sea Monster"
    # put_tile(sm)

    # Loop over every starting point
    96.times do |start_x|
      96.times do |start_y|
        found_sea_monster = true

        sm.length.times do |dy|
          sm[0].length.times do |dx|
            if sm[dy][dx] == '#'
              if (final_grid[start_y + dy] || [])[start_x + dx] != '#'
                found_sea_monster = false
                break
              end
            end
          end

          break if !found_sea_monster
        end

        if found_sea_monster
          puts "Found sea monster at y:#{start_y}, x:#{start_x}"
          sm.length.times do |dy|
            sm[0].length.times do |dx|
              if sm[dy][dx] == '#'
                is_sea_monster[start_y + dy][start_x + dx] = true
              end
            end
          end
        end
      end
    end
  end
end

total_hash = final_grid.join("").chars.count {|ch| ch == '#'}
sea_monster_points = 0
is_sea_monster.each do |ism_row|
  ism_row.each do |ism_cell|
    sea_monster_points += 1 if ism_cell
  end
end
puts total_hash
puts sea_monster_points

puts "Part 2: #{total_hash - sea_monster_points}"
