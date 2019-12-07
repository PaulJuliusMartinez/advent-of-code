#! /usr/bin/env ruby

# Run ./decXX.rb <test_name> to run code on input in file decXX.<test_name>.
strs =
  if ARGV[0]
    test_filename = File.readlines("#{__FILE__.chomp('rb')}#{ARGV[0]}").map(&:strip)
  else
    DATA.readlines.map(&:strip)
  end
orig_ints = strs[0].split(',').map(&:to_i)

POSITION_MODE = 0
IMMEDIATE_MODE = 1

def value_for_param(arr, param, mode)
  if mode == POSITION_MODE
    arr[param]
  elsif mode == IMMEDIATE_MODE
    param
  end
end

OPCODE_TO_NUM_PARAMS = {
  1 => 3, # Add
  2 => 3, # Multiply
  3 => 1, # Input
  4 => 1, # Output
  5 => 2, # Jump-if-true
  6 => 2, # Jump-if-false
  7 => 3, # Less than
  8 => 3, # Equals
}

def run_intcode(arr, inputs)
  ip = 0
  loop do
    op = arr[ip]

    opcode = op % 100
    mode1 = (op / 100) % 10
    mode2 = (op / 1000) % 10

    break if opcode == 99

    param1 = arr[ip + 1]
    param2 = arr[ip + 2]
    param3 = arr[ip + 3]

    value1 = value_for_param(arr, param1, mode1)
    value2 = value_for_param(arr, param2, mode2)

    ip += 1 + OPCODE_TO_NUM_PARAMS[opcode]

    if opcode == 1
      arr[param3] = value1 + value2
    elsif opcode == 2
      arr[param3] = value1 * value2
    elsif opcode == 3
      arr[param1] = inputs.shift
    elsif opcode == 4
      return value1
    elsif opcode == 5
      ip = value2 if value1 != 0
    elsif opcode == 6
      ip = value2 if value1 == 0
    elsif opcode == 7
      arr[param3] = value1 < value2 ? 1 : 0
    elsif opcode == 8
      arr[param3] = value1 == value2 ? 1 : 0
    end
  end
end

# Part 1
#puts "Part 1"
#run_intcode(orig_ints.dup, [1])

def orders(prefix, rest)
  return [prefix] if rest.empty?
  rest.flat_map do |a|
    orders(prefix + [a], rest - [a])
  end
end

outputs = orders([], [0, 1, 2, 3, 4]).map do |order|
  input = 0
  order.each do |phase|
    input = run_intcode(orig_ints.dup, [phase, input])
  end
  input
end

puts "Part 1"
puts outputs.max

class Intcode
  attr_accessor :next_input
  attr_reader :id

  def initialize(mem, id)
    @ip = 0
    @mem = mem
    @next_input = nil
    @id = id
  end

  def run
    loop do
      op = @mem[@ip]

      opcode = op % 100
      mode1 = (op / 100) % 10
      mode2 = (op / 1000) % 10

      return {state: :done} if opcode == 99

      param1 = @mem[@ip + 1]
      param2 = @mem[@ip + 2]
      param3 = @mem[@ip + 3]

      value1 = value_for_param(@mem, param1, mode1)
      value2 = value_for_param(@mem, param2, mode2)

      @ip += 1 + OPCODE_TO_NUM_PARAMS[opcode]

      if opcode == 1
        @mem[param3] = value1 + value2
      elsif opcode == 2
        @mem[param3] = value1 * value2
      elsif opcode == 3
        return {state: :input, loc: param1}
      elsif opcode == 4
        return {state: :output, value: value1}
      elsif opcode == 5
        @ip = value2 if value1 != 0
      elsif opcode == 6
        @ip = value2 if value1 == 0
      elsif opcode == 7
        @mem[param3] = value1 < value2 ? 1 : 0
      elsif opcode == 8
        @mem[param3] = value1 == value2 ? 1 : 0
      end
    end
  end

  def send_input(result, input)
    @mem[result[:loc]] = input
  end
end

def orders(prefix, rest)
  return [prefix] if rest.empty?
  rest.flat_map do |a|
    orders(prefix + [a], rest - [a])
  end
end

outputs = orders([], [5, 6, 7, 8, 9]).map do |order|
  # puts order.inspect
  cpu1 = Intcode.new(orig_ints.dup, 'A')
  cpu2 = Intcode.new(orig_ints.dup, 'B')
  cpu3 = Intcode.new(orig_ints.dup, 'C')
  cpu4 = Intcode.new(orig_ints.dup, 'D')
  cpu5 = Intcode.new(orig_ints.dup, 'E')

  cpus = [cpu1, cpu2, cpu3, cpu4, cpu5]

  cpus.zip(order).each do |cpu, phase|
    res1 = cpu.run
    # puts "Sent phase to #{cpu.id}"
    cpu.send_input(res1, phase)
  end

  last_output = 0
  last_e_output = nil
  break_all = false

  while !break_all do
    cpus.each do |cpu|
      res = cpu.run
      if res[:state] == :done
        break_all = true
        break
      end

      fail if res[:state] != :input
      # puts "Sending input to #{cpu.id}"
      cpu.send_input(res, last_output)

      res = cpu.run
      fail if res[:state] != :output

      # puts "Got output from #{cpu.id}"
      last_output = res[:value]
      last_e_output = res[:value] if cpu == cpu5
    end
  end

  last_e_output
end

puts "Part 2"
puts outputs.max

__END__
3,8,1001,8,10,8,105,1,0,0,21,30,39,64,81,102,183,264,345,426,99999,3,9,1001,9,2,9,4,9,99,3,9,1002,9,4,9,4,9,99,3,9,1002,9,5,9,101,2,9,9,102,3,9,9,1001,9,2,9,1002,9,2,9,4,9,99,3,9,1002,9,3,9,1001,9,5,9,1002,9,3,9,4,9,99,3,9,102,4,9,9,1001,9,3,9,102,4,9,9,1001,9,5,9,4,9,99,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,99,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,99,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,99
