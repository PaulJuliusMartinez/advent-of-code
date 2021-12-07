#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

numbers = grouped_strs[0][0].split(",").map(&:to_i)
boards = grouped_strs[1..-1]

class Board
  def initialize(rows)
    @squares = rows.map {|r| r.split.map(&:to_i)}.flatten
    @placed = 25.times.map {false}
  end

  DIAG1 = [0, 6, 12, 18, 24]
  DIAG2 = [4, 8, 12, 16, 20]

  def place(n)
    index = @squares.index(n)
    return if !index
    @placed[index] = true
  end

  def bingo?
    5.times do |n|
      row = 5.times.map {|d| (5 * n) + d}
      col = 5.times.map {|d| (5 * d) + n}

      return true if row.all? {|i| @placed[i]}
      return true if col.all? {|i| @placed[i]}
    end

    # return true if DIAG1.all? {|i| @placed[i]}
    # return true if DIAG2.all? {|i| @placed[i]}

    false
  end

  def score
    @squares.zip(@placed).map {|n, marked| marked ? 0 : n}.sum
  end
end

boards = boards.map {|rows| Board.new(rows)}

found_part1 = false

numbers.each do |num|
  boards.each {|b| b.place(num)}

  if (winner = boards.find(&:bingo?))
    puts "Part 1: #{winner.score * num}" if !found_part1
    found_part1 = true

    boards = boards.reject(&:bingo?)
    if boards.empty?
      puts "Part 2: #{winner.score * num}"
      break
    end
  end
end

