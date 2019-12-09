#! /usr/bin/env ruby

require './intcode.rb'

def memory(filename)
   File.readlines(filename).map(&:strip)[0].split(',').map(&:to_i)
end

day2_mem = memory('intcode.day2')
day5_mem = memory('intcode.day5')
day7_mem = memory('intcode.day7')
day7_ex1_mem = memory('intcode.day7.ex1')
day7_ex2_mem = memory('intcode.day7.ex2')
day7_ex3_mem = memory('intcode.day7.ex3')
day7_ex4_mem = memory('intcode.day7.ex4')
day7_ex5_mem = memory('intcode.day7.ex5')
day9_mem = memory('intcode.day9')

def check(day, expected, actual)
  if expected == actual
    puts "#{day.ljust(20)} Correct"
  else
    fail "#{day.ljust(20)} failed"
  end
end

#########
# DAY 2 #
#########

def day2(a, b, mem)
  mem = mem.dup
  mem[1] = a
  mem[2] = b

  cpu = Intcode.new(mem)
  cpu.run
  cpu.value_at_addr(0)
end

check('Day 2 Part 1', day2(12, 2, day2_mem), 3850704)

day2_part2 = nil

100.times do |a|
  100.times do |b|
    if day2(a, b, day2_mem) == 19690720
      day2_part2 = (100 * a) + b
      break
    end
  end
end

check('Day 2 Part 2', day2_part2, 6718)

#########
# DAY 5 #
#########

def day5(mem, inputs)
  day5_part1 = Intcode.new(mem)
  output = day5_part1.run(inputs)[:value]
  while output == 0
    output = day5_part1.run[:value]
  end
  output
end

check('Day 5 Part 1', day5(day5_mem, [1]), 9961446)
check('Day 5 Part 2', day5(day5_mem, [5]), 742621)


#########
# DAY 7 #
#########

def day7_part1(mem)
  outputs = [0, 1, 2, 3, 4].permutation.map do |order|
    input = 0
    order.each do |phase|
      output = Intcode.new(mem).run([phase, input])
      input = output[:value]
    end
    input
  end

  outputs.max
end

check('Day 7 Part 1 Ex. 1', day7_part1(day7_ex1_mem), 43210)
check('Day 7 Part 1 Ex. 2', day7_part1(day7_ex2_mem), 54321)
check('Day 7 Part 1 Ex. 3', day7_part1(day7_ex3_mem), 65210)
check('Day 7 Part 1', day7_part1(day7_mem), 65464)

def day7_part2(mem)
  outputs = [5, 6, 7, 8, 9].permutation.map do |order|
    cpu1 = Intcode.new(mem, 'A')
    cpu2 = Intcode.new(mem, 'B')
    cpu3 = Intcode.new(mem, 'C')
    cpu4 = Intcode.new(mem, 'D')
    cpu5 = Intcode.new(mem, 'E')

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

  outputs.max
end

check('Day 7 Part 2 Ex. 4', day7_part2(day7_ex4_mem), 139629729)
check('Day 7 Part 2 Ex. 5', day7_part2(day7_ex5_mem), 18216)
check('Day 7 Part 2', day7_part2(day7_mem), 1518124)

#########
# DAY 9 #
#########

check('Day 9 Part 1', Intcode.new(day9_mem).run([1])[:value], 3533056970)
check('Day 9 Part 2', Intcode.new(day9_mem).run([2])[:value], 72852)

puts 'All good!'
