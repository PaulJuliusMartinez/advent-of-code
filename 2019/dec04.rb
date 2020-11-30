#! /usr/bin/env ruby

strs = DATA.readlines.map(&:strip)
ints = strs[0].split('-').map(&:to_i)

min, max = ints

def fits_criteria(n)
  chars = n.to_s.split('')
  a, b, c, d, e, f = chars

  ai, bi, ci, di, ei, fi = chars.map(&:to_i)

  decreasing = ai <= bi && bi <= ci && ci <= di && di <= ei && ei <= fi

  two_same = a == b || b == c || c == d || d == e || e == f

  # For Part1:
  # return two_same && decreasing

  # Part 2

  pairs = [[0, 1], [1, 2], [2, 3], [3, 4], [4, 5]]

  two_matching = pairs.any? do |pair|
    ch1 = chars[pair[0]]
    ch2 = chars[pair[1]]

    others = ([0, 1, 2, 3, 4, 5] - pair).map {|index| chars[index]}

    ch1 == ch2 && !others.include?(ch1)
  end

  two_matching && decreasing
end

# puts fits_criteria(111111)
# puts fits_criteria(223450)
# puts fits_criteria(123789)

puts fits_criteria(112233)
puts fits_criteria(123444)
puts fits_criteria(111122)

num = ((min-1)..max).count {|n| fits_criteria(n)}
puts num

__END__
271973-785961
