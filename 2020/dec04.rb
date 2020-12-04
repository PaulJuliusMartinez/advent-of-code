#! /usr/bin/env ruby

require './input.rb'

require 'set'
require 'prime'
require 'scanf'

strs = get_input_str_arr(__FILE__)

NEEDED_KEYS = ['byr', 'iyr', 'eyr', 'hgt', 'hcl', 'ecl', 'pid']

def is_valid_part1(seen)
 NEEDED_KEYS.all? {|k| seen.key?(k)}
end

num_valid = 0
seen = {}
strs.each do |str|
  if str == ''
    if is_valid_part1(seen)
      num_valid += 1
    end
    seen = {}
  end

  kvs = str.split(" ")
  kvs.each do |kv|
    k, v = kv.split(":")
    seen[k] = v
  end
end

if is_valid_part1(seen)
  num_valid += 1
end

puts "Part 1: #{num_valid}"

EYE_COLOR = ['amb', 'blu', 'brn', 'gry', 'grn', 'hzl', 'oth']
HAIR_COLOR_RE = /^#[0-9a-f]{6}$/
PID_RE = /^[0-9]{9}$/
HGT_RE = /^[0-9]*(cm|in)$/

def is_valid_part2(seen)
 all_here = NEEDED_KEYS.all? {|k| seen.key?(k)}
 return false if !all_here

 byr = seen['byr'].to_i
 iyr = seen['iyr'].to_i
 eyr = seen['eyr'].to_i

 return false if !HGT_RE.match?(seen['hgt'])
 hgt = seen['hgt'].to_i
 is_cm = seen['hgt'].include?('cm')
 is_in = seen['hgt'].include?('in')

 return false if !HAIR_COLOR_RE.match?(seen['hcl'])
 return false if !EYE_COLOR.include?(seen['ecl'])
 return false if !PID_RE.match?(seen['pid'])

 return (
   (1920 <= byr && byr <= 2002) &&
   (2010 <= iyr && iyr <= 2020) &&
   (2020 <= eyr && eyr <= 2030) &&
   (!is_cm || (150 <= hgt && hgt <= 193)) &&
   (!is_in || (59 <= hgt && hgt <= 76))
  )
end

num_valid = 0
seen = {}
strs.each do |str|
  if str == ''
    if is_valid_part2(seen)
      num_valid += 1
    end
    seen = {}
  end

  kvs = str.split(" ")
  kvs.each do |kv|
    k, v = kv.split(":")
    seen[k] = v
  end
end

num_valid += 1 if is_valid_part2(seen)

puts "Part 2: #{num_valid}"
