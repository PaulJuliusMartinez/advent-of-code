#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

ints = get_multi_line_input_int_arr(__FILE__)

MOD = 20201227

cpk = ints[0]
dpk = ints[1]

csn = 7

val1 = 1
val2 = 1
while val1 != cpk
  val1 *= csn
  val1 = val1 % MOD

  val2 *= dpk
  val2 = val2 % MOD
end

puts "Part 1: #{val2}"

