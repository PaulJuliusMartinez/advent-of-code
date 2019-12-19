#! /usr/bin/env ruby

require './intcode-v3.rb'
require './input.rb'
require 'set'

start_time = Time.now

strs = get_input_str_arr(__FILE__)

maze = {}

$entrance = nil
keys = {}

strs.each.with_index do |line, y|
  line.split('').each.with_index do |ch, x|
    maze[[x, y]] = ch == '@' ? '.' : ch
    $entrance = [x, y] if ch == '@'
    if !['#', '.', '@'].include?(ch)
      key_name = ch.downcase
      keys[key_name] ||= {}
      keys[key_name][:key] = [x, y] if ch == ch.downcase
      keys[key_name][:door] = [x, y] if ch == ch.upcase
    end
  end
end

DIRS = [
  [-1, 0],
  [1, 0],
  [0, 1],
  [0, -1],
]

MAX_DISTANCE = 999999999

# Could fill in holes in map

def fill_in_dead_ends(maze)
  dead_ends = []

  maze.each do |pos, ch|
    next if pos == $entrance
    if ch == '.'
      wall_neighbors = 0
      DIRS.each do |dir|
        neighbor = [pos[0] + dir[0], pos[1] + dir[1]]
        wall_neighbors += 1 if maze[neighbor] == '#'
      end
      dead_ends << pos if wall_neighbors == 3
    end
  end

  while dead_end = dead_ends.pop
    maze[dead_end] = '#'

    DIRS.each do |dir|
      neighbor = [dead_end[0] + dir[0], dead_end[1] + dir[1]]
      next if maze[neighbor] != '.'

      wall_neighbors = 0
      DIRS.each do |neighbor_dir|
        n_neighbor = [neighbor[0] + neighbor_dir[0], neighbor[1] + neighbor_dir[1]]
        wall_neighbors += 1 if maze[n_neighbor] == '#'
      end
      dead_ends << neighbor if wall_neighbors == 3
    end
  end
end

fill_in_dead_ends(maze)

def print_maze(maze)
  x_max = maze.keys.map(&:first).max
  y_max = maze.keys.map(&:last).max

  (0..y_max).each do |y|
    (0..x_max).each do |x|
      if [x, y] == $entrance
        print '@'
      elsif maze[[x, y]] == '#'
        print ' '
      elsif maze[[x, y]] == '.'
        print '#'
      else
        print maze[[x, y]]
      end
    end
    puts
  end
end

class Node
  attr_reader :ch, :neighbors, :pos, :key, :key_for_door

  def initialize(ch, x, y)
    @ch = ch
    @x = x
    @y = y
    @is_key = ch != '.' && ch != '@' && ch == ch.downcase
    @key = @is_key ? ch.bytes[0] - 'a'.bytes[0] : nil
    @is_door = ch != '.' && ch != '@' && ch == ch.upcase
    @key_for_door = @is_door ? ch.downcase.bytes[0] - 'a'.bytes[0] : nil
    @neighbors = {}
    @pos = [x, y]
  end

  def is_key?
    @is_key
  end

  def is_door?
    @is_door
  end

  def add_neighbor(neighbor, distance)
    @neighbors[neighbor] = [distance, @neighbors[neighbor] || MAX_DISTANCE].min
  end

  def remove_neighbor(neighbor)
    @neighbors.delete(neighbor)
  end

  def to_s
    "[#{@x}, #{@y}]: #{@ch}"
  end
end

# Create generalized graph of points of interests on graph

