#! /usr/bin/env ruby

require './intcode.rb'
require './input.rb'

orig_ints = get_single_line_input_int_arr(__FILE__)

outputs = [0, 1, 2, 3, 4].permutation.map do |order|
  input = 0
  order.each do |phase|
    output = Intcode.new(orig_ints).run([phase, input])
    input = output[:value]
  end
  input
end

puts "Part 1"
puts outputs.max

outputs = [5, 6, 7, 8, 9].permutation.map do |order|
  cpu1 = Intcode.new(orig_ints, 'A')
  cpu2 = Intcode.new(orig_ints, 'B')
  cpu3 = Intcode.new(orig_ints, 'C')
  cpu4 = Intcode.new(orig_ints, 'D')
  cpu5 = Intcode.new(orig_ints, 'E')

  cpus = [cpu1, cpu2, cpu3, cpu4, cpu5]

  cpus.zip(order).each do |cpu, phase|
    cpu.run([phase])
  end

  last_output = 0
  last_e_output = nil
  break_all = false

  while !break_all do
    cpus.each do |cpu|
      state = cpu.run([last_output])

      if state[:state] == Intcode::DONE
        break_all = true
        break
      end

      last_output = state[:value]
      last_e_output = state[:value] if cpu == cpu5
    end
  end

  last_e_output
end

puts "Part 2"
puts outputs.max

__END__
3,8,1001,8,10,8,105,1,0,0,21,30,39,64,81,102,183,264,345,426,99999,3,9,1001,9,2,9,4,9,99,3,9,1002,9,4,9,4,9,99,3,9,1002,9,5,9,101,2,9,9,102,3,9,9,1001,9,2,9,1002,9,2,9,4,9,99,3,9,1002,9,3,9,1001,9,5,9,1002,9,3,9,4,9,99,3,9,102,4,9,9,1001,9,3,9,102,4,9,9,1001,9,5,9,4,9,99,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,99,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,2,9,4,9,99,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,99
