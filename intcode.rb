#! /usr/bin/env ruby

strs = DATA.readlines.map(&:strip)
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
    mode3 = (op / 10000) % 10

    break if opcode == 99

    param1 = arr[ip + 1]
    param2 = arr[ip + 2]
    param3 = arr[ip + 3]

    value1 = value_for_param(arr, param1, mode1)
    value2 = value_for_param(arr, param2, mode2)
    value3 = value_for_param(arr, param3, mode3)

    ip += 1 + OPCODE_TO_NUM_PARAMS[opcode]

    if opcode == 1
      arr[param3] = value1 + value2
    elsif opcode == 2
      arr[param3] = value1 * value2
    elsif opcode == 3
      arr[param1] = inputs.shift
    elsif opcode == 4
      puts "Output: #{value1}"
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
puts "Part 1"
run_intcode(orig_ints.dup, [1])
# Part 2
puts "Part 1"
run_intcode(orig_ints.dup, [5])

__END__
