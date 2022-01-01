#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'
require 'json'

strs = get_input_str_arr(__FILE__)

def parse_sf_num(str)
  last_popped = nil
  stack = []

  while !str.empty?
    if str[0] == '['
      str = str[1..]
      # puts "pushed, remaining: #{str}"

      stack << {left: nil, right: nil}
    elsif str[0] == ']'
      str = str[1..]
      # puts "popped, remaining: #{str}"

      last_popped = stack.pop
      if (parent = stack.last)
        if !parent[:left]
          parent[:left] = last_popped
          # puts 'set parent left after pop'
        elsif !parent[:right]
          parent[:right] = last_popped
          # puts 'set parent right after pop'
        end
      end
    elsif str[0] == ','
      str = str[1..]
      # puts "skipped comma, remaining: #{str}"
    else
      val = str.to_i
      str = str[val.to_s.length..]
      # puts "got #{val}, remaining: #{str}"

      if (parent = stack.last)
        if !parent[:left]
          parent[:left] = val
          # puts 'set parent left after literal'
        elsif !parent[:right]
          parent[:right] = val
          # puts 'set parent right after literal'
        end
      end
    end
  end

  return last_popped
end

def sf_num_to_s(sf_num)
  sf_num_to_s_rec(sf_num, "")
end

def sf_num_to_s_rec(sf_num, s)
  if sf_num.is_a?(Hash)
    s << "["
    sf_num_to_s_rec(sf_num[:left], s)
    s << ","
    sf_num_to_s_rec(sf_num[:right], s)
    s << "]"
  else
    s << sf_num.to_s
  end
end

def sf_add(left, right)
  reduce({left: left, right: right})
end

def reduce(sf_num)
  # nested inside 4 pairs => leftmost explodes
  # n >= 1 => leftmost regular number splits
  loop do
    path_to_nested4 = find_nested4(sf_num, 0, [])
    if path_to_nested4
      sf_num = explode(sf_num, path_to_nested4)
      # puts "exploded, now: #{sf_num_to_s(sf_num)}"
      next
    end

    path_to_g10 = find_g10(sf_num, [])
    if path_to_g10
      sf_num = split(sf_num, path_to_g10)
      # puts "split, now: #{sf_num_to_s(sf_num)}"
      next
    end

    break
  end

  sf_num
end

def find_nested4(sf_num, depth, path)
  return nil if !sf_num.is_a?(Hash)
  return path if depth == 4

  #if sf_num[:left].is_a?(Hash)
    found = find_nested4(sf_num[:left], depth + 1, path + [:left])
    return found if found
  #end

  #if sf_num[:right].is_a?(Hash)
    found = find_nested4(sf_num[:right], depth + 1, path + [:right])
    return found if found
  #end
end

def find_g10(sf_num, path)
  if !sf_num.is_a?(Hash)
    return path if sf_num >= 10
    return nil
  end

  found = find_g10(sf_num[:left], path + [:left])
  return found if found

  found = find_g10(sf_num[:right], path + [:right])
  return found if found
end

def explode(sf_num, path_to_nested4)
  path_to_left = find_first_regular_number_to_left(sf_num, path_to_nested4)
  path_to_right = find_first_regular_number_to_right(sf_num, path_to_nested4)

  left, right = lookup(sf_num, path_to_nested4).values_at(:left, :right)

  # puts "nested4 = #{left.inspect}, #{right.inspect}"
  # puts "left path/val: #{path_to_left.inspect}, #{lookup(sf_num, path_to_left)}" if path_to_left
  # puts "right path/val: #{path_to_right.inspect}, #{lookup(sf_num, path_to_right)}" if path_to_right

  #[
  #  [path_to_left, left],
  #  [path_to_right, right],
  #].each do |path, val|
  #  next if !path

  #  sf_set(sf_num, path, lookup(sf_num, path) + val)
  #end

  # Same as above, but actually simpler
  sf_set(sf_num, path_to_left, lookup(sf_num, path_to_left) + left) if path_to_left
  sf_set(sf_num, path_to_right, lookup(sf_num, path_to_right) + right) if path_to_right

  sf_set(sf_num, path_to_nested4, 0)

  sf_num
