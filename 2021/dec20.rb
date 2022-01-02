#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

$alg = grouped_strs[0][0].gsub('#', '1').gsub('.', '0')
input_image = grouped_strs[1]

input_image = input_image.map do |str|
  str.gsub('#', '1').gsub('.', '0')
end

image_map = {}

input_image.each.with_index do |row, y|
  row.chars.each.with_index do |ch, x|
    image_map[[x, y]] = ch if ch == '1'
  end
end

def iterate(image, outside)
  keys = image.keys
  xmin, xmax = keys.map(&:first).minmax
  ymin, ymax = keys.map(&:last).minmax

  xmin -= 1
  ymin -= 1
  xmax += 1
  ymax += 1

  # puts "#{xmin}..#{xmax}, #{ymin}..#{ymax}"

  # (ymin..ymax).each do |y|
  #   (xmin..xmax).each do |x|
  #     print (image[[x, y]] == '1' ? '#' : '.')
  #   end
  #   puts
  # end
  # puts "*************************"

  new_image = {}

  (xmin..xmax).each do |x|
    (ymin..ymax).each do |y|
      index_str =
        [-1, 0, 1].map do |dy|
          [-1, 0, 1].map do |dx|
            image[[x + dx, y + dy]] || outside
          end.join
        end.join

      # puts "Index at (#{x}, #{y}): #{index_str} (#{index_str.to_i(2)})"

      index = index_str.to_i(2)

      new_image[[x, y]] = $alg[index]
    end
  end

  outside_index = ([outside] * 9).join.to_i(2)
  new_outside = $alg[outside_index]
  # puts "new_outside: #{new_outside}"

  [new_image, new_outside]
end

outside = '0'
second, outside = iterate(image_map, outside)
third, outside = iterate(second, outside)

puts "Part 1: #{third.values.count {|p| p == '1'}}"

48.times do
  third, outside = iterate(third, outside)
end

puts "Part 2: #{third.values.count {|p| p == '1'}}"
