#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

ops = strs.map do |str|
  opp, arg = str.split(" ")
  arg = arg.to_i
  [opp, arg]
end

def run(ops, part:)
  acc = 0
  next_inst = 0
  seen_instructions = Set.new

  loop do
    break if seen_instructions.include?(next_inst)
    break if next_inst == ops.count

    op, arg = ops[next_inst]

    seen_instructions << next_inst

    case op
    when 'acc'
      acc += arg
      next_inst += 1
    when 'jmp'
      next_inst += arg
    when 'nop'
      next_inst += 1
    end
  end

  if part == 1
    acc
  else
    next_inst == ops.count ? acc : nil
  end
end

puts "Part 1: #{run(ops, part: 1)}"

ops.count.times do |i|
  new_ops = ops.dup
  ch_op, ch_arg = ops[i]
  next if ch_op == 'acc'

  if ch_op == 'jmp'
    new_ops[i] = ['nop', ch_arg]
  else
    new_ops[i] = ['jmp', ch_arg]
  end

  val = run(new_ops, part: 2)
  if val
    puts "Part 2: #{val}"
    break
  end
end

