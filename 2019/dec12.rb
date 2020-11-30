#! /usr/bin/env ruby

require './intcode.rb'
require './input.rb'
require 'set'

strs = get_input_str_arr(__FILE__)

$primes = [2, 3, 5, 7, 11, 13, 17, 19]

(23..700).each do |n|
  is_prime = true
  $primes.each do |p|
    if n % p == 0
      is_prime = false
      break
    end
  end
  $primes << n if is_prime
end

original_positions = strs.map do |str|
  parts = str.split(',')
  ps = parts.map do |part|
    part.split('=')[1].to_i
  end

  ps
end

original_velocities = [
  [0, 0, 0],
  [0, 0, 0],
  [0, 0, 0],
  [0, 0, 0],
]

def iterate(positions, velocities)
  velocities = velocities.each.with_index.map do |v, vi|
    dx, dy, dz = [0, 0, 0]
    positions.each.with_index.map do |p, pi|
      next if vi == pi

      if positions[vi][0] < p[0]
        dx += 1
      elsif positions[vi][0] > p[0]
        dx += -1
      end

      if positions[vi][1] < p[1]
        dy += 1
      elsif positions[vi][1] > p[1]
        dy += -1
      end

      if positions[vi][2] < p[2]
        dz += 1
      elsif positions[vi][2] > p[2]
        dz += -1
      end
    end

    [v[0] + dx, v[1] + dy, v[2] + dz]
  end

  positions = positions.each.with_index.map do |p, pi|
    [
      p[0] + velocities[pi][0],
      p[1] + velocities[pi][1],
      p[2] + velocities[pi][2],
    ]
  end

  [positions, velocities]
end

# Part 1

index = 0
positions = original_positions.map(&:dup)
velocities = original_velocities.map(&:dup)


loop do
  positions, velocities = iterate(positions, velocities)
  index += 1
  break if index > 1000 - 1
end

total_energy = positions.zip(velocities).map do |p, v|
  p.map(&:abs).sum * v.map(&:abs).sum
end
  .sum

puts total_energy

# Part 2

def count_cycle_length(positions, velocities, dim)
  positions = positions.map(&:dup)
  velocities = velocities.map(&:dup)

  positions.each do |pos|
    pos[0] = 0 if dim != 0
    pos[1] = 0 if dim != 1
    pos[2] = 0 if dim != 2
  end

  previous_positions = Set.new
  index = 0

  loop do
    positions, velocities = iterate(positions, velocities)
    index += 1
    break if previous_positions.include?([positions, velocities])
    previous_positions.add([positions, velocities])
  end

  index - 1
end

cycle_x = count_cycle_length(original_positions, original_velocities, 0)
cycle_y = count_cycle_length(original_positions, original_velocities, 1)
cycle_z = count_cycle_length(original_positions, original_velocities, 2)

def factor(n)
  factors = []
  loop do
    found_factor = false
    $primes.each do |p|
      if n % p == 0
        factors << p
        found_factor = true
        n = n / p
        break
      end
    end
    break if !found_factor || n == 1
  end
  factors << n

  factors
end

def lcm(factor_arrs)
  lcm = 1

  while factor_arrs.any?
    factors = factor_arrs.pop
    factors.each do |factor|
      lcm *= factor

      factor_arrs.each do |factor_arr|
        factor_arr.shift if factor_arr[0] == factor
      end
    end
  end

  lcm
end

puts lcm([factor(cycle_x), factor(cycle_y), factor(cycle_z)])

__END__
<x=19, y=-10, z=7>
<x=1, y=2, z=-3>
<x=14, y=-4, z=1>
<x=8, y=7, z=-6>
