#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

a2 = strs[2][3].ord - 'A'.ord
b2 = strs[2][5].ord - 'A'.ord
c2 = strs[2][7].ord - 'A'.ord
d2 = strs[2][9].ord - 'A'.ord
a1 = strs[3][3].ord - 'A'.ord
b1 = strs[3][5].ord - 'A'.ord
c1 = strs[3][7].ord - 'A'.ord
d1 = strs[3][9].ord - 'A'.ord

TOP_TO_INDEX = {
  0 => 0,
  1 => 1,
  2 => 3,
  3 => 5,
  4 => 7,
  5 => 9,
  6 => 10,
}

POD_CHARS = {0 => 'A', 1 => 'B', 2 => 'C', 3 => 'D'}

INDEX_TO_TOP_INDEX = TOP_TO_INDEX.invert

HOLE_TO_INDEX = {
  0 => 2,
  1 => 4,
  2 => 6,
  3 => 8
}

POD_COSTS = {
  0 => 1,
  1 => 10,
  2 => 100,
  3 => 1000,
}

class Room
  attr_accessor :energy, :tops, :holes

  def initialize(depth)
    @depth = depth
    @tops = [nil] * 7
    @holes = [
      [nil] * depth,
      [nil] * depth,
      [nil] * depth,
      [nil] * depth,
    ]
    @energy = 0
  end

  def init(as, bs, cs, ds)
    @holes = [as, bs, cs, ds]

    self
  end

  def dup
    duped = Room.new(@depth)
    duped.tops = @tops.dup
    duped.holes = @holes.map(&:dup)
    duped.energy = @energy

    duped
  end

  def possible_moves
    moves = []

    # Move back home
    # Need to check if space, and if an occupant, that occupant is
    # correct neighbor
    @tops.each.with_index do |pod, i|
      next if !pod

      hole_occupants = @holes[pod].compact
      next if hole_occupants.any? {|o| o != pod}

      move = {from_top: i, to_hole: pod, height: hole_occupants.length}
      moves << move if !obstructed?(move)
    end

    # Move out of starting block

    # Loop over every hole, try moving top, if no top, move bottom
    # Don't move top if in right hole and bottom is same
    # Don't move bottom if in right hole
    @holes.each.with_index do |hole, i|
      last_occupant_index = hole.rindex(&:itself)
      next if !last_occupant_index
      next if hole.all? {|pod| pod == i || !pod}

      7.times do |top|
        next if @tops[top]
        move = {top: top, from_hole: i, height: last_occupant_index}
        moves << move if !obstructed?(move)
      end
    end

    moves
  end

  def obstructed?(move)
    start_index, dest_index = start_dest_index_of_move(move)

    (start_index..dest_index).any? do |path_index|
      top_index = INDEX_TO_TOP_INDEX[path_index]
      next false if !top_index
      @tops[top_index]
    end
  end

  def start_dest_index_of_move(move)
    if (hole = move[:from_hole])
      start_index = HOLE_TO_INDEX[hole]
      dest_index = TOP_TO_INDEX[move[:top]]
    elsif (top = move[:from_top])
      start_index = TOP_TO_INDEX[move[:from_top]]
      dest_index = HOLE_TO_INDEX[move[:to_hole]]
    else
      raise 'Invalid move'
    end

    if start_index < dest_index
      [start_index + 1, dest_index]
    elsif start_index > dest_index
      [dest_index, start_index - 1]
    else
      raise 'start and dest same'
    end
  end

  def make_move(move)
    start_index, dest_index = start_dest_index_of_move(move)

    if (hole = move[:from_hole])
      hole_height = move[:height]
      pod = @holes[hole][hole_height]
      if !pod
        print
        puts move.inspect
        raise 'No pod in hole'
      end

      @holes[hole][hole_height] = nil
      @tops[move[:top]] = pod

      steps = @depth - hole_height # to get out of the hole
      steps += dest_index - start_index + 1

      @energy += steps * POD_COSTS[pod]
    elsif (top = move[:from_top])
      hole_height = move[:height]

      pod = @tops[top]

      @tops[top] = nil
      @holes[move[:to_hole]][hole_height] = pod

      steps = @depth - hole_height
      steps += dest_index - start_index + 1
      @energy += steps * POD_COSTS[pod]
    else
      raise 'Invalid move'
    end

    self
  end

  def progress
    return @progress if @progress
    num = 0
    @holes.each.with_index do |hole, i|
      # NOTE: not updated to handle variable @depths
      if hole[0] == i
        num += 1
        num += 1 if hole[1] == i
      end
    end
    @progress = num
    num
  end

  def done?
    @holes.each.with_index.all? do |hole, i|
      hole.all? {|pod| pod == i}
    end
  end

  def pod_at_top(i)
    POD_CHARS[@tops[i]] || '.'
  end

  def pod_at_hole(hole, height)
    POD_CHARS[@holes[hole][height]] || '.'
  end

  def print
    puts "############# (energy used: #{@energy}, progress: #{progress})"
    puts "##{pod_at_top(0)}#{pod_at_top(1)}.#{pod_at_top(2)}.#{pod_at_top(3)}.#{pod_at_top(4)}.#{pod_at_top(5)}#{pod_at_top(6)}#"
    @depth.times do |n|
      d = @depth - 1 - n
      middle = "##{pod_at_hole(0, d)}##{pod_at_hole(1, d)}##{pod_at_hole(2, d)}##{pod_at_hole(3, d)}#"
      if n == 0
        puts "###{middle}##"
      else
        puts "  #{middle}"
      end
    end
    puts "  #########"
  end

  def room_hash
    h = ""
    @tops.each {|t| h << (POD_CHARS[t] || '.')}
    @holes.each do |hole|
      hole.each {|pod| h << (POD_CHARS[pod] || '.')}
    end
    h << @energy.to_s
    h
  end