def calculate_points_of_interest(maze)
  pois = Set.new

  maze.each do |pos, ch|
    next if ch == '#'
    if ch == '.'
      num_neighbors = 0
      DIRS.each do |dir|
        neighbor = [pos[0] + dir[0], pos[1] + dir[1]]
        if maze[neighbor] != '#'
          num_neighbors += 1
        end
      end
      if num_neighbors > 2 || pos == $entrance
        pois << Node.new(ch, pos[0], pos[1])
      end
    elsif
      pois << Node.new(ch, pos[0], pos[1])
    end
  end

  loc_to_poi = pois.map {|poi| [poi.pos, poi]}.to_h

  pois.each do |poi|
    distances_from_poi = Hash.new {|h, k| h[k] = MAX_DISTANCE}
    distances_from_poi[poi.pos] = 0

    to_consider = [poi.pos]

    while curr = to_consider.pop
      curr_distance = distances_from_poi[curr]

      DIRS.each do |dir|
        neighbor = [curr[0] + dir[0], curr[1] + dir[1]]
        next if maze[neighbor] == '#'

        if neighbor_poi = loc_to_poi[neighbor]
          if neighbor_poi != poi
            poi.add_neighbor(neighbor_poi, curr_distance + 1)
            neighbor_poi.add_neighbor(poi, curr_distance + 1)
          end
        else
          if distances_from_poi[neighbor] > curr_distance + 1
            distances_from_poi[neighbor] = curr_distance + 1
            to_consider << neighbor
          end
        end
      end
    end
  end

  pois
end

points_of_interest = nil

loop do
  points_of_interest = calculate_points_of_interest(maze)

  # Some doors don't lead anywhere...
  removed_any = false

  points_of_interest.to_a.each do |poi|
    next if !poi.is_door?
    next if poi.neighbors.length > 1
    if !poi.is_key?
      # puts "#{poi} leads nowhere"
      poi.neighbors.each do |neighbor_poi, _|
        neighbor_poi.remove_neighbor(poi)
      end
      maze[poi.pos] = '#'
      removed_any = true
    end
  end

  break if !removed_any

  # puts "Filling in more dead ends..."
  fill_in_dead_ends(maze)
end

loc_to_poi = points_of_interest.map {|poi| [poi.pos, poi]}.to_h

# points_of_interest.each do |poi|
#   puts poi.to_s
#   poi.neighbors.each do |neighbor_poi, distance|
#     puts "  #{distance} to #{neighbor_poi}"
#   end
# end

# Some things are located along dead ends, so if we get anything along that
# dead end, we should always get it next.

$ALWAYS_NEXT = {}
# puts 'ALWAYS NEXT'
points_of_interest.to_a.each do |poi|
  next if !poi.is_key?
  next if poi.neighbors.count != 1
  # puts "Starting ALWAYS_NEXT chain at #{poi}"
  neighbor_poi = poi.neighbors.first[0]
  required_keys = []

  prev_poi = poi
  prev_key_poi = poi
  total_distance = 0
  loop do
    if (neighbor_poi.neighbors.keys - [prev_poi]).length != 1
      # puts "  Ending chain because next position #{neighbor_poi} has more than 2 neighbors"
      break
    end

    total_distance += neighbor_poi.neighbors[prev_poi]

    if neighbor_poi.is_door?
      required_keys << neighbor_poi.key_for_door
      # puts "  Adding door #{neighbor_poi.ch} to chain"
    elsif neighbor_poi.is_key?
      $ALWAYS_NEXT[neighbor_poi] = [required_keys, prev_key_poi, total_distance]
      # puts "  If have keys: #{required_keys}, always go from #{neighbor_poi} to #{prev_key_poi} in #{total_distance} steps"
    else
      # puts "  Ending chain because reached fork"
      break
    end

    next_poi = (neighbor_poi.neighbors.keys - [prev_poi]).first
    prev_poi = neighbor_poi
    if neighbor_poi.is_key?
      prev_key_poi = neighbor_poi
      total_distance = 0
    end
    neighbor_poi = next_poi
  end

  if neighbor_poi.is_key?
    $ALWAYS_NEXT[neighbor_poi] = poi
    puts "ALWAYS GO FROM #{neighbor_poi} to #{poi}"
  end
end

# print_maze(maze)
# puts points_of_interest.count

class KeySet
  def initialize(num_keys)
    @keys = [false] * num_keys
    @num_keys = 0
  end

  def add_key(key)
    @num_keys += 1 if !@keys[key]
    @keys[key] = true
  end

  def remove_key(key)
    @num_keys -= 1 if @keys[key]
    @keys[key] = false
  end

  def include?(key)
    @keys[key]
  end

  def count
    @num_keys
  end
