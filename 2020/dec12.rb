#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

x = 0
y = 0
dir = [1, 0]

strs.each do |str|
  cmd = str[0]
  val = str[1..10].to_i

  case cmd
  when 'N'
    y += val
  when 'S'
    y -= val
  when 'E'
    x += val
  when 'W'
    x -= val
  when 'L'
    if val == 90
      # 1, 0 => 0, 1
      dir = [-dir[1], dir[0]]
    elsif val == 180
      dir = [-dir[0], -dir[1]]
    elsif val == 270
      dir = [dir[1], -dir[0]]
    end
  when 'R'
    if val == 90
      dir = [dir[1], -dir[0]]
    elsif val == 180
      dir = [-dir[0], -dir[1]]
    elsif val == 270
      dir = [-dir[1], dir[0]]
    end
  when 'F'
    x += dir[0] * val
    y += dir[1] * val
  end

  # puts [x, y].inspect
end

puts "Part 1: #{x.abs + y.abs}"

###################3

sx = 0
sy = 0
wx = 10
wy = 1

strs.each do |str|
  cmd = str[0]
  val = str[1..10].to_i

  case cmd
  when 'N'
    wy += val
  when 'S'
    wy -= val
  when 'E'
    wx += val
  when 'W'
    wx -= val
  when 'L'
    if val == 90
      # 1, 0 => 0, 1
      wx, wy = [-wy, wx]
    elsif val == 180
      wx, wy = [-wx, -wy]
    elsif val == 270
      wx, wy = [wy, -wx]
    end
  when 'R'
    if val == 90
      wx, wy = [wy, -wx]
    elsif val == 180
      wx, wy = [-wx, -wy]
    elsif val == 270
      wx, wy = [-wy, wx]
    end
  when 'F'
    sx += wx * val
    sy += wy * val
  end
  # puts "ship: #{sx}, #{sy}, wp: #{wx}, #{wy}"
end

puts "Part 2: #{sx.abs + sy.abs}"
