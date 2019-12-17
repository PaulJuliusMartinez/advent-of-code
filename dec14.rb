#! /usr/bin/env ruby

require './intcode.rb'
require './input.rb'

strs = get_input_str_arr(__FILE__)

production_rules = {}

strs.each do |str|
  inputs, outputs = str.split('=>').map(&:strip)
  inputs = inputs.split(',').map do |count_and_input|
    count, input = count_and_input.split(' ')
    count = count.to_i
    [input, count]
  end

  output_parts = outputs.split(' ')
  output_count = output_parts[0].to_i
  output = output_parts[1]

  production_rules[output] = [output_count, inputs]
end


def calculate_ore_needs(rules, amount)
  needs = Hash.new {|h, k| h[k] = 0}
  needs['FUEL'] = amount

  loop do
    used_rule = false

    needs.keys.each do |need|
      next if need == 'ORE'

      num_needed = needs[need]
      next if num_needed <= 0

      used_rule = true

      produced, inputs = rules[need]
      times_used = (num_needed.to_f / produced).ceil

      # puts "Need #{num_needed} #{need}, rule produces #{produced}, using rule #{times_used} times"

      needs[need] -= times_used * produced
      # puts "  Now only need #{needs[need]} #{need}"
      inputs.each do |input|
        resource, quantity = input
        # puts "  Previously needed #{needs[resource]} #{resource}"
        needs[resource] += quantity * times_used
        # puts "  Now need #{needs[resource]} #{resource}"
      end

    end

    break if !used_rule
  end

  needs['ORE']
end

needed_for_one = calculate_ore_needs(production_rules, 1)
puts needed_for_one

TRILLION = 1_000_000_000_000
min = (TRILLION.to_f / needed_for_one).floor
max = min * 2

while min != max do
  mid = (min + max) / 2
  if calculate_ore_needs(production_rules, mid) > TRILLION
    max = mid - 1
  else
    min = mid
  end
end

puts min



__END__
9 GJSNW, 9 GHJHK => 6 DRKW
1 SJNKX, 1 GHJHK, 7 DCPM => 1 BFGL
7 RBJHJ, 8 CHPCH, 1 SJHGH, 9 ZMRD, 2 VDVN, 17 SFSN, 4 DPZW => 9 TXWFP
1 KBJXG, 6 GJSNW, 2 RKBM => 9 QMVN
1 QMVN, 1 MWXF => 9 QZRM
1 ZPXS, 1 QZRM => 5 TWNV
1 RBJHJ => 9 BXGJ
4 RFLMC => 2 KRLSB
9 JBTL, 2 TZBZR => 4 WPXNJ
3 DCPM, 2 ZTLXS => 3 MWXF
3 QXFZ, 3 QTZW => 8 SJHGH
15 WPXNJ => 4 DXTFP
5 ZLJT, 3 GHJHK => 9 QXFZ
2 GHJHK => 8 LFQDQ
6 QMVN, 19 DRKW => 5 XCLVL
5 QTZW, 1 DCPM, 9 KBLFQ => 6 RPMHX
11 KBJXG => 1 TMXRJ
4 TKNB => 7 SFSN
29 XCLVL => 6 RBJHJ
5 BSMN, 11 MQZBK, 1 XCLVL, 12 BXGJ, 2 KDHT, 4 TMXRJ => 3 NCNMC
1 SPKZM, 1 TFWDG, 15 KRLSB => 8 MQZBK
21 DCPM, 18 QXFZ => 2 TZBZR
1 TMXRJ => 3 KBLFQ
5 BCBTD => 3 VDVN
1 DXTFP, 15 SPKZM => 5 DBWNB
5 ZTLXS => 8 QTZW
4 LFQDQ, 1 DRKW => 5 JBTL
6 XCLVL => 6 KDFC
2 TWNV, 29 CRDZ => 9 CXZG
11 KQVSV, 5 KSNJ => 7 ZMRD
150 ORE => 3 RKBM
9 QXFZ, 3 JBTL => 1 SJNKX
8 TXWFP, 1 BSMN, 6 WRTCX, 5 NCNMC, 12 RPMHX, 18 VZNQ, 1 ZPXS, 17 MGWHP, 15 CXZG => 1 FUEL
14 SJHGH, 1 KQVSV, 12 BCBTD, 17 QLQP, 11 JBLCQ, 2 KDHT, 2 JBTL => 9 WRTCX
2 TKNB, 11 KDFC => 9 SPKZM
122 ORE => 7 WXRBN
16 TZBZR => 1 ZPXS
2 KDHT => 5 QLQP
3 RKBM, 5 WXRBN => 6 ZLJT
26 MWXF, 6 MCXDR => 2 TKNB
2 SJNKX => 5 MCXDR
2 QXFZ => 8 DCPM
2 KBLFQ => 7 TFWDG
172 ORE => 9 GHJHK
2 CHPCH, 8 DPZW, 11 ZLJT => 2 CRDZ
2 SPKZM, 6 DCPM => 4 CHPCH
9 RPMHX, 5 KQVSV => 9 MGWHP
3 BFGL, 5 WPXNJ => 9 KSNJ
1 SJGC => 8 DPZW
1 BSMN => 5 BCBTD
2 ZTLXS, 1 KSNJ => 8 SJGC
186 ORE => 8 GJSNW
20 TKNB, 1 DXTFP, 11 QZRM => 7 KDHT
14 DXTFP => 7 BSMN
117 ORE => 6 KBJXG
2 WPXNJ => 4 VZNQ
4 RPFV, 1 ZMRD => 4 RFLMC
10 QTZW => 2 RPFV
2 QMVN, 6 LFQDQ, 7 GJSNW => 7 ZTLXS
33 QZRM => 4 KQVSV
1 SJHGH, 1 DPZW, 8 DBWNB => 8 JBLCQ