end

def shortest_distances(pois, curr_poi, current_key_set)
  shortest_distance = Hash.new {|h, k| h[k] = MAX_DISTANCE}
  shortest_distance[curr_poi] = 0

  to_consider = [curr_poi]

  while next_poi = to_consider.pop
    curr_distance = shortest_distance[next_poi]

    next_poi.neighbors.each do |neighbor_poi, distance|
      # We can't go do doors if we don't have the key.
      if neighbor_poi.is_door? && !current_key_set.include?(neighbor_poi.key_for_door)
        next
      end

      if shortest_distance[neighbor_poi] > curr_distance + distance
        shortest_distance[neighbor_poi] = curr_distance + distance

        # We want to consider distances to new keys, so if we get to a key, it doesn't
        # make sense to go to any keys _after_ it; we'd pick those up along the way.
        if neighbor_poi.is_key? && !current_key_set.include?(neighbor_poi.key)
          next
        end

        to_consider << neighbor_poi
      end
    end
  end

  shortest_distance.delete(curr_poi)

  shortest_distance
end

key_pois = points_of_interest.select(&:is_key?)

curr_keys = KeySet.new(key_pois.count)
from_start = shortest_distances(points_of_interest, loc_to_poi[$entrance], curr_keys)


# from_start.each do |poi, distance|
#   if from_start[poi] < MAX_DISTANCE
#     puts "Can reach #{poi} from start in #{distance} steps."
#   end
# end

# Manually encoded: Only get these keys if you have another key.
only_ifs = [
  ['j', ['q']],
  ['k', ['q']],
  ['i', ['n', 'r', 'd']],
  ['a', ['l', 'c']],
  ['e', ['t']],
  ['y', ['p', 'z']],
]

$chars_to_key_door_pairs = {}
points_of_interest.each do |poi|
  if poi.is_key?
    $chars_to_key_door_pairs[poi.ch] ||= [nil, nil]
    $chars_to_key_door_pairs[poi.ch][0] ||= poi
  elsif poi.is_door?
    $chars_to_key_door_pairs[poi.ch.downcase] ||= [nil, nil]
    $chars_to_key_door_pairs[poi.ch.downcase][1] ||= poi
  end
end

$ONLY_IF = {}
only_ifs.each do |key, reqs|
  key_poi = $chars_to_key_door_pairs[key][0]
  req_keys = reqs.map {|req| $chars_to_key_door_pairs[req][0].key}
  $ONLY_IF[key_poi] = req_keys
  # puts "Only get #{key_poi} if you have keys: #{req_keys}"
end

best_order = ['n', 'b', 'd', 'r', 's', 'i', 'h', 'l', 'c', 'a', 'f', 't', 'g', 'e', 'z', 'm', 'o', 'q', 'k', 'j', 'p', 'y', 'u', 'w', 'r', 'x']
$BEST_ORDER = best_order.map do |ch|
  $chars_to_key_door_pairs[ch][0]
end

def find_remaining_keys(pois, curr_poi, curr_keys, key_pois, curr_steps, max_steps)
  if curr_steps >= max_steps
    # puts "Quit because path isn't good enough"
    return max_steps
  end
  if curr_keys.count == key_pois.count
    # puts "FINISHED IN #{curr_steps}"
    return curr_steps
  end

  required_keys, always_next_poi, always_next_poi_distance = $ALWAYS_NEXT[curr_poi]
  if always_next_poi && required_keys.all? {|k| curr_keys.include?(k)}
    distances = Hash.new {|h, k| h[k] = MAX_DISTANCE}
    distances[always_next_poi] = always_next_poi_distance
  else
    distances = shortest_distances(pois, curr_poi, curr_keys)
  end

  keys_to_get = []

  key_pois.each do |key_poi|
    next if curr_keys.include?(key_poi.key)
    distance_to_key = distances[key_poi]
    # Can get to key
    if distance_to_key < MAX_DISTANCE
      key_reqs = $ONLY_IF[key_poi]
      if key_reqs && !key_reqs.all? {|k| curr_keys.include?(k)}
        next
      end
      keys_to_get << [distance_to_key, key_poi]
    end
  end

  keys_to_get.sort_by(&:first).each do |distance_to_key, key_poi|
    new_curr_steps = curr_steps + distance_to_key

    # puts "At #{curr_steps}, in loc #{curr_poi}, taking #{distance_to_key} steps to get #{key_poi.key}, currently have keys: #{curr_keys.inspect}"
    curr_keys.add_key(key_poi.key)
    total_distance = find_remaining_keys(
      pois,
      key_poi,
      curr_keys,
      key_pois,
      new_curr_steps,
      max_steps,
    )
    curr_keys.remove_key(key_poi.key)

    max_steps = [total_distance, max_steps].min
  end

  return max_steps
