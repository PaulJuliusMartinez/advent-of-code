#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

deck1 = grouped_strs[0][1..].map(&:to_i)
deck2 = grouped_strs[1][1..].map(&:to_i)

d1 = deck1.dup
d2 = deck2.dup

while !deck1.empty? && !deck2.empty?
  c1 = deck1.shift
  c2 = deck2.shift

  if c1 > c2
    deck1 << c1
    deck1 << c2
  else
    deck2 << c2
    deck2 << c1
  end
end

deck1.reverse!
deck2.reverse!

sum = 0
(deck1 + deck2).each_with_index do |card, i|
  sum += card * (i + 1)
end

puts "Part 1: #{sum}"



def play_recursive(deck1, deck2)
  seen = Set.new
  loop do
    return 2 if deck1.empty?
    return 1 if deck2.empty?

    if seen.include?([deck1, deck2])
      return 1
    end

    seen << [deck1.dup, deck2.dup]

    c1 = deck1.shift
    c2 = deck2.shift

    if c1 <= deck1.count && c2 <= deck2.count
      new_deck1 = deck1[0..(c1 - 1)]
      new_deck2 = deck2[0..(c2 - 1)]
      winner = play_recursive(new_deck1, new_deck2)
    else
      if c1 > c2
        winner = 1
      else
        winner = 2
      end
    end

    if winner == 1
      deck1 << c1
      deck1 << c2
    else
      deck2 << c2
      deck2 << c1
    end
  end
end

play_recursive(d1, d2)

d1.reverse!
d2.reverse!

sum = 0
(d1 + d2).each_with_index do |card, i|
  sum += card * (i + 1)
end

puts "Part 2: #{sum}"
