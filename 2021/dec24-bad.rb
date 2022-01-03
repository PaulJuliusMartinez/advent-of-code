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

  {
    op: op.to_sym,
    arg1: arg1.to_sym,
    arg2: arg2,
  }
end

ZERO = {lit: 0}
ONE = {lit: 1}

def simplify(expr)
  return expr if expr[:input]

  if expr[:add]
    args = expr[:add]

    # Flatten nested additions
    args = args.flat_map do |arg|
      arg[:add] ? arg[:add] : [arg]
    end

    # Combine literals
    lits, other = args.partition {|arg| arg[:lit]}
    single_lit = nil

    if !lits.empty?
      single_lit = {lit: lits.map {|arg| arg[:lit]}.sum}
    end

    if single_lit
      args = other + [single_lit]
    else
      args = other
    end

    # Get rid of any 0 literals.
    args.reject! {|arg| arg == ZERO}

    # Don't unnecessarily wrap additions.
    if args.length == 0
      return ZERO
    elsif args.length == 1
      return args[0]
    else
      return {add: args}
    end
  end

  if expr[:mul]
    args = expr[:mul]

    # Flatten nested multiplications
    args = args.flat_map do |arg|
      arg[:mul] ? arg[:mul] : [arg]
    end

    # Combine literals
    lits, other = args.partition {|arg| arg[:lit]}
    single_lit = nil

    if !lits.empty?
      prod = 1
      lits.each {|arg| prod *= arg[:lit]}
      single_lit = {lit: prod}
    end

    if single_lit
      args = other + [single_lit]
    else
      args = other
    end

    # Multiply by zero gives 0
    return ZERO if args.include?(ZERO)

    # Get rid of any 1 literals.
    args.reject! {|arg| arg == ONE}

    # Don't unnecessarily wrap additions.
    if args.length == 0
      return ONE
    elsif args.length == 1
      return args[0]
    else
      return {mul: args}
    end
  end

  if expr[:div]
    arg1, arg2 = expr[:div]
    return ZERO if arg1 == ZERO
    return arg1 if arg2 == ONE

    if arg1[:lit] && arg2[:lit]
      return {lit: (arg1[:lit] / arg2[:lit].to_f).truncate}
    end

    return expr
  end

  if expr[:mod]
    og_arg1, og_arg2 = expr[:mod]
    arg1 = og_arg1
    arg2 = og_arg2

    if (mod = arg2[:lit])
      if (add_args = arg1[:add])
        len = add_args.length
        new_add_args = add_args.reject do |add_arg|
          add_arg[:mul] && add_arg[:mul].any? {|mul_arg| mul_arg[:lit] && mul_arg[:lit] % mod == 0}
        end
        new_add_args = new_add_args.reject do |add_arg|
          add_arg[:lit] && add_arg[:lit] % mod == 0
        end

        if new_add_args.length != len
          # puts "Simplified mod via nested multiply"
          # puts "Before: #{og_arg1.inspect}"
          arg1 = simplify({add: new_add_args})
          # puts "After: #{arg1.inspect}"
        end
      elsif (mul_args = arg1[:mod])
        return ZERO if mul_args.include?({lit: mod})
      end
    end

    if arg1[:lit] && arg2[:lit]
      return {lit: arg1[:lit] % arg2[:lit]}
    end

    if arg1 != og_arg1 || arg2 != og_arg2
      return {mod: [arg1, arg2]}
    end

    return expr
  end

  if expr[:eql]
    arg1, arg2 = expr[:eql]

    # Check literal comparisons with inputs
    if arg1[:input] || arg2[:input]
      if arg1[:input]
        input, comp = [arg1, arg2]
      else
        input, comp = [arg2, arg1]
      end

      if (min = min_value(comp)) && min > 9
        # puts "Simplified eql because min value of expr (#{min}) > 9"
        return ZERO
      end

      if (max = max_value(comp)) && max < 1
        # puts "Simplified eql because max value of expr (#{max}) < 1"
        return ZERO
      end
    end

    return ZERO if arg1[:input] && arg2[:lit] && (arg2[:lit] < 1 || arg2[:lit] > 9)
    return ZERO if arg2[:input] && arg1[:lit] && (arg1[:lit] < 1 || arg1[:lit] > 9)

    return ONE if arg1 == arg2

    if arg1[:eql]
      return arg1 if arg2 == ONE
      return {neq: arg1[:eql]} if arg2 == ZERO
    end

    return expr
  end

  expr
end

def distribute_mul_across_addition(expr)
  mul_args = expr[:mul]
  return expr if !mul_args

  return expr if mul_args.length != 2
  return expr if !mul_args[0][:add]
  return expr if !mul_args[1][:lit]

  adds = mul_args[0][:add]
  lit = mul_args[1]

  distributed = adds.map do |add_arg|
    simplify({mul: [add_arg, lit]})
  end

  simplify({add: distributed})
end

def min_value(expr)
  return 1 if expr[:input]
  return expr[:lit] if expr[:lit]
  return 0 if expr[:eql]
  return 0 if expr[:mod]

  # Give up
  return nil if expr[:div]

  if (args = expr[:add] || expr[:mul])
    mins = args.map {|arg| min_value(arg)}
    return nil if mins.any?(&:nil?)

    return mins.sum if expr[:add]
    prod = 1
    mins.each {|min| prod *= min}
    return prod
  end

  nil
end

