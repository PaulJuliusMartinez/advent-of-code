#! /usr/bin/env ruby

require 'json'

json = `
  curl 'https://adventofcode.com/2019/leaderboard/private/view/632609.json' \
  -H 'cache-control: max-age=0' \
  -H 'cookie: #{File.read('cookie').strip}'
`

members = JSON.parse(json, symbolize_names: true)[:members].values

latest_day = members.map do |member|
  member[:completion_day_level].keys.map(&:to_s).map(&:to_i).max
end.compact.max

day = ARGV[0] ? ARGV[0].to_i : latest_day
day_sym = day.to_s.to_sym

processed_members = members.map do |member|
  completions = member[:completion_day_level][day_sym] || {}

  {
    name: member[:name],
    first_star_ts: completions&.[](:"1")&.[](:get_star_ts)&.to_i,
    second_star_ts: completions&.[](:"2")&.[](:get_star_ts)&.to_i,
  }
end

first_star_order = processed_members
  .select {|m| m[:first_star_ts]}
  .sort_by {|m| m[:first_star_ts]}

second_star_order = processed_members
  .select {|m| m[:second_star_ts]}
  .sort_by {|m| m[:second_star_ts]}

processed_members.each do |member|
  rank1 = first_star_order.index(member)
  member[:first_star_rank] = rank1 + 1 if rank1
  member[:first_star_score] = members.length + 1 - rank1 if rank1

  rank2 = second_star_order.index(member)
  member[:second_star_rank] = rank2 + 1 if rank2
  member[:second_star_score] = members.length + 1 - rank2 if rank2

  member[:score] = nil

  if rank1
    member[:score] = member[:first_star_score] + (member[:second_star_score] || 0)
  end
end

max_t = Time.now.to_i
sorted_members = processed_members.sort_by do |m|
  [-(m[:score] || 0), m[:second_star_ts] || max_t, m[:first_star_ts] || max_t, m[:name]]
end

day_start_time = Time.new(2019, 11, 30, 21, 0, 0) + ((day - 1) * 24 * 3600)
start_ts = day_start_time.to_i

max_length_name = members.map {|m| m[:name]}.map(&:length).max

puts <<~HEADER
#{"Day #{day} Leaderboard".center(max_length_name)}   -------Part 1--------   -------Part 2--------
  #{"Name".center(max_length_name)}     Time  Rank  Score       Time  Rank  Score   Total
HEADER

def format_ts(ts, start_ts)
  elapsed = ts - start_ts
  hr, elapsed = elapsed.divmod(3600)
  min, s = elapsed.divmod(60)

  "#{hr.to_s.rjust(2, '0')}:#{min.to_s.rjust(2, '0')}:#{s.to_s.rjust(2, '0')}"
end

sorted_members.each do |m|
  name = m[:name]
  time1 = '--:--:--'
  rank1 = m[:first_star_rank]
  score1 = m[:first_star_score]

  time2 = '--:--:--'
  rank2 = m[:second_star_rank]
  score2 = m[:second_star_score]

  total_score = score1
  total_score += score2 if score2

  time1 = format_ts(m[:first_star_ts], start_ts) if m[:first_star_ts]
  time2 = format_ts(m[:second_star_ts], start_ts) if m[:second_star_ts]

  puts(
    "#{name.ljust(max_length_name)}   " +
      "#{time1}   #{rank1.to_s.rjust(3)}  #{score1.to_s.rjust(5)}   " +
      "#{time2}   #{rank2.to_s.rjust(3)}  #{score2.to_s.rjust(5)}   " +
      total_score.to_s.rjust(5),
  )
end
