#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

def determine_mapping(inputs)
  one = inputs.find {|i| i.length == 2}.chars
  four = inputs.find {|i| i.length == 4}.chars
  seven = inputs.find {|i| i.length == 3}.chars
  eight = inputs.find {|i| i.length == 7}.chars

  two_three_five = inputs.select {|i| i.length == 5}
  zero_six_nine = inputs.select {|i| i.length == 6}
  # 2 => 5
  # 3 => 5
  # 5 => 5

  # 0 => 6
  # 6 => 6
  # 9 => 6

  top = (seven - one)[0]
  tl_mid = (four - one)

  mid_bottom = (two_three_five[0].chars & two_three_five[1].chars & two_three_five[2].chars) - [top]

  mid = (tl_mid & mid_bottom)[0]
  tl = (tl_mid - [mid])[0]
  bottom = (mid_bottom - [mid])[0]

  # tr
  # bl
  # br

  six = zero_six_nine.find {|i| (i.chars - seven).length == 4}.chars
  bottoms = (six - [top, mid, bottom, tl])

  br = (bottoms & one)[0]
  bl = (bottoms - one)[0]

  tr = (eight - [top, mid, bottom, tl, br, bl])[0]

  mapping = {
    top: top,
    mid: mid,
    bottom: bottom,
    tl: tl,
    tr: tr,
    bl: bl,
    br: br,
  }

  # puts mapping.inspect

  mapping
end

def decode(mapping, inputs)
  sum = 0
  digit = 1

  values = {
    0 => [:top, :tl, :tr, :bl, :br, :bottom],
    1 => [:tr, :br],
    2 => [:top, :tr, :mid, :bl, :bottom],
    3 => [:top, :tr, :mid, :br, :bottom],
    4 => [:tl, :tr, :mid, :br],
    5 => [:top, :tl, :mid, :br, :bottom],
    6 => [:top, :tl, :mid, :bl, :br, :bottom],
    7 => [:top, :tr, :br],
    8 => [:top, :tl, :tr, :mid, :bl, :br, :bottom],
    9 => [:top, :tl, :tr, :mid, :br, :bottom],
  }

  lookup = values.map do |value, keys|
    [keys.map {|k| mapping[k]}.sort.join, value]
  end.to_h

  inputs.reverse.each do |input|
    sum += lookup[input.chars.sort.join] * digit
    # puts lookup[input.chars.sort.join]
    digit *= 10
  end
  # puts '**'

  sum
end

c = 0
sum = 0
strs.each do |str|
  before, after = str.split("|")
  before_inputs = before.split(" ").map(&:strip)
  after_inputs = after.split(" ").map(&:strip)

  c += after_inputs.select {|s| [2, 3, 7, 4].include?(s.length)}.count

  mapping = determine_mapping(before_inputs)
  # puts decode(mapping, after_inputs)
  sum += decode(mapping, after_inputs)
end

puts "Part 1: #{c}"
puts "Part 2: #{sum}"
