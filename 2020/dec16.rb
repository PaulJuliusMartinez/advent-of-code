#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

rules = {}
grouped_strs[0].each do |str|
  name, ranges = str.split(":")
  ra, rb = ranges.split(" or ").map(&:strip)

  amin, amax = ra.split("-").map(&:to_i)
  bmin, bmax = rb.split("-").map(&:to_i)

  rules[name] = [[amin, amax], [bmin, bmax]]
end

error_rate = 0

valid_tickets = grouped_strs[2][1..1000].select do |tkt|
  nums = tkt.split(",").map(&:to_i)

  tkt_bad = false
  nums.each do |num|
    none_valid = rules.values.all? do |ra, rb|
      num < ra[0] || rb[1] < num || (ra[1] < num && num < rb[0])
    end

    # Alternatively:
    # potentially_valid = rules.values.any? do |ra, rb|
    #   num < ra[0] || rb[1] < num || (ra[1] < num && num < rb[0])
    # end

    if none_valid # if !potentially_valid
      error_rate += num
      tkt_bad = true
    end
  end

  !tkt_bad
end

puts "Part 1: #{error_rate}"

valid_tickets << grouped_strs[1][1]
valid_tickets.map! {|tkt| tkt.split(",").map(&:to_i)}

def find_possible_index(field_name, tickets, rules)
  ra, rb = rules[field_name]

  tickets[0].length.times.select do |i|
    vals = tickets.map {|tkt| tkt[i]}

    vals.all? do |num|
      (ra[0] <= num && num <= ra[1]) || (rb[0] <= num && num <= rb[1])
    end
  end
end

valid_rules_at_indexes = Hash.new {|h, k| h[k] = Set.new}

rules.keys.each do |field|
  find_possible_index(field, valid_tickets, rules).each do |i|
    valid_rules_at_indexes[i] << field
  end
end

# puts valid_rules_at_indexes.inspect
index_potential_rules = valid_rules_at_indexes.map.sort_by {|k, v| v.length}
# puts index_potential_rules[0..3].inspect

my_ticket = grouped_strs[1][1].split(",").map(&:to_i)

DEPART_RULES = [
  "departure location",
  "departure station",
  "departure platform",
  "departure track",
  "departure date",
  "departure time",
]

prod = 1

index_potential_rules.each.with_index do |(index, rules), i|
  if rules.count == 1
    rule = rules.to_a[0]

    if DEPART_RULES.include?(rule)
      prod *= my_ticket[index]
    end

    index_potential_rules[(i + 1)..30].each do |_, rules_set|
      rules_set.delete(rule)
    end
  else
    puts "Too many choices for index #{index}"
  end
end

puts "Part 2: #{prod}"
