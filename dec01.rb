#! /usr/bin/ruby

masses = File.readlines('dec01.input').map(&:to_i)

def fuel_for_mass(m)
  (m / 3).floor - 2
end


### Star 1

total = 0
masses.each {|m| total += fuel_for_mass(m)}

puts total


### Star 2

total = 0
masses.each do |m|
  fuel_mass = fuel_for_mass(m)
  while fuel_mass > 0
    total += fuel_mass
    fuel_mass = fuel_for_mass(fuel_mass)
  end
end

puts total
