#! /usr/bin/env ruby

require './input.rb'
require './util.rb'

require 'set'
require 'prime'
require 'scanf'

str = get_input_str(__FILE__)


bits = str.chars.map do |ch|
  b = ch.to_i(16).to_s(2).chars
  b.unshift("0") while b.length != 4
  b
end.flatten

packets = []

version_numbers = 0

$packet_id = 0

packet_stack = []
packet_stack << {
  id: $packet_id,
  sub_packets: [],
  remaining_packets: 999999,
  remaining_bits: 999999,
}

while bits.any?
  if packet_stack[0][:sub_packets][0]
    break if packet_stack[0][:sub_packets][0][:remaining_bits] == 0
    break if packet_stack[0][:sub_packets][0][:remaining_packets] == 0
  end

  before_len = bits.length

  version = bits.shift(3).join.to_i(2)
  type_id = bits.shift(3).join.to_i(2)

  # puts "version: #{version}, type_id: #{type_id}"

  version_numbers += version

  literal_value = nil
  total_length = nil
  num_packets = nil

  if type_id == 4
    digits = []

    first_bit = bits.shift
    digits.concat(bits.shift(4))
    while first_bit == '1'
      first_bit = bits.shift
      digits.concat(bits.shift(4))
    end

    literal_value = digits.join.to_i(2)
    # puts "literal: #{literal_value}"
  else
    length_id = bits.shift
    if length_id == '0'
      total_length = bits.shift(15).join.to_i(2)
      # puts "operator, length: #{total_length}"
    else
      num_packets = bits.shift(11).join.to_i(2)
      # puts "operator, num_packets: #{num_packets}"
    end
  end

  bits_used = before_len - bits.length

  $packet_id += 1
  packet_id = $packet_id
  if literal_value
    new_packet = { literal: literal_value, packet_id: $packet_id }
    # puts "Packet[#{packet_id}] is a literal"
  else
    new_packet = { packet_id: $packet_id, sub_packets: [] }
    # puts "Packet[#{packet_id}] is an operator"
    if num_packets
      new_packet[:remaining_packets] = num_packets
      # puts "Packet[#{packet_id}] has #{num_packets} sub-packets"
    end
    if total_length
      new_packet[:remaining_bits] = total_length
      # puts "Packet[#{packet_id}] has #{total_length} sub-packets"
    end
  end

  new_packet[:version] = version
  new_packet[:type_id] = type_id

  packet_stack.last[:sub_packets] << new_packet

  # print "  " * packet_stack.length
  #
  packet_stack.each do |ancestor|
    if ancestor[:remaining_bits]
      ancestor[:remaining_bits] -= bits_used
      # puts "Removing #{bits_used} from Packet[#{ancestor}], now #{ancestor[:remaining_bits]}"
    end
  end

  if packet_stack.last[:remaining_packets]
    packet_stack.last[:remaining_packets] -= 1
    # puts "packet_stack remaining_packets: #{packet_stack.last[:remaining_packets]}"
    packet_stack.pop if packet_stack.last[:remaining_packets] == 0
  end

  while packet_stack.last[:remaining_bits] == 0
    # puts "Popping packet with no more bits"
    packet_stack.pop
  end

  if !literal_value
    packet_stack << new_packet
  end
end

puts "Part 1: #{version_numbers}"

require 'json'
# puts JSON.pretty_generate(packet_stack)

SUM = 0
PRODUCT = 1
MIN = 2
MAX = 3
LITERAL = 4
GT = 5
LT = 6
EQ = 7

def eval_packet(packet, depth)
  # print "  " * depth
  if packet[:type_id] == LITERAL
    # puts "Literal #{packet[:literal]}"
    return packet[:literal]
  end

  sub_packets = packet[:sub_packets].map {|sub_packet| eval_packet(sub_packet, depth + 1)}

  case packet[:type_id]
  when SUM
    # puts "Summing #{sub_packets.join(', ')}"
    sub_packets.sum
  when PRODUCT
    # puts "Multipling #{sub_packets.join(', ')}"
    prod = 1
    sub_packets.each {|val| prod *= val}
    prod
  when MIN
    # puts "Min of #{sub_packets.join(', ')}"
    sub_packets.min
  when MAX
    # puts "Max of #{sub_packets.join(', ')}"
    sub_packets.max
  when GT
    # puts "#{sub_packets[0]} > #{sub_packets[1]}"
    sub_packets[0] > sub_packets[1] ? 1 : 0
  when LT
    # puts "#{sub_packets[0]} < #{sub_packets[1]}"
    sub_packets[0] < sub_packets[1] ? 1 : 0
  when EQ
    # puts "#{sub_packets[0]} == #{sub_packets[1]}"
    sub_packets[0] == sub_packets[1] ? 1 : 0
  else
    0
  end
end

# puts packet_stack.length
puts "Part 2: #{eval_packet(packet_stack[0][:sub_packets][0], 0)}"
