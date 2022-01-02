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

  def initialize
    @tops = [nil] * 7
    @holes = [[nil, nil], [nil, nil], [nil, nil], [nil, nil]]
    @energy = 0
  end

  def init(a2, b2, c2, d2, a1, b1, c1, d1)
    @holes = [
      [a1, a2],
      [b1, b2],
      [c1, c2],
      [d1, d2],
    ]

    self
  end

  def dup
    duped = Room.new
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

      # Check if hole is full, or occupied by someone else.
      next if @holes[pod][1]

      next if @holes[pod][0] && @holes[pod][0] != pod

      move = {from_top: i, to_hole: pod, height: @holes[pod][0] ? 1 : 0}
      moves << move if !obstructed?(move)
    end

    # Move out of starting block

    # Loop over every hole, try moving top, if no top, move bottom
    # Don't move top if in right hole and bottom is same
    # Don't move bottom if in right hole
    @holes.each.with_index do |hole, i|
      if hole[1]
        next if hole[1] == i && hole[0] == i

        7.times do |top|
          next if @tops[top]
          move = {top: top, from_hole: i, height: 1}
          moves << move if !obstructed?(move)
        end
      elsif hole[0]
        next if hole[0] == i

        7.times do |top|
          next if @tops[top]
          move = {top: top, from_hole: i, height: 0}
          moves << move if !obstructed?(move)
        end
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
      raise 'No pod in hole' if !pod

      @holes[hole][hole_height] = nil
      @tops[move[:top]] = pod

      steps = 2 - hole_height # to get out of the hole
      steps += dest_index - start_index + 1

      @energy += steps * POD_COSTS[pod]
    elsif (top = move[:from_top])
      hole_height = move[:height]

      pod = @tops[top]

      @tops[top] = nil
      @holes[move[:to_hole]][hole_height] = pod

      steps = 2 - hole_height
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
      if hole[0] == i
        num += 1
        num += 1 if hole[1] == i
      end
    end
    @progress = num
    num
  end

  def done?
    @holes == [[0, 0], [1, 1], [2, 2], [3, 3]]
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
    puts "####{pod_at_hole(0, 1)}##{pod_at_hole(1, 1)}##{pod_at_hole(2, 1)}##{pod_at_hole(3, 1)}###"
    puts "  ##{pod_at_hole(0, 0)}##{pod_at_hole(1, 0)}##{pod_at_hole(2, 0)}##{pod_at_hole(3, 0)}#"
    puts "  #########"
  end

  def room_hash
    h = ""
    @tops.each {|t| h << (POD_CHARS[t] || '.')}
    @holes.each do |hole|
      h << (POD_CHARS[hole[0]] || '.')
      h << (POD_CHARS[hole[1]] || '.')
    end
    h << @energy.to_s
    h
  end
end

starting_room = Room.new.init(a2, b2, c2, d2, a1, b1, c1, d1)

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

scenarios = [starting_room]
best_energy = 10000000000

current_energy = 0

seen_rooms = Set.new

while scenarios.any?
  room = scenarios.pop
  room_hash = room.room_hash
  next if seen_rooms.include?(room_hash)
  seen_rooms << room_hash

  next if room.energy > best_energy
  next if room.energy > 16059 #best_energy

  # if room.energy > current_energy
  #   puts "Current room"
  #   room.print
  #   current_energy = room.energy + 10
  # end

  possible_moves = room.possible_moves

  #if possible_moves.empty?
  #  puts "No possible moves:"
  #  room.print
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
      puts "best energy = #{best_energy}" if new_room.energy == best_energy
    else
      scenarios << new_room if !seen_rooms.include?(new_room.room_hash)
    end
  end

  scenarios.sort_by!(&:progress)
end

puts "Part 1: #{best_energy}"