end

curr_best = MAX_DISTANCE

# puts points_of_interest.count
puts find_remaining_keys(points_of_interest, loc_to_poi[$entrance], curr_keys, key_pois, 0, curr_best)


def steps_in_path(pois, curr_poi, dests, all_keys)
  dests = dests.map {|ch| $chars_to_key_door_pairs[ch][0]}
  total_steps = 0
  while dests.any?
    next_dest = dests.shift
    distances = shortest_distances(pois, curr_poi, all_keys)
    total_steps += distances[next_dest]
    curr_poi = next_dest
  end
  total_steps
end

all_keys = KeySet.new(26)
(0...26).each {|k| all_keys.add_key(k)}

# 1  2
#
# 4  3
s1 = loc_to_poi[[$entrance[0] - 1, $entrance[1] - 1]]
s2 = loc_to_poi[[$entrance[0] + 1, $entrance[1] - 1]]
s3 = loc_to_poi[[$entrance[0] + 1, $entrance[1] + 1]]
s4 = loc_to_poi[[$entrance[0] - 1, $entrance[1] + 1]]
q1_steps = steps_in_path(points_of_interest, s1, ['k', 'j', 'p'], all_keys)
q2_steps = steps_in_path(points_of_interest, s2, ['i', 'h', 'a', 'f', 't'], all_keys)
q3_steps = steps_in_path(points_of_interest, s3, ['m', 'o', 'q', 'y', 'u', 'w', 'v', 'x'], all_keys)
q4_steps = steps_in_path(points_of_interest, s4, ['n', 'b', 'd', 'r', 's', 'l', 'c', 'g', 'e', 'z'], all_keys)

# puts q1_steps
# puts q2_steps
# puts q3_steps
# puts q4_steps
puts q1_steps + q2_steps + q3_steps + q4_steps


# puts Time.now - start_time

