#! /usr/bin/env ruby

require 'json'
require 'optparse'

# Has the content "session=<base64>"
COOKIE_FILE = 'cookie'
MAX_FETCH_FREQUENCY = 15 * 60

LEADERBOARDS = {
  xtech: 378851,
  affinity: 632609,
  google: 411675,
  otto: 989140,
}

options = {
  year: 2020,
  leaderboard: :google,
  top_n: 15,
}

OptionParser.new do |opts|
  opts.on("-y", "--year [YEAR]", Integer, "Year") do |y|
    options[:year] = y
  end

  opts.on("-l", "--leaderboard [LEADERBOARD]", "Leaderboard") do |l|
    options[:leaderboard] = l.to_sym
  end

  opts.on("-d", "--day [DAY]", Integer, "Day") do |d|
    options[:day] = d
  end

  opts.on("-t", "--top [TOP]", Integer, "Top N performers, use -1 to have no limit") do |t|
    if t == -1
      options.delete(:top_n)
    else
      options[:top_n] = t
    end
  end

  opts.on("-h", "--hide", "Don't show users that haven't completed the problem yet.") do |h|
    options[:hide_inactive] = h
  end
end.parse!

if !LEADERBOARDS.key?(options[:leaderboard])
  puts "Unknown leaderboard: #{options[:leaderboard]}"
  exit(1)
end

YEAR = options[:year]
LEADERBOARD_DATA_FILE = "leaderboard.#{options[:leaderboard]}.#{YEAR}.json"
LEADERBOARD_ID = LEADERBOARDS[options[:leaderboard]]

existing_data = if File.exist?(LEADERBOARD_DATA_FILE)
                  File.read(LEADERBOARD_DATA_FILE).strip
                else
                  ''
                end
should_fetch_again = true

if !existing_data.empty?
  parsed = JSON.parse(existing_data, symbolize_names: true)
  last_fetched_at = parsed[:last_fetched_at]

  if Time.now.to_i - last_fetched_at > MAX_FETCH_FREQUENCY
    should_fetch_again = true
  else
    puts "Using data from #{Time.at(last_fetched_at)}"
    should_fetch_again = false
  end
end

if should_fetch_again
  json = `
    curl --silent 'https://adventofcode.com/#{YEAR}/leaderboard/private/view/#{LEADERBOARD_ID}.json' \
    -H 'cache-control: max-age=0' \
    -H 'cookie: #{File.read(COOKIE_FILE).strip}'
  `

  parsed = JSON.parse(json, symbolize_names: true)

  File.write(LEADERBOARD_DATA_FILE, parsed.merge(last_fetched_at: Time.now.to_i).to_json)
end

members = parsed[:members].values
anon_num = 1
members.each do |member|
  if !member[:name]
    member[:name] = "<Anonymous user #{anon_num}>"
    anon_num += 1
  end
end

latest_day = members.map do |member|
  member[:completion_day_level].keys.map(&:to_s).map(&:to_i).max
end.compact.max

day = options[:day] || latest_day
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

day_start_time = Time.new(YEAR, 11, 30, 21, 0, 0) + ((day - 1) * 24 * 3600)
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

  return " >99 hrs" if hr > 99

  "#{hr.to_s.rjust(2, '0')}:#{min.to_s.rjust(2, '0')}:#{s.to_s.rjust(2, '0')}"
end

num_to_show = options[:top_n] || sorted_members.count
num_shown = 0
num_with_scores = sorted_members.count {|m| m[:first_star_ts]}

sorted_members.each do |m|
  break if num_shown >= num_to_show

  name = m[:name]
  time1 = '--:--:--'
  rank1 = m[:first_star_rank]
  score1 = m[:first_star_score]

  time2 = '--:--:--'
  rank2 = m[:second_star_rank]
  score2 = m[:second_star_score]

  if options[:hide_inactive] && !m[:first_star_ts]
    break
  end

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

  num_shown += 1
end

if num_shown < sorted_members.length
  puts "(Showing #{num_shown} of #{sorted_members.count} members, #{num_with_scores}/#{sorted_members.count} have submitted, pass \"--top -1\" to show all.)"
end
