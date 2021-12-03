#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

index_counts = ZHash.new

strs.each do |str|
  str.chars.each.with_index do |ch, i|
    index_counts[i] += 1 if ch == '1'
  end
end

total_num = strs.count

more = ""
less = ""

strs[0].length.times do |index|
  count = index_counts[index]
  if count > total_num - count
    more += "1"
    less += "0"
  else
    more += "0"
    less += "1"
  end
end

# puts more
# puts less

def to_n(binary)
  total = 0
  size = 1
  binary.reverse.chars.each do |ch|
    total += size if ch == '1'
    size *= 2
  end

  total
end

puts "Part 1: #{to_n(more) * to_n(less)}"



# toggle == true  => oxygen generator (most  common, tied => 1)
# toggle == false => CO2 scrubber     (least common, tied => 0)
def filter_nums(nums, toggle, index=0)
  return nums[0] if nums.length == 1

  num1 = nums.count {|s| s[index] == '1'}
  num0 = nums.count - num1

  if num1 == num0
    bit = toggle ? "1" : "0"
  else
    if toggle
      bit = num1 > num0 ? "1" : "0"
    else
      bit = num1 > num0 ? "0" : "1"
    end
  end

  # Can get rid of num1 == num0 case by using >=
  # if toggle
  #   bit = num1 >= num0 ? "1" : "0"
  # else
  #   bit = num1 >= num0 ? "0" : "1"
  # end

  nums = nums.filter {|s| s[index] == bit}

  filter_nums(nums, toggle, index + 1)
end

puts "Part 2: #{to_n(filter_nums(strs, true)) * to_n(filter_nums(strs, false))}"