__END__
#################################################################################
#.................#...#.#...............#...#.........#.......#.......#.....#...#
#######.#.#######.#.#.#.#.#######.#######.#.#.###.#####.#####.#.#.###C###.#.#.#.#
#.E...#.#.#.....#...#...#.#.....#.......#.#.#t#.#.....#.#...#...#.#.#.#...#.#.#.#
#.###.###.#.###.#######.#.#.###.#######.#.###.#.#####.#.#.#.#####.#.#.#.###.#.#.#
#.#.......#...#...#...#.#.#.#.......#...#.#.........#...#.#.....#f#.....#...#a#.#
#.#########.#.#####.#.#.#.###.#####.#.###.#.#######.#####.#.###.#.#######.###.###
#...#.....#.#.....#.#...#...#.#.....#...#...#...#.#.....#.#...#.#...#h..#...#...#
#.#.#.###.#####.#.#.#######.#.#.#######.#.###.#.#.#####.###.#.#####.#.#.###.###.#
#.#.#...#.....#.#...#...#...#.#...#...#.#...#.#.#.....#...#.#.#.....#.#...#.L.#.#
###.#.#######.#.#####.#.#.###.###.###.#.#####.#.#.###.###.###.#.#####.###.###.#.#
#...#.#...#...#...#...#.#...#...#.....#.#...#.#.#...#.........#.#.......#...#...#
#.###.#.#.#.#####.#.###.###.#.#.#####.#.#.#.#.#.###.###########.#.#####.###.###.#
#.....#.#...#.....#...#...#.#.#.#.....#.#.#...#.#.....#.....#...#...#.#.#...#...#
#.#####.###.#####.###.###.#.###.#.#####.#.#####.#.#####.###.#.#####.#.#.###.#.###
#...#.#...#.#...#.#...#.#.#.#...#.....#.#.#.....#.#.....#...#...#.#.#.#...#.#...#
###.#.###.###.#.###.###.#.#.#.#.#######.#.#.#######.#####.#####.#.#.#.###.#####.#
#.#.....#.....#.....#...#.#...#.#.......#.#.......#...#.#.#.....#.#.#...#.......#
#.#####.#############.#.#.#.#####.#####.#.#######.###.#.#.###.###.#.#.###########
#.....#.#.#...........#.#...#.....#.....#.#...#...#...#.#.....#...#.#...........#
#.#.###.#.#.#.#####.#########.#####.#####.#.#.#.###.###.#.#####.#.#.###.#########
#.#.#...#...#.....#.#.......#.#.........#...#.#.....#.....#.X.#.#.#...#.#...#...#
###.#.###########.#########.#.#########.#.###.#######.#####.###.#####D#.#.#.#.#.#
#...#.#...........#.......#.#.....#.....#...#...#...#...#.#...#.......#...#...#.#
#.#.#.###.#######.#.#.#.###.#.###.#####.#.#####.###.###.#.###.#######.###.#####.#
#.#.#....k#...#...#.#.#.#...#...#.....#.#.#.....#.....#.#...#.#...V.#...#...#...#
#.#.#########.#.###.#.#.#.#####.#####.###.#.#####.#####.###.#.#.###.###.###.#.###
#.#...#.......#.#...#.#.#...#.......#...#.#.#.....#.....#...#...#...#.#.#.#.#...#
#.###.#.#######.#.###.#####.#.#########.#.#.###.#.#.#####.#######.###.#.#.#.###.#
#...#...#.......#.#.#.....#.#.#.#.......#.#.#...#.#.#.#...#.......#...R.#...#...#
#.#.#####.#######.#.#####.#.#.#.#.#####.###.#.#####.#.#.#.#W#######.#####S###.#.#
#.#......j#...#...#...I.#...#...#.#.....#...#.......#...#.#.#.....#...#.#.#.#.#.#
#.#########.###.###.###.#########.#####.#.#######.#######.#.#.###.###.#.#.#.#.#.#
#.......#.....#.....#.#.#...#.....#...#.#.......#.........#...#.#.#.#.#.#.#.#.#.#
#######.###.#.#######U#.#.#.#.#####.#.#########.###.###########.#.#.#.#.#.#.#.###
#...Y.#...#.#.........#...#.#.......#...#.#...#.#...#.............#.#.#.....#...#
#.#######.#.###.#####.#####.#########.#.#.#.#.#.#####.#############.#.#########B#
#...#.Q...#.#...#.#...#...#.#...#...#.#.#...#.#.......#i..#.....#...#.........#.#
#.#.#.#######.###.#.#####.#.#.#.#.#.###.#.###.#########.#.#.#.###.#.#########.#.#
#.#...........#p..........#...#...#.........#...........#...#.....#...N.........#
#######################################.@.#######################################
#.#.....#.#.........#.........#.....#.......#...#.......#...#.....#...G.....#...#
#.#.#.#.#.#.#####.#.#######.#.#.###.#.###.#.#.#.#.#####.#.###.###.#.#####.#.#.#.#
#...#r#.#.#.#...#n#.........#...#.#.#...#.#.#.#.#...#...#...#.#.#...#...#.#...#.#
#.###.#.#.#.#.###.###############.#.###.#.#.#.#.#.#.#.#####.#.#.#######.#.#####.#
#.#d#.#.#.....#...#.........#.....#.....#.#..m#.#.#.#.....#.#.#.....#...#...#...#
#.#.#.#.#######.#########.###.#.#######.#.#####.#.#.#####.#.#.###.#.#.#####.#.###
#...#.#.#..b....#.....#...#...#.#.....#.#.#...#.#.#.#.......#.....#...#.....#...#
#.###.#.#.#######.###.#.###.###.#.###.#.#.#.#.#.#.#.#################.#.#######.#
#.#...#...#.......#...#.#...#.#...#.#...#.#.#.#.#.#.#.....#.......#...#...#.K.#.#
###.#######.###.###.###.#.###.#####.#####.#.#.#.#.#.#.###.#.#####.#.#####.#.#.#.#
#...#.......#.#...#.....#...#.......#...#.#.#...#.#.#.#.#...#...#.....#...#.#.#.#
#.#####.#####.###.#####.###.###.#.#.###.#.###.#####.#.#.#####.#########.###.###.#
#.#...#..z#.....#...#.#.#.#...#.#.#.....#...#.#.....#.....#...#.........#.....#.#
#.#.#.###.###.#.###.#.#.#.###.###.#####.###.#.#.#.#######.###.#.#########.###.#.#
#.#.#..s#.....#.#...#.......#...#.#.#...#...#...#.#.....#.....#...#.#.....#.#.#.#
#.#.###.#######.#.#############.#.#.#.###.#########.#.#######.###.#.#.#####.#.#.#
#.....#.#.....#.#.............#...#...#.#.M...#.....#...#...#.#...#...#.....#...#
#######.#.###.#######.#####.#.#####.###.#####.#.#######.#.#.#.#.#####.###.#.#####
#...#...#.#.#.......#.....#.#...#...#...#.....#.#.....#.#.#...#.....#.....#...#.#
#O###.###.#.#######.###.###.#####.#####.#.#####.#.###.#.#.#####.###.#########.#.#
#...#.....#.....#...#.#.#...#.....#.....#.....#...#.#.#.#...#.#...#......o#...#.#
###.#########.#.#.#.#.#.#.#.#.#######.#.#####.#####.#.#.###.#.###.#######.#.###J#
#...#.........#.#.#.#.#.#.#.#.#.......#.#.......#.....#.#...#..x#.#.....#.#.....#
#.#.#.#########.#.###.#.#.###.###.#.#####.#####.#.#####.#.#####.#.#.#####.#.#####
#.#...#....g#.#.#.....#.#...#...#.#.....#.....#.#.#...#.....#...#...#.....#.#...#
#.###.#.###.#.#.###########.###.#######.#.###.###.#.#######.#.#####.#.###.###.#.#
#.#.#.#...#.#.................#.#...#...#.#.#.....#.#....v#.#.#.....#.#.#.#...#.#
#.#.#.###.#.###########.#####.#.#.#.#.#.#.#.#######.#.###.###.#.#####.#.#.#.###.#
#.#.#...#.#...F...#.....#...#.#.#.#...#.#.#.....#...#...#.....#.....#.#...#q#.#.#
#.#.###.#.#######.#.#####.#.###.#.#######.###.#.#.#.###.###########.#.#####.#.#.#
#.#...#.#.#...#...#.#...#.#.....#.......#.....#...#.#.#w#.........#.#.....#.#.#.#
#.#.#.#.#.#.#.#.#.###.#.#.#########.###.###########.#.#.#.#.#####.#######.#.#.#.#
#.#.#...#.#.#...#.#...#.#...#.....#...#.#...#.......#.#.#.#.#...#.P.#...#.#...#y#
#.#######.#.#.#####.###.###.#.###.#####.#.###.#######.#.###.#.#.###.#.#.#.#.###.#
#.#.....#.#c#.#...#.#l..#...#...#.#.A.#.#.....#.......#...Z.#.#...#.#.#.#...#...#
#.#.###T#.#.###.#.#.#.###.###.#.#.#.#.#.#.#########.#.###########.#.#.#.#####.###
#.#...#.#.#.....#...#...#.H.#.#.#.#.#...#...#.......#.....#.......#...#.....#..u#
#.###.#.#.#############.###.###.#.#.###.###.###.#########.###.###.#########.###.#
#.....#..........e....#.........#...#...#.......#.............#...........#.....#
#################################################################################
