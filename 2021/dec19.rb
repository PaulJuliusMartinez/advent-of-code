#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

def orient!(beacons, oriented_beacons)
  original_beacons = beacons
  original_oriented_beacons = oriented_beacons
  beacons, oriented_beacons = find_12_overlapping_beacons(beacons, oriented_beacons)

  [0, 1, 2].permutation.each do |order|
    [false, true].each do |flip_x|
      [false, true].each do |flip_y|
        [false, true].each do |flip_z|

          orientation_mod = {
            order: order,
            flip_x: flip_x,
            flip_y: flip_y,
            flip_z: flip_z,
          }

          # puts "trying #{orientation_mod.inspect}"
          if deltas_match?(beacons, oriented_beacons, orientation_mod)
            # Orient all the beacons
            new_beacons = original_beacons.map do |beacon|
              orient_beacon(beacon.dup, orientation_mod)
            end

            # puts "oriented"
            # oriented_beacons.each {|beacon| puts beacon.join(",") }
            # puts "un-oriented"
            # beacons.each {|beacon| puts beacon.join(",") }
            # puts "re-oriented"
            # beacons.each {|beacon| puts orient_beacon(beacon, orientation_mod).join(",") }


            # Want to do: beacon + dx = oriented_beacon
            # Therefore: dx = oriented_beacon - beacon
            first_overlapping_beacon = orient_beacon(beacons[0].dup, orientation_mod)
            dx = oriented_beacons[0][0] - first_overlapping_beacon[0]
            dy = oriented_beacons[0][1] - first_overlapping_beacon[1]
            dz = oriented_beacons[0][2] - first_overlapping_beacon[2]
            # puts [dx, dy, dz].inspect

            # oriented_beacons.zip(beacons).each do |ob, b|
            #   rob = orient_beacon(b, orientation_mod)
            #   rob[0] += dx
            #   rob[1] += dy
            #   rob[2] += dz
            #   puts "  #{ob.join(",")} -> #{rob.join(",")}"
            # end

            new_beacons.each do |beacon|
              beacon[0] += dx
              beacon[1] += dy
              beacon[2] += dz
            end

            return [new_beacons, orientation_mod, [dx, dy, dz]]
          end
        end
      end
    end
  end
end

def deltas_match?(bs, oriented_bs, orientation_mod)
  # puts "Checking: #{orientation_mod.inspect}"
  bs.each_cons(2).zip(oriented_bs.each_cons(2)).all? do |b_pair, oriented_b_pair|
    # puts b_pair.inspect
    # puts oriented_b_pair.inspect
    b1, b2 = b_pair
    # puts "#{b1.join(",")} -> #{orient_beacon(b1, orientation_mod).join(",")}"
    # puts "#{b2.join(",")} -> #{orient_beacon(b2, orientation_mod).join(",")}"
    b1 = orient_beacon(b1.dup, orientation_mod)
    b2 = orient_beacon(b2.dup, orientation_mod)
    # puts [b1, b2].inspect

    ob1, ob2 = oriented_b_pair

    delta = [b1[0] - b2[0], b1[1] - b2[1], b1[2] - b2[2]]
    # puts delta.join(",")
    oriented_delta = [ob1[0] - ob2[0], ob1[1] - ob2[1], ob1[2] - ob2[2]]
    # puts oriented_delta.join(",")

    # puts "matched!" if delta == oriented_delta
    delta == oriented_delta
  end
end

def orient_beacon(beacon, orientation_mod)
  beacon[0] = -beacon[0] if orientation_mod[:flip_x]
  beacon[1] = -beacon[1] if orientation_mod[:flip_y]
  beacon[2] = -beacon[2] if orientation_mod[:flip_z]

  i1, i2, i3 = orientation_mod[:order]
  [beacon[i1], beacon[i2], beacon[i3]]
end