def max_value(expr)
  return 9 if expr[:input]
  return expr[:lit] if expr[:lit]
  return 1 if expr[:eql]

  if expr[:mod]
    return expr[:mod][1][:lit] - 1 if expr[:mod][1][:lit]
    return nil
  end

  # Give up
  return nil if expr[:div]

  nil
end

def evaluate_expr(expr, input)
  inputs = {}
  input.chars.each.with_index do |ch, i|
    inputs[i] = ch.to_i
  end

  memoized = {}

  evalute_expr_rec(expr, memoized, inputs)
end

def evalute_expr_rec(expr, memoized, inputs)
  memoized[expr] ||= begin
    if expr[:input]
      inputs[expr[:input]]
    elsif expr[:lit]
      expr[:lit]
    elsif (add_args = expr[:add])
      add_args.map {|add_arg| evalute_expr_rec(add_arg, memoized, inputs)}.sum
    elsif (mul_args = expr[:mul])
      prod = 1
      mul_args.each {|mul_arg| prod *= evalute_expr_rec(mul_arg, memoized, inputs)}
      prod
    elsif (div_args = expr[:div])
      arg1 = evalute_expr_rec(div_args[0], memoized, inputs)
      arg2 = evalute_expr_rec(div_args[1], memoized, inputs)
      (arg1 / arg2.to_f).truncate
    elsif (mod_args = expr[:mod])
      arg1 = evalute_expr_rec(mod_args[0], memoized, inputs)
      arg2 = evalute_expr_rec(mod_args[1], memoized, inputs)
      arg1 % arg2
    elsif (eql_args = expr[:eql])
      arg1 = evalute_expr_rec(eql_args[0], memoized, inputs)
      arg2 = evalute_expr_rec(eql_args[1], memoized, inputs)
      arg1 == arg2 ? 1 : 0
    elsif (neq_args = expr[:neq])
      arg1 = evalute_expr_rec(neq_args[0], memoized, inputs)
      arg2 = evalute_expr_rec(neq_args[1], memoized, inputs)
      arg1 == arg2 ? 0 : 1
    else
      raise "???: #{expr.inspect}"
    end
  end

  if !memoized[expr]
    puts "Got nil for: #{expr}"
  end

  memoized[expr]
end

def symbolic_evaluate(count: 300)
  inputs = 14.times.map {|n| {input: n}}

  state = {
    w: ZERO,
    x: ZERO,
    y: ZERO,
    z: ZERO,
  }

  $instructions[..count].each.with_index do |instr, i|
    # puts JSON.pretty_generate(state)
    # puts "Processing instuction: #{instr.inspect}"

    op, arg1_ref, arg2 = instr.values_at(:op, :arg1, :arg2)
    arg1 = state[arg1_ref]

    if arg2
      if arg2[:ref]
        arg2 = state[arg2[:ref]]
      end
    end

    case op
    when :inp
      state[arg1_ref] = inputs.pop
    when :add
      result = {add: [arg1, arg2]}
      # puts "Simplifying add: #{result}"
      result = simplify(result)
      # puts "Simplified add: #{result}"

      state[arg1_ref] = result
    when :mul
      result = {mul: [arg1, arg2]}
      # puts "Simplifying mul: #{result}"
      result = simplify(result)
      # puts "Simplified mul: #{result}"
      result = distribute_mul_across_addition(result)

      state[arg1_ref] = result
    when :div
      result = {div: [arg1, arg2]}
      # puts "Simplifying div: #{result}"
      result = simplify(result)
      # puts "Simplified div: #{result}"

      state[arg1_ref] = result
    when :mod
      result = {mod: [arg1, arg2]}
      # puts "Simplifying mod: #{result}"
      result = simplify(result)
      # puts "Simplified mod: #{result}"

      state[arg1_ref] = result
    when :eql
      result = {eql: [arg1, arg2]}
      # puts "Simplifying eql: #{result}"
      result = simplify(result)
      # puts "Simplified eql: #{result}"

      state[arg1_ref] = result
    end
  end

  # puts JSON.pretty_generate(state[:z], max_nesting: 300)
  # puts state[:z].to_json(max_nesting: 300)

  state
end

def evaluate(input)
  inputs = input.chars.reverse.map(&:to_i)

  state = {w: 0, x: 0, y: 0, z: 0}

  $instructions.each do |instr|
    op, arg1, arg2 = instr.values_at(:op, :arg1, :arg2)

    if arg2
      if arg2[:ref]
        arg2 = state[arg2[:ref]]
      else
        arg2 = arg2[:lit]
      end
    end

    case op
    when :inp
      state[arg1] = inputs.pop
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
  end

  state[:z]
end

model_number = 99_999_999_999_999

# model_number = 99933178527330
model_number = 66821482720000

final_eval = symbolic_evaluate(count: 300)[:z]

loop do
  if model_number % 100 == 0
    puts "Considering: #{model_number}"
  end

  input = model_number.to_s
  #if input.index('0')
  #  model_number -= 1
  #  next
  #end

  traditional = evaluate(input)
  # symbolic = evaluate_expr(final_eval, input)
  # puts "For input: #{input}"
  # puts "  Traditional: #{traditional}"
  # puts "  Symbolic:    #{symbolic}"
  puts "#{input} -> #{traditional.to_s.rjust(14)}"

  if traditional == 0
    puts model_number
    break
  end

  model_number -= 1
end