end

def split(sf_num, path_to_g10)
  half = lookup(sf_num, path_to_g10) / 2.0
  sf_set(sf_num, path_to_g10, {left: half.floor.to_i, right: half.ceil.to_i})

  sf_num
end

def lookup(sf_num, path)
  path.each do |side|
    sf_num = sf_num[side]
  end

  sf_num
end

def sf_set(sf_num, path, val)
  node = sf_num
  path[..-2].each do |side|
    node = node[side]
  end
  node[path.last] = val
end

def find_first_regular_number_to_left(sf_num, path)
  if (last_right_index = path.rindex(:right))
    new_path = path[0..last_right_index]
    new_path[last_right_index] = :left

    new_node = lookup(sf_num, new_path)
    while new_node.is_a?(Hash)
      new_path << :right
      new_node = new_node[:right]
    end

    new_path
  end
end

def find_first_regular_number_to_right(sf_num, path)
  if (last_left_index = path.rindex(:left))
    new_path = path[0..last_left_index]
    new_path[last_left_index] = :right

    new_node = lookup(sf_num, new_path)
    while new_node.is_a?(Hash)
      new_path << :left
      new_node = new_node[:left]
    end

    new_path
  end
end

tests = [
  "[[[[[9,8],1],2],3],4]",
  "[7,[6,[5,[4,[3,2]]]]]",
  "[[6,[5,[4,[3,2]]]],1]",
  "[[3,[2,[1,[7,3]]]],[6,[5,[4,[3,2]]]]]",
  "[[3,[2,[8,0]]],[9,[5,[4,[3,2]]]]]",
]

# tests.each do |test|
#   sf_num = parse_sf_num(test)
# 
#   puts "TEST: #{test}"
#   nested4 = find_nested4(sf_num, 0, [])
#   # puts "  NESTED 4 Path: #{nested4.inspect}"
#   reg_to_left = find_first_regular_number_to_left(sf_num, nested4)
#   # if reg_to_left
#   #   puts "  Left Path: #{reg_to_left.inspect} (#{lookup(sf_num, reg_to_left)})"
#   # else
#   #   puts "  Left Path: nil"
#   # end
# 
#   reg_to_right = find_first_regular_number_to_right(sf_num, nested4)
#   # if reg_to_right
#   #   puts "  Right Path: #{reg_to_right.inspect} (#{lookup(sf_num, reg_to_right)})"
#   # else
#   #   puts "  Right Path: nil"
#   # end
# 
#   puts sf_num_to_s(explode(sf_num, nested4))
# end

# sf_add(parse_sf_num("[[[[4,3],4],4],[7,[[8,4],9]]]"), parse_sf_num("[1,1]"))


def sf_dup(sf_num)
  return sf_num if !sf_num.is_a?(Hash)
  {left: sf_dup(sf_num[:left]), right: sf_dup(sf_num[:right])}
end

def magnitude(sf_num)
  if sf_num.is_a?(Hash)
    3 * magnitude(sf_num[:left]) + 2 * magnitude(sf_num[:right])
  else
    sf_num
  end
end

sf_nums = strs.map do |str|
  parse_sf_num(str)
end

total = sf_dup(sf_nums[0])
rest = sf_nums[1..]

rest.each do |val|
  total = sf_add(total, sf_dup(val))
end

puts "Part 1: #{magnitude(total)}"

max_mag = 0
sf_nums.each do |left|
  sf_nums.each do |right|
    next if left == right
    max_mag = [max_mag, magnitude(sf_add(sf_dup(left), sf_dup(right)))].max
  end
end

puts "Part 2: #{max_mag}"
