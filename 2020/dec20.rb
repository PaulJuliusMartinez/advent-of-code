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

def extract_inner_tile(tile)
  inner_tile = tile[1..-2]
  inner_tile.map! {|str| str[1..-2]}
  inner_tile
end

grouped_strs.each do |tile|
  tile_num = tile[0].split(" ")[1].to_i

  tile.shift

  # This made my input easier to work with lol
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

  $tile_nums_to_inner_tile[tile_num] = extract_inner_tile(tile)
  $tile_nums_to_outer_tile[tile_num] = tile

  $tiles_to_edges[tile_num] = all
end

corner_tile = nil

prod = 1
$tiles_to_edges.each do |tile_num, edge_vals|
  # puts "Tile #{tile_num} has #{num_matching} matching edges"
  if edge_vals.count {|edge| $edge_counts[edge] == 2} == 4
    corner_tile = tile_num
    prod *= tile_num
  end
end

puts "Part 1: #{prod}"

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

# puts corner_tile
# puts get_neighbors_of_tile(corner_tile).inspect
# puts image.inspect

used_tiles = Set.new
used_tiles << corner_tile

def get_remaining_neighbor_tile(tile1, tile2, used_tiles)
  tile1_possibilities = get_neighbors_of_tile(tile1)
  # puts "Around tile1: #{tile1_possibilities.to_a}"
  tile1_possibilities.to_a.each {|t| tile1_possibilities.delete(t) if used_tiles.include?(t)}
  # puts "Around tile1 (and unused): #{tile1_possibilities.to_a}"

  if tile2
    tile2_possibilities = get_neighbors_of_tile(tile2)
    # puts "Around tile2: #{tile2_possibilities.to_a}"
    tile2_possibilities.to_a.each {|t| tile2_possibilities.delete(t) if used_tiles.include?(t)}
    # puts "Around tile2 (and unused): #{tile2_possibilities.to_a}"

    tile1_possibilities &= tile2_possibilities
  end

  tile1_possibilities
end

# Assemble image in layers of squares
#
#  123
#  223
#  333
(SIZE - 1).times do |layer|
  # Fill right side
  x = layer + 1
  (layer + 1).times do |y|
    left = (image[y] || [])[x - 1]
    above = (image[y - 1] || [])[x]

    possibilities = get_remaining_neighbor_tile(left, above, used_tiles)
    # puts "Putting #{possibilities.to_a[0]} at (#{x}, #{y})"
    image[y][x] = possibilities.to_a[0]
    used_tiles << image[y][x]
  end

  # Fill bottom side
  y = layer + 1
  (layer + 1).times do |x|
    left = (image[y] || [])[x - 1]
    above = (image[y - 1] || [])[x]

    possibilities = get_remaining_neighbor_tile(above, left, used_tiles)
    # puts "Putting #{possibilities.to_a[0]} at (#{x}, #{y})"
    image[y][x] = possibilities.to_a[0]
    used_tiles << image[y][x]
  end

  # Fill in corner
  # layer = 0, want above = (y: 0, x: 1), left: (y: 1, x: 0)
  n1 = image[layer][layer + 1]
  n2 = image[layer + 1][layer]

  possibilities = get_remaining_neighbor_tile(n1, n2, used_tiles)
  # puts "Putting #{possibilities.to_a[0]} at (#{layer + 1}, #{layer + 1})"
  image[layer + 1][layer + 1] = possibilities.to_a[0]
  used_tiles << image[layer + 1][layer + 1]
end

# image.each do |row|
#   puts row.join("  ")
# end

def rotate_tile_left(tile)
  width = tile[0].length
  height = tile.length
  new_tile = Array.new(width) {Array.new(height)}

  height.times do |y|
    width.times do |x|
      # top right: y:0, x:w to y:0, x: 0
      # top left: y:0, x:0 to y:w, x: 0
      # bottom left: y:h, x:0 to y:w, x:h
      # bottom right: y:h, x:w to y:0, x:h
      new_tile[width - 1 - x][y] = tile[y][x]
    end
  end

  new_tile.each_with_index do |row, i|
    new_tile[i] = row.join("")
  end

  new_tile
end

def flip_horizontal(tile)
  tile.map {|s| s.reverse}
end

def put_inner_tile_num(tile_num)
  put_tile($tile_nums_to_inner_tile[tile_num])
end

def put_outer_tile_num(tile_num)
  put_tile($tile_nums_to_outer_tile[tile_num])
end

