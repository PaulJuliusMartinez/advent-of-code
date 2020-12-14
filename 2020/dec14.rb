#! /usr/bin/env ruby

require './input.rb'
require './util.rb'
require './gb.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

mem = ZHash.new

two_pows = (0..35).map {|n| 2 ** (35-n)}
ALL_BITS = 2**36 - 1

mask = 0
mask_or = 0
strs.each do |str|
  if str.start_with?('mask')
    mask = 0
    mask_or = 0

    ms = str.split(" ")[2]
    ms.chars.each_with_index do |ch, i|
      if ch == '0'
        # nothing
      elsif ch == '1'
        mask_or += 1 << (35-i)
      elsif ch == 'X'
        mask += 1 << (35-i)
      end
    end
  else
    dest = str[4..100].to_i
    val = str.split(" ")[2].to_i
    mask_val = (val & mask) | mask_or

    # puts "val #{val} became #{mask_val}"

    mem[dest] = mask_val
  end
end

puts "Part 1: #{mem.values.sum}"




mem = ZHash.new

o_mask = 0
x_mask = 0

strs.each do |str|
  if str.start_with?('mask')
    o_mask = 0
    x_mask = 0

    ms = str.split(" ")[2]
    ms.chars.each_with_index do |ch, i|
      if ch == '0'
        # nothing
      elsif ch == '1'
        o_mask += 1 << (35-i)
      elsif ch == 'X'
        x_mask += 1 << (35-i)
      end
    end
  else
    dest = str[4..100].to_i
    val = str.split(" ")[2].to_i

    dest |= o_mask
    dest &= (ALL_BITS - x_mask)

    on_bits = two_pows.select do |tp|
      (x_mask & tp) > 0
    end

    # puts on_bits.inspect

    (0..(2 ** (on_bits.count) - 1)).each do |n|
      floating_bits = 0
      (0..(on_bits.count - 1)).each do |i|
        # puts "n: #{n}"
        # puts "i: #{i}"
        # puts "&: #{n & (2 << i)}"
        # puts "2 << i: #{2 << i}"
        if (n & (1 << i)) > 0
          floating_bits += on_bits[i]
        end
      end

      #puts "writing #{val} to #{dest + floating_bits}"
      mem[dest + floating_bits] = val
    end

    # Much cleaner power set implementation
    # on_bits.count.times do |n|
    #   on_bits.combination(n) do |comb|
    #     floating_bits = comb.sum
    #     mem[dest + floating_bits] = val
    #   end
    # end
  end
end

puts "Part 2: #{mem.values.sum}"
