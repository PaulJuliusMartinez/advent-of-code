#! /usr/bin/env ruby

require 'set'
require './intcode-v3.rb'

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
day11_mem = memory('intcode.day11')
day13_mem = memory('intcode.day13')

def check(day, expected, actual)
  if expected == actual
    puts "#{day.ljust(20)} Correct"
  else
    fail "#{day.ljust(20)} Failed (Expected #{expected}, but got #{actual}"
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
  day5_part1.run(inputs)
  day5_part1.all_output.last
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
      cpu = Intcode.new(mem)
      cpu.run([phase, input])
      input = cpu.next_output
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
      cpu.queue_input(phase)
    end

    last_output = 0
    last_e_output = nil
    break_all = false

    while !break_all do
      cpus.each do |cpu|
        if cpu.halted?
          break_all = true
          break
        end

        cpu.queue_input(last_output)
        cpu.run

        last_output = cpu.next_output
        last_e_output = last_output if cpu == cpu5
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

check('Day 9 Part 1', Intcode.new(day9_mem).run([1], return_output: true)[:value], 3533056970)
check('Day 9 Part 2', Intcode.new(day9_mem).run([2], return_output: true)[:value], 72852)

##########
# DAY 11 #
##########

cpu = Intcode.new(day11_mem)
curr_dir = [0, 1]

curr_x, curr_y = [0, 0]
panels = Hash.new {|h, k| h[k] = 'b'}

painted = Set.new

loop do
  break if cpu.halted?
  cpu.queue_input(panels[[curr_x, curr_y]] == 'b' ? 0 : 1)
  cpu.run

  val1, val2 = cpu.all_output

  painted.add([curr_x, curr_y])
  panels[[curr_x, curr_y]] = val1 == 0 ? 'b' : 'w'

  if val2 == 0
    # turn left
    curr_dir = [-curr_dir[1], curr_dir[0]]
  else
    # turn right
    curr_dir = [curr_dir[1], -curr_dir[0]]
  end

  curr_x += curr_dir[0]
  curr_y += curr_dir[1]
end

check('Day 11 Part 1', painted.count, 2238)

##########
# DAY 13 #
##########

def day13_part1(mem)
  cpu = Intcode.new(mem)
  cpu.run

  cpu.all_output.each_slice(3).count {|_x, _y, tile_id| tile_id == 2}
end

def day13_part2(mem)
  mem[0] = 2
  cpu = Intcode.new(mem)

  last_score = 0
  last_ball_x = nil
  last_paddle_x = nil

  loop do
    break if cpu.halted?

    cpu.run

    cpu.all_output.each_slice(3) do |x, y, tile_id|
      if [x, y] == [-1, 0]
        last_score = tile_id
      else
        if tile_id == 3
          last_paddle_x = x
        elsif tile_id == 4
          last_ball_x = x
        end
      end
    end

    if last_paddle_x < last_ball_x
      cpu.queue_input(1)
    elsif last_paddle_x > last_ball_x
      cpu.queue_input(-1)
    else
      cpu.queue_input(0)
    end
  end

  last_score
end

check('Day 13 Part 1', day13_part1(day13_mem), 270)
check('Day 13 Part 2', day13_part2(day13_mem), 12535)

puts 'All good!'
