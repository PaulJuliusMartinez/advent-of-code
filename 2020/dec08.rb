#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

insts = GB.parse_instructions(strs)

gb1 = GB.new(insts)
gb1.run
puts "Part 1: #{gb1.acc}"

insts.count.times do |i|
  new_ops = insts.dup
  ch_op, arg = insts[i]
  next if ch_op == GB::ACC

  if ch_op == GB::JMP
    new_ops[i] = [GB::NOP, arg]
  else
    new_ops[i] = [GB::JMP, arg]
  end

  gb = GB.new(new_ops)
  gb.run

  if gb.done?
    puts "Part 2: #{gb.acc}"
    break
  end
end

