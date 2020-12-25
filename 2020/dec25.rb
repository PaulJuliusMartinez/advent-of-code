#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

ints = get_multi_line_input_int_arr(__FILE__)

MOD = 20201227

def transform(sn, loop_size)
  val = 1
  loop_size.times do
    val *= sn
    val = val % MOD
  end
  val
end

cpk = ints[0]
dpk = ints[1]

sn = 7
loops = 0
val = 1
while val != cpk
  loops += 1
  val *= sn
  val = val % MOD
end

cls = loops

puts "Part 1: #{transform(dpk, cls)}"

