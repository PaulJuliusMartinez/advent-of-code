#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

str = get_input_str(__FILE__)

cups = str.chars.map(&:to_i)

COUNT = cups.count

100.times do |n|
  # puts cups.join(' ')
  current = cups[0]
  three = cups[1..3]
  rest = cups[4..]
  dest = current - 1

  loop do
    if dest == 0
      dest = COUNT
    end

    dest_index = rest.index(dest)
    if dest_index
      before = rest[0..dest_index]
      after = rest[(dest_index + 1)..]
      cups = before + three + after + [current]
      break
    end
    dest -= 1
  end
end

while cups[0] != 1
  cups << cups.shift
end

puts "Part 1: #{cups[1..].join('')}"


class Cup
  attr_accessor :val, :prev, :next
  def initialize(val)
    @val = val
  end

  def inspect
    "Cup ##{val}, prev: #{prev.val}, next: #{self.next.val}"
  end
end

# BIG_COUNT = 9
BIG_COUNT = 1_000_000

all_cups = Array.new(BIG_COUNT + 1)
cups = str.chars.map(&:to_i)

BIG_COUNT.times do |i|
  all_cups[i + 1] = Cup.new(i + 1)
end

BIG_COUNT.times do |i|
  n = i + 1
  all_cups[n].prev = all_cups[n - 1]
  all_cups[n].next = all_cups[n + 1]
end
all_cups[1].prev = all_cups.last
all_cups.last.next = all_cups[1]

cups.each_with_index do |cup_num, i|
  if i == 0
    # all_cups[cup_num].prev = all_cups[BIG_COUNT]
  else
    all_cups[cup_num].prev = all_cups[cups[i - 1]]
  end

  if i == COUNT - 1
    # See below
  else
    all_cups[cup_num].next = all_cups[cups[i + 1]]
  end
end

if BIG_COUNT == COUNT
  # Hook up last cup to first cup
  all_cups[cups.last].next = all_cups[cups[0]]
  all_cups[cups[0]].prev = all_cups[cups.last]
else
  # Hook up last cup to COUNT + 1
  all_cups[cups.last].next = all_cups[COUNT + 1]
  all_cups[COUNT + 1].prev = all_cups[cups.last]

  # Hook up first_cup to BIG_COUNT cup
  all_cups.last.next = all_cups[cups[0]]
  all_cups[cups[0]].prev = all_cups.last
end

curr = all_cups[cups[0]]
ITER = 10_000_000

def check(cup)
  seen = Set.new
  while !seen.include?(cup.val)
    seen << cup.val
    cup = cup.next
  end
  return seen.count == BIG_COUNT
end

ITER.times do |n|
  dest_num = curr.val - 1

  n1 = curr.next.val
  n2 = curr.next.next.val
  n3 = curr.next.next.next.val

  if dest_num == 0
    dest_num = BIG_COUNT
  end

  while dest_num == n1 || dest_num == n2 || dest_num == n3
    dest_num -= 1
    if dest_num == 0
      dest_num = BIG_COUNT
    end
  end

  first_of_three = curr.next
  last_of_three = curr.next.next.next
  after_three = curr.next.next.next.next

  dest = all_cups[dest_num]

  # Snip out the next three

  curr.next = after_three
  after_three.prev = curr

  # Move three to after dest

  # Connect end of three to dest.next
  last_of_three.next = dest.next
  dest.next.prev = last_of_three

  # Connect dest to start of three
  dest.next = first_of_three
  first_of_three.prev = dest

  curr = curr.next
end

puts "Part 2: #{all_cups[1].next.val * all_cups[1].next.next.val}"
