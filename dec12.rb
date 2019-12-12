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

positions = strs.map do |str|
  parts = str.split(',')
  ps = parts.map do |part|
    part.split('=')[1].to_i
  end

  ps[1] = 0
  ps[2] = 0

  ps
end

velocities = [
  [0, 0, 0],
  [0, 0, 0],
  [0, 0, 0],
  [0, 0, 0],
]

index = 0


previous_positions = Set.new

loop do
  # update velocities
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


  index += 1

  break if previous_positions.include?([positions, velocities])

  previous_positions.add([positions, velocities])
end

puts index - 1
# puts "#{positions[0].inspect} #{velocities[0].inspect}"
# puts "#{positions[1].inspect} #{velocities[1].inspect}"
# puts "#{positions[2].inspect} #{velocities[2].inspect}"
# puts "#{positions[3].inspect} #{velocities[3].inspect}"

total_energy = positions.zip(velocities).map do |p, v|
  p.map(&:abs).sum * v.map(&:abs).sum
end
  .sum

# puts total_energy

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

puts factor(268296).inspect
puts factor(193052).inspect
puts factor(102356).inspect

__END__
<x=19, y=-10, z=7>
<x=1, y=2, z=-3>
<x=14, y=-4, z=1>
<x=8, y=7, z=-6>