def find_12_overlapping_beacons(beacons1, beacons2)
  deltas_and_maps1, deltas_and_maps2 = [beacons1, beacons2].map do |beacons|
    deltas = Set.new
    sig_to_indexes = {}
    beacons_to_delta = {}

    beacons.each.with_index do |beacon1, b1|
      beacons.each.with_index do |beacon2, b2|
        next if b1 >= b2

        delta_sig = [
          beacon1[0] - beacon2[0],
          beacon1[1] - beacon2[1],
          beacon1[2] - beacon2[2],
        ].map(&:abs).sort

        next if delta_sig == [0, 0, 0]

        # puts "Scanner #{s} delta_sig between #{b1} and #{b2}: #{delta_sig.inspect}"

        deltas << delta_sig
        sig_to_indexes[delta_sig] = [b1, b2]
        beacons_to_delta[[b1, b2]] = delta_sig
        beacons_to_delta[[b2, b1]] = delta_sig
      end
    end

    [deltas, sig_to_indexes, beacons_to_delta]
  end

  deltas1, sig_to_indexes1, beacons_to_delta1 = deltas_and_maps1
  deltas2, sig_to_indexes2, beacons_to_delta2 = deltas_and_maps2

  deltas = (deltas1 & deltas2).to_a

  overlapping_beacons1 = deltas.flat_map {|d| sig_to_indexes1[d]}.uniq

  first_delta = beacons_to_delta1[[
    overlapping_beacons1[0],
    overlapping_beacons1[1],
  ]]

  possible_starts = sig_to_indexes2[first_delta]
  # puts "possible_starts: #{possible_starts.inspect}"

  possible_starts.each do |start|
    overlapping_beacons2 = [start]
    next_index = 1

    while next_index < NUM_OVERLAPPING
      prev_beacon2 = overlapping_beacons2.last
      # puts "prev beacon: #{prev_beacon2}"

      adjacent_delta = beacons_to_delta1[[
        overlapping_beacons1[next_index - 1],
        overlapping_beacons1[next_index],
      ]]
      # puts "adjacent_delta: #{adjacent_delta}"

      beacons_for_delta = sig_to_indexes2[adjacent_delta] - [prev_beacon2]

      if beacons_for_delta.length != 1
        # puts "picked wrong start: #{beacons_for_delta.inspect}"
        break
      end

      overlapping_beacons2 << beacons_for_delta[0]

      next_index += 1
    end

    # puts overlapping_beacons2.inspect
    next if overlapping_beacons2.length != NUM_OVERLAPPING

    list1 = overlapping_beacons1.map {|index| beacons1[index]}
    list2 = overlapping_beacons2.map {|index| beacons2[index]}

    # puts "done!"

    return [list1, list2]
  end
end


# SOLUTION

grouped_strs = str_groups_separated_by_blank_lines(__FILE__)

scanner_beacons = grouped_strs.map do |scanner_data|
  scanner_data[1..].map do |line|
    coords = line.split(",").map(&:to_i)
    coords << 0 while coords.length < 3
    coords
  end
end

scanner_deltas = scanner_beacons.map.with_index do |beacons, s|
  deltas = Set.new
  beacons.each.with_index do |beacon1, b1|
    beacons.each.with_index do |beacon2, b2|
      next if b1 >= b2

      delta_sig = [
        beacon1[0] - beacon2[0],
        beacon1[1] - beacon2[1],
        beacon1[2] - beacon2[2],
      ].map(&:abs).sort

      next if delta_sig == [0, 0, 0]

      # puts "Scanner #{s} delta_sig between #{b1} and #{b2}: #{delta_sig.inspect}"

      deltas << delta_sig
    end
  end

  deltas
end

overlaps = []

scanner_deltas.each.with_index do |deltas1, s1|
  scanner_deltas.each.with_index do |deltas2, s2|
    next if s1 >= s2
    overlaps << [(deltas1 & deltas2).count, s1, s2]
  end
end

NUM_OVERLAPPING = 12
REQUIED_INTERSECTING_DELTAS = NUM_OVERLAPPING * (NUM_OVERLAPPING - 1) / 2
overlaps.sort!.reverse!.select! {|arr| arr[0] >= REQUIED_INTERSECTING_DELTAS}

overlap_map = Hash.new {|h, k| h[k] = []}
overlaps.each do |_, s1, s2|
  overlap_map[s1] << s2
  overlap_map[s2] << s1
end

oriented = Set.new([0])
# puts "oriented 0"
to_orient = overlap_map[0].map {|neighbor| [neighbor, 0]}
# puts to_orient.inspect

scanner_locs = [[0, 0, 0]]
while to_orient.any?
  next_to_orient, relative_to = to_orient.pop
  if oriented.include?(next_to_orient)
    # puts "already oriented #{next_to_orient}"
    next
  end
  oriented << next_to_orient

  # puts "will try to orient #{next_to_orient} relative to #{relative_to}"
  # puts scanner_beacons.inspect
  oriented_beacons, orientation_mod, displacement = orient!(
    scanner_beacons[next_to_orient],
    scanner_beacons[relative_to],
  )
  scanner_locs << displacement
  # puts "oriented #{next_to_orient} relative to #{relative_to}, orientation_mod: #{orientation_mod.inspect}"

  scanner_beacons[next_to_orient] = oriented_beacons

  overlap_map[next_to_orient].each {|neighbor| to_orient << [neighbor, next_to_orient]}

  # puts to_orient.inspect
end

all_beacons = Set.new
scanner_beacons.each do |beacons|
  beacons.each do |beacon|
    all_beacons << beacon
  end
end

puts "Part 1: #{all_beacons.count}"

max_distance = 0
scanner_locs.each do |s1p|
  scanner_locs.each do |s2p|
    next if s1p == s2p
    d = [s1p[0] - s2p[0], s1p[1] - s2p[1], s1p[2] - s2p[2]].map(&:abs).sum
    max_distance = [d, max_distance].max
  end
end

puts "Part 2: #{max_distance}"
