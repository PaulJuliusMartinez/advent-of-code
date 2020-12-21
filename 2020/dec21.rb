#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

$allergens_to_foods = Hash.new {|h, k| h[k] = []}
$all_ing = Set.new
$foods = []

strs.each do |str|
  str = str[0..-2]
  ing, allergen = str.split("(contains ")
  ings = ing.split(" ").map(&:strip)
  allergens = allergen.split(", ").map(&:strip)

  # puts ings.inspect
  # puts allergens.inspect

  food = Set.new(ings)
  $foods << food

  allergens.each do |alleg|
    $allergens_to_foods[alleg] << food
  end

  ings.each do |ing|
    $all_ing << ing
  end
end

allergen_to_possible_ing = {}

$allergens_to_foods.each do |allergen, foods|
  s = foods[0]
  foods[1..].each do |food|
    s = s & food
  end

  allergen_to_possible_ing[allergen] = s
end

possible_allergen_ing_array = allergen_to_possible_ing.values
maybe_allergens = possible_allergen_ing_array[0]
possible_allergen_ing_array.each do |ing_set|
  maybe_allergens = maybe_allergens | ing_set
end

not_allergen_ings = $all_ing - maybe_allergens

count = 0
$foods.each do |food|
  food.to_a.each do |ing|
    if not_allergen_ings.include?(ing)
      count += 1
    end
  end
end

puts "Part 1: #{count}"

# Aray of [allergen, ingredient_for_allergen]
allergen_ing = []

# Array of [allergen, possible_ingredients_for_allergen] pairs
remaining_allergens = allergen_to_possible_ing.map {|k, v| [k, v]}

while remaining_allergens.any?
  remaining_allergens.sort_by! {|(ing, allergens)| allergens.count}

  ing, allergens = remaining_allergens.shift
  allergen = allergens.to_a[0]
  allergen_ing << [ing, allergen]

  remaining_allergens.each do |(_, allergens)|
    allergens.delete(allergen)
  end
end

puts "Part 2: #{allergen_ing.sort_by {|allergen, _| allergen}.map(&:last).join(",")}"
