#! /usr/bin/env ruby

strs = DATA.readlines.map(&:strip)
ints = strs.map(&:to_i)

puts strs
puts ints

__END__
hello
1234
