#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)


$rules = {}

grouped_strs[0].each do |rule|
  rule_num, rest = rule.split(": ", 2)
  rule_num = rule_num.to_i

  if rest.include?('"')
    $rules[rule_num] = [[rest[1]]]
  else
    one_of_parts = rest.split(" | ")
    $rules[rule_num] = one_of_parts.map do |part|
      part.split(" ").map(&:to_i)
    end
  end
end

# $rules[8] = [[42], [42, 8]]
# $rules[11] = [[42, 31], [42, 11, 31]]

# Below code tries to "simplify" the rule map, but it doesn't help much.

# terminal_rules = $rules
#   .select {|k, v| v[0][0].is_a?(String)}
#   .map {|k, _| k}
#
# terminal_rules = [terminal_rules[0]]
#
# while !terminal_rules.empty?
#   term = terminal_rules.pop
#   # puts "term: #{term}, val: #{$rules[term].inspect}"
#   val = $rules[term][0][0]
#   $rules.delete(term)
#
#   $rules.keys.each do |key|
#     if !$rules[key].any? {|arr| arr.include?(term)}
#       next
#     end
#
#     $rules[key].each_with_index do |expansion, i|
#       # puts "expansion: #{expansion.inspect}"
#       # puts "term: #{term}"
#       while ind = expansion.index(term)
#         expansion[ind] = val
#         # puts "replacing #{term} in $rules[#{key}] with #{val}, now #{expansion.inspect}"
#       end
#
#       if expansion.all? {|x| x.is_a?(String)}
#         $rules[key][i] = [expansion.join("")]
#       end
#     end
#
#     if $rules[key].length == 1 && $rules[key][0].length == 1 && $rules[key][0][0].is_a?(String)
#       # puts "key #{key} is a terminal, $rules[key] == #{$rules[key].inspect}"
#       terminal_rules << key
#     end
#   end
# end
#
# puts $rules.inspect


# $cache = {}

def squish(pattern)
  res = []

  pattern.each do |part|
    if res.last.is_a?(String) && part.is_a?(String)
      res[-1] = res[-1] + part
    else
      res << part
    end
  end

  res
end

$messages = Set.new(grouped_strs[1])
$num_found = 0

$longest_message = $messages.to_a.map(&:length).max

$prefixes = Set.new
grouped_strs[1].each do |str|
  str.length.times do |i|
    $prefixes << str[0..i]
  end
end

def expand(pattern)
  pattern = squish(pattern)

  # This isn't needed because we check prefixes.
  # But it would be needed the rules were left recursive? (Maybe?)
  #
  # potential_length = 0
  # pattern.each do |part|
  #   if part.is_a?(String)
  #     potential_length += part.length
  #   else
  #     potential_length += 1
  #   end
  # end

  # if potential_length > $longest_message
  #   return []
  # end

  if pattern[0].is_a?(String)
    if !$prefixes.include?(pattern[0])
    # if !$messages.any? {|str| str.start_with?(pattern[0])}
      return []
    end
  end

  # if $cache.key?(pattern)
  #   return $cache[pattern]
  # end
  # pattern is [3, 6, "a", 8]
  # puts "expand(#{pattern.inspect})"

  i = 0
  while i < pattern.length && !pattern[i].is_a?(Integer)
    i += 1
  end

  if i == pattern.length
    ret =  [pattern.join("")]
    # puts "Returning #{ret.inspect}"
    # $cache[pattern] = ret

    if $messages.include?(ret[0])
      $num_found += 1
      # puts "found #{ret[0]} in messages (#{$num_found}th)"
      # $messages.delete(ret[0])
    end

    return ret
  end

  # i is index of first non-terminal
  before = i == 0 ? [] : pattern[0..(i - 1)]
  after = pattern[(i + 1)..]

  all = []
  $rules[pattern[i]].each do |expanded|
    # puts "expanding #{pattern[i]} to #{expanded}"
    all.concat(squish(expand(before + expanded + after)))
  end

  # $cache[pattern] = all

  all
end

expand([0])

puts "Part 1: #{$num_found}"

$rules[8] = [[42], [42, 8]]
$rules[11] = [[42, 31], [42, 11, 31]]

$num_found = 0
# $cache = {}
expand([0])

puts "Part 2: #{$num_found}"
