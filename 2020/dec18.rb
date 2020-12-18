#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

def evaluate_str(str)
  str = str.strip

  if !str.index('(')
    vals = str.split(" ")
    result = vals[0].to_i
    i = 1
    while i < vals.length
      op = vals[i]
      next_val = vals[i + 1].to_i

      if op == '*'
        result = result * next_val
      elsif op == '+'
        result = result + next_val
      end

      i += 2
    end

    result
  else

    evaluate_str(simplify_str(str) {|s| evaluate_str(s)})
  end
end


$count = 0

def simplify_str(str)
  last_lparen = 0
  i = 0
  while i < str.length
    if str[i] == '('
      last_lparen = i
    elsif str[i] == ')'
      break
    end

    i += 1
  end

  before = last_lparen == 0 ? "" : str[0..(last_lparen - 1)]
  parenthesized = str[(last_lparen + 1)..(i - 1)]
  after = str[(i + 1)..1000]


  # puts "Before: #{str}"
  # puts "Before: #{before}"
  # puts "Paren: #{parenthesized}"
  # puts "After: #{after}"

  # exit if $count == 10
  $count += 1

  simplified = "#{before}#{yield parenthesized}#{after}"

  # puts "Simplified: #{simplified}"

  simplified
end

sum = 0

strs.each do |str|
  sum += evaluate_str(str)
end

puts "Part 1: #{sum}"

def eval_flipped(str)
  str = str.strip

  if !str.index('(')
    product = 1
    additions = str.split(" * ")
    additions.each do |add_str|
      product *= add_str.split(" + ").map(&:to_i).sum
    end

    product
  else
    eval_flipped(simplify_str(str) {|s| eval_flipped(s)})
  end
end

sum = 0

strs.each do |str|
  sum += eval_flipped(str)
end

puts "Part 2: #{sum}"
