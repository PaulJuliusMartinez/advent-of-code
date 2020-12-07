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
  sort: "score"
}

VALID_SORTS = %w(score total part1 part2 name)

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

  opts.on("-s", "--sort [SORT]", "Which column to sort by") do |s|
    if !VALID_SORTS.include?(s)
      puts "Invalid sort: #{s} (options are #{VALID_SORTS.join(',')})"
      exit(1)
    end
    options[:sort] = s
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

part2_order = processed_members
  .select {|m| m[:second_star_ts]}
  .sort_by {|m| m[:second_star_ts] - m[:first_star_ts]}

processed_members.each do |member|
  part1_rank = first_star_order.index(member)
  member[:part1_rank] = part1_rank + 1 if part1_rank
  member[:first_star_score] = members.length + 1 - part1_rank if part1_rank

  total_rank = second_star_order.index(member)
  member[:total_rank] = total_rank + 1 if total_rank
  member[:second_star_score] = members.length + 1 - total_rank if total_rank

  part2_rank = part2_order.index(member)
  member[:part2_rank] = part2_rank + 1 if part2_rank

  member[:score] = nil

  if part1_rank
    member[:score] = member[:first_star_score] + (member[:second_star_score] || 0)
  end
end

max_t = Time.now.to_i
sorted_members = processed_members.sort_by do |m|
  score = -(m[:score] || 0)
  total_time = m[:second_star_ts] || max_t
  part1_time = m[:first_star_ts] || max_t
  part2_time = if m[:second_star_ts]
                 m[:second_star_ts] - m[:first_star_ts]
               else
                 max_t
               end

  case options[:sort]
  when "score"
    [score, total_time, part1_time, m[:name]]
  when "part1"
    [part1_time, score, total_time, m[:name]]
  when "part2"
    [part2_time, score, total_time, m[:name]]
  when "total"
    [total_time, score, part1_time, m[:name]]
  when "name"
    [m[:name], score, total_time, part1_time]
  end
end

day_start_time = Time.new(YEAR, 12, 1, 0, 0, 0, "-05:00") + ((day - 1) * 24 * 3600)
start_ts = day_start_time.to_i

num_to_show = options[:top_n] || sorted_members.count
max_length_name = sorted_members.take(num_to_show).map {|m| m[:name]}.map(&:length).max
max_length_name = [max_length_name, "Day #{day} Leaderboard".length].max

puts <<~HEADER
#{"Day #{day} Leaderboard".center(max_length_name)}   -------Part 1--------   ----Part 2-----   ---------Finish-------
  #{"Name".center(max_length_name)}     Time  Rank  Score     ∆ Time   Rank       Time   Rank  Score   Total
HEADER

def format_ts(ts, start_ts)
  elapsed = ts - start_ts
  hr, elapsed = elapsed.divmod(3600)
  min, s = elapsed.divmod(60)

  return " >99 hrs" if hr > 99

  "#{hr.to_s.rjust(2, '0')}:#{min.to_s.rjust(2, '0')}:#{s.to_s.rjust(2, '0')}"
end

num_shown = 0
num_with_scores = sorted_members.count {|m| m[:first_star_ts]}

sorted_members.take(num_to_show).each do |m|
  name = m[:name]
  time1 = '--:--:--'
  part1_rank = m[:part1_rank]
  score1 = m[:first_star_score]

  total_time = '--:--:--'
  total_rank = m[:total_rank]
  score2 = m[:second_star_score]

  part2_time = '--:--:--'
  part2_rank = m[:part2_rank]
  if m[:second_star_ts]
    part2_time = format_ts(m[:second_star_ts] - m[:first_star_ts], 0)
  end

  if options[:hide_inactive] && !m[:first_star_ts]
    if options[:sort] == 'name'
      next
    else
      break
    end
  end

  total_score = score1
  total_score += score2 if score2

  time1 = format_ts(m[:first_star_ts], start_ts) if m[:first_star_ts]
  total_time = format_ts(m[:second_star_ts], start_ts) if m[:second_star_ts]

  puts(
    "#{name.ljust(max_length_name)}   " +
      "#{time1}   #{part1_rank.to_s.rjust(3)}  #{score1.to_s.rjust(5)}   " +
      "#{part2_time}    #{part2_rank.to_s.rjust(3)}   #{total_time}    #{total_rank.to_s.rjust(3)}  #{score2.to_s.rjust(5)}   " +
      total_score.to_s.rjust(5),
  )

  num_shown += 1
end

if num_shown < sorted_members.length
  puts "(Showing #{num_shown} of #{sorted_members.count} members, #{num_with_scores}/#{sorted_members.count} have submitted, pass \"--top -1\" to show all.)"
end
