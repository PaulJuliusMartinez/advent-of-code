#! /usr/bin/env ruby

strs = DATA.readlines.map(&:strip)
orig_ints = strs[0].split(',').map(&:to_i)

def run_intcode(a, b, ints)
  ints[1] = a
  ints[2] = b

  index = 0
  loop do
    opcode = ints[index]
    break if opcode == 99
    pos1 = ints[index + 1]
    pos2 = ints[index + 2]
    dst = ints[index + 3]

    if opcode == 1
      ints[dst] = ints[pos1] + ints[pos2]
    elsif opcode == 2
      ints[dst] = ints[pos1] * ints[pos2]
    end

    index += 4
  end

  ints[0]
end

# Part 1
puts run_intcode(12, 2, orig_ints.dup)

# Part 2
100.times do |a|
  100.times do |b|
    if run_intcode(a, b, orig_ints.dup) == 19690720
      puts (100 * a) + b
      break
    end
  end
end

__END__
1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,13,1,19,1,6,19,23,2,23,6,27,1,5,27,31,1,10,31,35,2,6,35,39,1,39,13,43,1,43,9,47,2,47,10,51,1,5,51,55,1,55,10,59,2,59,6,63,2,6,63,67,1,5,67,71,2,9,71,75,1,75,6,79,1,6,79,83,2,83,9,87,2,87,13,91,1,10,91,95,1,95,13,99,2,13,99,103,1,103,10,107,2,107,10,111,1,111,9,115,1,115,2,119,1,9,119,0,99,2,0,14,0
