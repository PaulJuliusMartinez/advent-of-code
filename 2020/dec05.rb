#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

ROWS = [64, 32, 16, 8, 4, 2, 1]
SEATS = [4, 2, 1]

def seat_id(str)
  row = str[0..6]
  seat = str[7..100]

  row_num = row.chars.zip(ROWS).map do |ch, n|
    if ch == 'B'
      n
    else
      0
    end
  end.sum

  seat_num = seat.chars.zip(SEATS).map do |ch, n|
    if ch == 'R'
      n
    else
      0
    end
  end.sum

  (row_num * 8) + seat_num
end

seat_ids = strs.map {|s| seat_id(s)}
puts "Part 1: #{seat_ids.max}"

all_seat_ids = Set.new(seat_ids)
((seat_ids.min)..(seat_ids.max)).each do |n|
  puts "Part 2: #{n}" if !all_seat_ids.include?(n)
end
