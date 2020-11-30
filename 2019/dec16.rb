#! /usr/bin/env ruby

require './intcode.rb'
require './input.rb'

str = get_input_str(__FILE__)

orig_ints = str.split('').map(&:to_i)


base_pattern = [0, 1, 0, -1]

patterns = orig_ints.length.times.map do |n|
  n += 1
  pattern = base_pattern.flat_map {|i| [i] * n}
  pattern = pattern * (1 + orig_ints.length / pattern.length)
  pattern.shift
  pattern = pattern[0..(orig_ints.length - 1)]
  pattern
end

ints = orig_ints.dup

100.times do
  ints = ints.each.with_index.map do |_, n|
    ints.zip(patterns[n]).map {|i, p| i * p}.sum.abs % 10
    # ints.each.with_index.map {|v, i| v * base_pattern[(i + 1) / (n + 1) % 4]}.sum.abs % 10
  end
end

puts ints[0...8].map(&:to_s).join('')

offset = orig_ints[0...7].map(&:to_s).join('').to_i

full_ints = orig_ints * 10000
later_ints = full_ints[offset..-1]

100.times do |n|
  sum = later_ints.sum

  later_ints.map! do |n|
    before_sub = sum % 10
    sum -= n
    before_sub
  end
end

puts later_ints[0...8].map(&:to_s).join('')




__END__
59793513516782374825915243993822865203688298721919339628274587775705006728427921751430533510981343323758576985437451867752936052153192753660463974146842169169504066730474876587016668826124639010922391218906707376662919204980583671961374243713362170277231101686574078221791965458164785925384486127508173239563372833776841606271237694768938831709136453354321708319835083666223956618272981294631469954624760620412170069396383335680428214399523030064601263676270903213996956414287336234682903859823675958155009987384202594409175930384736760416642456784909043049471828143167853096088824339425988907292558707480725410676823614387254696304038713756368483311