def put_tile(tile)
  tile.each {|s| puts s}
end

def for_each_orientation(tile)
  [false, true].each do |should_flip|
    [0, 1, 2, 3].each do |rotate|
      orientation = tile
      orientation = flip_horizontal(orientation) if should_flip
      rotate.times {orientation = rotate_tile_left(orientation)}
      yield orientation
    end
  end
end

oriented_tiles = Array.new(SIZE) {Array.new(SIZE)}
oriented_outer_tiles = Array.new(SIZE) {Array.new(SIZE)}

# Figure out orientation of top-left corner:
for_each_orientation($tile_nums_to_outer_tile[image[0][0]]) do |tile|
  right_edge = tile.map(&:chars).map(&:last).join("")
  bottom_edge = tile.last

  right_edge_match = ($edge_vals_to_tiles[edge_to_i(right_edge)] - [image[0][0]])[0]
  bottom_edge_match = ($edge_vals_to_tiles[edge_to_i(bottom_edge)] - [image[0][0]])[0]

  if right_edge_match == image[0][1] && bottom_edge_match == image[1][0]
    oriented_outer_tiles[0][0] = tile
    oriented_tiles[0][0] = extract_inner_tile(tile)
  end
end


# put_tile(oriented_outer_tiles[0][0])
# 
# puts "****************"
# puts image[0][0]
# put_outer_tile_num(image[0][0])
# puts "****************"
# puts image[0][1]
# put_outer_tile_num(image[0][1])
# 
# puts "****************"


# Fill in top row
(SIZE - 1).times do |x|
  x = x + 1
  me = image[0][x]

  my_outer_tile = $tile_nums_to_outer_tile[me]

  right_edge = oriented_outer_tiles[0][x-1].map(&:chars).map(&:last).join("")

  # puts "right edge: #{right_edge}"

  for_each_orientation(my_outer_tile) do |o_outer|
    o_inner = extract_inner_tile(o_outer)
    left_edge = o_outer.map {|s| s[0]}.join("")

    # puts "left edge (of below): #{left_edge}"
    # puts '---'
    # put_tile(o_outer)
    # puts '---'

    if right_edge == left_edge
      oriented_tiles[0][x] = o_inner
      oriented_outer_tiles[0][x] = o_outer
      # puts "found orientation!: rotate?: #{should_flip}, times: #{rotate}"
      break
    end
  end
end

# puts "FILLING IN ROWS BELOW"

(SIZE - 1).times do |y|
  y = y + 1
  SIZE.times do |x|
    me = image[y][x]

    # puts "TRYING TO orient y:#{y}, x:#{x}"

    my_outer_tile = $tile_nums_to_outer_tile[me]

    bottom_edge = oriented_outer_tiles[y - 1][x].last

    # puts "bottom edge: #{bottom_edge}"

    for_each_orientation(my_outer_tile) do |o_outer|
      o_inner = extract_inner_tile(o_outer)

      top_edge = o_outer[0]

      # puts "top edge (of above): #{top_edge}"
      # puts '---'
      # put_tile(o_outer)
      # puts '---'

      if bottom_edge == top_edge
        oriented_tiles[y][x] = o_inner
        oriented_outer_tiles[y][x] = o_outer
        # puts "found orientation!: rotate?: #{should_flip}, times: #{rotate}"
        break
      end
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

# put_spaced_outer_tiles(oriented_outer_tiles)
# puts '**********'
# put_spaced_inner_tiles(oriented_tiles)


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

# puts final_grid[0]
# puts final_grid.last


SEA_MONSTER = [
  "                  # ",
  "#    ##    ##    ###",
  " #  #  #  #  #  #   ",
]

# puts final_grid.length
# puts final_grid[0].length

is_sea_monster = Array.new(96) {Array.new(96) {false}}

# put_tile(final_grid)

[false, true].each do |should_flip|
  [0, 1, 2, 3].each do |rotate|
    sm = SEA_MONSTER
    sm = flip_horizontal(sm) if should_flip
    rotate.times {sm = rotate_tile_left(sm)}

    # puts "Looking for Sea Monster"
    # put_tile(sm)

    # Loop over every starting point
    (8 * SIZE).times do |start_x|
      (8 * SIZE).times do |start_y|
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
          # puts "Found sea monster at y:#{start_y}, x:#{start_x}"
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
sea_monster_points = is_sea_monster.map {|ism_row| ism_row.count(&:itself)}.sum

puts "Part 2: #{total_hash - sea_monster_points}"
