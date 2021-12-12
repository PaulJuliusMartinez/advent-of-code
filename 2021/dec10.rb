#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

MATCHING = {
  '}' => '{',
  ')' => '(',
  ']' => '[',
  '>' => '<',
}

REVERSE_MATCHING = {
  '{' => '}',
  '(' => ')',
  '[' => ']',
  '<' => '>',
}

SCORES = {
  '}' => 1197,
  ')' => 3,
  ']' => 57,
  '>' => 25137,
  nil => 0,
}

SCORES_2 = {
  '}' => 3,
  ')' => 1,
  ']' => 2,
  '>' => 4,
  nil => 0,
}

score = 0
score2s = []

strs.each do |str|
  seen = []

  invalid_ch = nil
  str.chars.each do |ch|
    if ['(', '[', '{', '<'].include?(ch)
      seen << ch
    else
      if seen.pop != MATCHING[ch]
        invalid_ch = ch
        break
      end
    end
  end

  score += SCORES[invalid_ch]

  if !invalid_ch
    s2 = 0
    while seen.any?
      s2 *= 5
      s2 += SCORES_2[REVERSE_MATCHING[seen.pop]]
    end
    score2s << s2
  end
end
score2s.sort!

puts "Part 1: #{score}"
puts "Part 2: #{score2s[score2s.length / 2]}"
