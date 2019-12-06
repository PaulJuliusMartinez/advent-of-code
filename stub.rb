#! /usr/bin/env ruby

# Run ./decXX.rb <test_name> to run code on input in file decXX.<test_name>.
strs =
  if ARGV[0]
    test_filename = File.readlines("#{__FILE__.chomp('rb')}#{ARGV[0]}").map(&:strip)
  else
    DATA.readlines.map(&:strip)
  end
ints = strs.map(&:to_i)

puts strs
puts ints

__END__
hello
1234
