#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'
require 'json'

strs = get_input_str_arr(__FILE__)

$instructions = strs.map do |str|
  op, arg1, arg2 = str.split(" ")

  if arg2
    if ['w', 'x', 'y', 'z'].include?(arg2)
      arg2 = {ref: arg2.to_sym}
    else
      arg2 = {lit: arg2.to_i}
    end
  end

  inst = {
    op: op.to_sym,
    arg1: arg1.to_sym,
    arg2: arg2,
  }

  inst
end

$instr_groups = []
curr_instr_group = []
$instructions.each do |instr|
  if instr[:op] == :inp
    curr_instr_group = []
    $instr_groups << curr_instr_group
  else
    curr_instr_group << instr
  end
end

# $instr_groups.each do |instrs|
#   div_arg = instrs[3][:arg2][:lit]
#   c1 = instrs[4][:arg2][:lit]
#   c2 = instrs[14][:arg2][:lit]
#   puts "  div_arg: #{div_arg.to_s.rjust(3)}, c1: #{c1.to_s.rjust(3)}, c2: #{c2.to_s.rjust(3)}"
# end
# exit

def evaluate(inputs)
  state = {w: 0, x: 0, y: 0, z: 0}

  $instr_groups.each.with_index do |instrs, i|
    break if !inputs[i]
    state[:w] = inputs[i]

    div_arg = instrs[3][:arg2][:lit]
    c1 = instrs[4][:arg2][:lit]
    c2 = instrs[14][:arg2][:lit]

    # puts "Current z: #{state.inspect}, input: #{state[:w]}"
    # puts "  div_arg: #{div_arg}, c1: #{c1}, c2: #{c2}"


    instrs.each do |instr|
      op, arg1, arg2 = instr.values_at(:op, :arg1, :arg2)

      if arg2
        if arg2[:ref]
          arg2 = state[arg2[:ref]]
        else
          arg2 = arg2[:lit]
        end
      end

      case op
      when :add
        state[arg1] = state[arg1] + arg2
      when :mul
        state[arg1] = state[arg1] * arg2
      when :div
        state[arg1] = (state[arg1] / arg2.to_f).truncate
      when :mod
        state[arg1] = state[arg1] % arg2
      when :eql
        state[arg1] = state[arg1] == arg2 ? 1 : 0
      end

      # puts "  inst: #{instr}"
      # puts "  new_state: #{state.inspect}"
    end

    # puts "Finished: #{state.inspect}"
    # puts
  end

  state
end

correct_inputs = []
$indents = {}

$bad_zs = Hash.new {|h, k| h[k] = Set.new}

def find_input_in_direction(current_inputs, direction:)
  return current_inputs if current_inputs.length == 14

  instrs = $instr_groups[current_inputs.length]
  indent = ($indents[current_inputs.length] ||= " " * current_inputs.length)

  div_arg = instrs[3][:arg2][:lit]
  c1 = instrs[4][:arg2][:lit]
  c2 = instrs[14][:arg2][:lit]

  if div_arg == 1
    max_input = [26 - c2, 9].min #<- Not needed
    min_input = 1

    inputs_to_try = (min_input..max_input).to_a
    inputs_to_try.reverse! if direction == :down

    inputs_to_try.each do |next_input|
      # puts "#{indent} Trying #{current_inputs.inspect} then #{next_input}"
      current_inputs << next_input
      best = find_input_in_direction(current_inputs, direction: direction)

      return best if best
      current_inputs.pop

      # puts "#{indent} Tried #{current_inputs.inspect} then #{next_input}, but it failed"
    end

    # puts "#{indent} Nothing worked for #{current_inputs}. Backtracking"
    return nil
  else
    # print "#{indent} Evaluating #{current_inputs.inspect}... "
    z = evaluate(current_inputs)[:z]
    # puts "ended with z = #{z}"

    next_input = z % 26 + c1
    if next_input < 1 || 9 < next_input
      # puts "#{indent} Next input was out of range: #{next_input}"
      return nil
    else
      if $bad_zs[current_inputs.length].include?(z)
        # puts "Bailed early on bad z"
        return nil
      end

      current_inputs << next_input
      best = find_input_in_direction(current_inputs, direction: direction)

      return best if best
      current_inputs.pop

      $bad_zs[current_inputs.length] << z

      # puts "#{indent} Tried #{current_inputs.inspect} then #{next_input}, but it failed"
      return nil
    end
  end
end

# Technically should pass [], but it's very slow.
puts "Part 1: #{find_input_in_direction([1], direction: :down).join}"
puts "Part 2: #{find_input_in_direction([], direction: :up).join}"

# while correct_inputs.length < 14
# 
#   best_input = (1..9).min_by do |next_input|
#     new_inputs = correct_inputs + [next_input]
#     puts "Feeding in #{new_inputs.inspect}"
#     end_state = evaluate(new_inputs)
# 
#     puts "  ends with z = #{end_state[:z]}"
# 
#     end_state[:z]
#   end
# 
#   puts "Best input was #{best_input}"
#   correct_inputs << best_input
# end





# model_number = 99_999_999_999_999
# BASE = 26
# 
# loop do
#   model_chars = model_number.to_s
#   if (index = model_chars.index('0'))
#     power = 14 - index
#     remainder = model_number % (10.pow(power))
# 
#     # puts "#{model_number} (includes 0), substracting #{remainder + 1}"
#     model_number -= remainder + 1
#     # puts "Now #{model_number}"
#     next
#   end
# 
#   # inputs = model_chars.chars.map(&:to_i).reverse
#   inputs = model_chars.chars.map(&:to_i).rotate(9)
#   # puts inputs.inspect
# 
#   z = evaluate(inputs)[:z]
#   puts "#{model_number.to_s(BASE)} -> #{z.to_s(BASE).rjust(14)} (sum: #{(model_number + z).to_s(BASE).rjust(14)})"
# 
#   model_number -= 1
#   break
# end
