#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

# Example
space1 = 3
space2 = 7
spaces = [3, 7]

space1 = strs[0].split(": ")[1].to_i - 1
space2 = strs[1].split(": ")[1].to_i - 1
spaces = [space1, space2]

scores = [0, 0]
die = 1
dice_rolls = 0

while scores.all? {|n| n < 1000}
  2.times do |n|
    dice_rolls += 3

    moves = 0
    3.times do
      moves += die
      die += 1
      die = 1 if die > 100
    end

    spaces[n] = (spaces[n] + moves) % 10
    scores[n] += spaces[n] + 1

    break if scores[n] >= 1000
  end
end

puts "Part 1: #{scores.min * dice_rolls}"

games_in_state = ZHash.new
initial_game_state = [0, 0, space1, space2, 0]
games_in_state[initial_game_state] = 1

states_to_consider = [initial_game_state]

WAYS_TO_ROLL_N = {
  3 => 1, # 111
  4 => 3, # 112 121 211
  5 => 6, # 113 131 311 122 212 221
  6 => 7, # 27 - 6 - 6 - 3 - 3 - 1 - 1
  7 => 6,
  8 => 3,
  9 => 1,
}

win_count = [0, 0]

while states_to_consider.any?
  # puts "Total active games: #{games_in_state.values.sum}"
  state = states_to_consider.shift

  score1, score2, space1, space2, turn = state
  num_games_in_state = games_in_state[state]
  games_in_state[state] = 0

  # puts "Considering state: #{state.inspect} (#{num_games_in_state} current games in state)"
  next if num_games_in_state == 0

  scores = [score1, score2]
  spaces = [space1, space2]
  next_turn = 1 - turn

  WAYS_TO_ROLL_N.each do |moves, num_ways|
    new_space = (spaces[turn] + moves) % 10
    new_score = scores[turn] + new_space + 1

    new_state = [scores[0], scores[1], spaces[0], spaces[1], next_turn]
    new_state[turn] = new_score
    new_state[2 + turn] = new_space

    if new_score >= 21
      win_count[turn] += num_ways * num_games_in_state
      # puts "  Winning state: #{new_state.inspect} (Adding #{num_ways * num_games_in_state} games)"
    else
      # puts "  New state: #{new_state.inspect} (Adding #{num_ways * num_games_in_state} games)"
      games_in_state[new_state] += num_ways * num_games_in_state
      states_to_consider << new_state
    end
  end
end

# games_in_state.each do |state, num_games|
#   puts " State: #{state.inspect} (#{num_games} current games in state)"
# end

puts "Part 2: #{win_count.max}"