end

starting_room = Room.new(2).init([a1, a2], [b1, b2], [c1, c2], [d1, d2])

# DEBUG STUFF
#
# example_moves = [
#   {top: 2, from_hole: 2, height: 1},
# 
#   {top: 3, from_hole: 1, height: 1},
#   {from_top: 3, to_hole: 2, height: 1},
# 
#   {top: 3, from_hole: 1, height: 0},
#   {from_top: 2, to_hole: 1, height: 0},
# 
#   {top: 2, from_hole: 0, height: 1},
#   {from_top: 2, to_hole: 1, height: 1},
# 
#   {top: 4, from_hole: 3, height: 1},
#   {top: 5, from_hole: 3, height: 0},
# 
#   {from_top: 4, to_hole: 3, height: 0},
#   {from_top: 3, to_hole: 3, height: 1},
# 
#   {from_top: 5, to_hole: 0, height: 1},
# ]
# 
# room = starting_room
# example_moves.each do |move|
#   room.print
#   possible_moves = room.possible_moves
#   if !possible_moves.include?(move)
#     puts "Move not found"
#     puts "Current room"
#     room.print
#     puts "Looking for move: #{move.inspect}"
#     exit
#   end
# 
#   room = room.dup.make_move(move)
# end
# room.print

def least_energy(start)
  scenarios = [start]
  best_energy = 10000000000

  current_energy = 0

  seen_rooms = Set.new

  while scenarios.any?
    room = scenarios.pop
    room_hash = room.room_hash
    next if seen_rooms.include?(room_hash)
    seen_rooms << room_hash

    next if room.energy > best_energy
    # next if room.energy > 16059 #best_energy

    # if room.energy > current_energy
      # puts "Current room"
      # room.print
    #   current_energy = room.energy + 10
    # end

    possible_moves = room.possible_moves

    # if possible_moves.empty?
    #   puts "No possible moves:"
    #   #room.print
    # else
    #   puts "#{possible_moves.length} possible moves:"
    #   possible_moves.each {|m| puts "  #{m.inspect}"}
    # end

    possible_moves.each do |move|
      new_room = room.dup.make_move(move)
      # if move[:from_top]
      #   puts "Current room"
      #   room.print
      #   puts "Considering move: #{move.inspect} (cost: #{new_room.energy - room.energy})"
      #   puts "After move:"
      #   new_room.print
      # end

      if new_room.done?
        # puts "Solved room with energy: #{new_room.energy}"
        best_energy = [best_energy, new_room.energy].compact.min
        # puts "best energy = #{best_energy}" if new_room.energy == best_energy
      else
        scenarios << new_room if !seen_rooms.include?(new_room.room_hash)
      end
    end

    scenarios.sort_by!(&:progress)
  end

  best_energy
end

puts "Part 1: #{least_energy(starting_room)}"

starting_room = Room.new(4).init(
  [a1, 3, 3, a2],
  [b1, 1, 2, b2],
  [c1, 0, 1, c2],
  [d1, 2, 0, d2],
)

puts "Part 2: #{least_energy(starting_room)}"
