#! /usr/bin/env ruby

require './intcode-v3.rb'
require './input.rb'

strs = get_input_str_arr(__FILE__)

REVERSE = 'deal into new stack'

DECK_SIZE = 10007

deck = DECK_SIZE.times.map(&:itself)

actions = strs.map do |action|
  if action == REVERSE
    {action: :reverse}
  elsif action.start_with?('deal with increment ')
    stride = action.split(' ').last.to_i
    {action: :stride, stride: stride}
  else
    cut = action.split(' ').last.to_i
    {action: :cut, cut: cut}
  end
end

strs.each do |action|
  if action == REVERSE
    deck = deck.reverse
  elsif action.start_with?('deal with increment ')
    stride = action.split(' ').last.to_i

    new_deck = deck.dup
    DECK_SIZE.times do |i|
      new_deck[(i * stride) % DECK_SIZE] = deck[i]
    end
    deck = new_deck
  elsif action.start_with?('cut ')
    cut = action.split(' ').last.to_i
    deck = deck.rotate(cut)
  else
    puts "UNKNOWN ACTION: #{action}"
  end
end

# Part 1
puts deck.find_index(2019)


# Part 2
END_INDEX = 2020
DECK_SIZE = 119_315_717_514_047 # Prime
SHUFFLE_TIMES = 101_741_582_076_661 # Prime

def inverse(stride, deck_size)
  stride.times do |times_around|
    div, mod = (deck_size * times_around + 1).divmod(stride)
    return div if mod == 0
  end

  0
end

a, b = [1, 0]
actions.each do |action|
  if action[:action] == :reverse
    a *= -1
    b *= -1
    b -= 1
  elsif action[:action] == :stride
    a *= action[:stride]
    b *= action[:stride]
  elsif action[:action] == :cut
    b -= action[:cut]
  end
end

ia, ib = [1, 0]
actions.reverse.each do |action|
  if action[:action] == :reverse
    ia *= -1
    ib *= -1
    ib -= 1
  elsif action[:action] == :stride
    inverse = inverse(action[:stride], DECK_SIZE)
    ia *= inverse
    ib *= inverse
  elsif action[:action] == :cut
    ib += action[:cut]
  end
end

a = a % DECK_SIZE
b = b % DECK_SIZE
ia = ia % DECK_SIZE
ib = ib % DECK_SIZE

def get_next_index(index, a, b)
  (a * index + b) % DECK_SIZE
end

remainder = SHUFFLE_TIMES
pwr_of_2 = 2
index = END_INDEX
sindex = 64586600795606

in2020 = get_next_index(2020, ia, ib)
puts in2020
puts get_next_index(in2020, a, b)

while remainder > 0
  if remainder % pwr_of_2 > 0
    sindex = get_next_index(sindex, a, b)
    index = get_next_index(index, ia, ib)
    remainder -= remainder % pwr_of_2
  end

  pwr_of_2 *= 2
  ib = ((ia * ib) + ib) % DECK_SIZE
  ia = (ia * ia) % DECK_SIZE
  b = ((a * b) + b) % DECK_SIZE
  a = (a * a) % DECK_SIZE
end
puts index
puts sindex

__END__
deal into new stack
deal with increment 25
cut -5919
deal with increment 56
deal into new stack
deal with increment 20
deal into new stack
deal with increment 53
cut 3262
deal with increment 63
cut 3298
deal into new stack
cut -4753
deal with increment 57
deal into new stack
cut 9882
deal with increment 42
deal into new stack
deal with increment 40
cut 2630
deal with increment 32
cut 1393
deal with increment 74
cut 2724
deal with increment 23
cut -3747
deal into new stack
cut 864
deal with increment 61
deal into new stack
cut -4200
deal with increment 72
cut -7634
deal with increment 32
deal into new stack
cut 6793
deal with increment 38
cut 7167
deal with increment 10
cut -9724
deal into new stack
cut 6047
deal with increment 37
cut 7947
deal with increment 63
deal into new stack
deal with increment 9
cut -9399
deal with increment 26
cut 1154
deal with increment 74
deal into new stack
cut 3670
deal with increment 45
cut 3109
deal with increment 64
cut -7956
deal with increment 39
deal into new stack
deal with increment 61
cut -9763
deal with increment 20
cut 4580
deal with increment 30
deal into new stack
deal with increment 62
deal into new stack
cut -997
deal with increment 54
cut -1085
deal into new stack
cut -9264
deal into new stack
deal with increment 11
cut 6041
deal with increment 9
deal into new stack
cut 5795
deal with increment 26
cut 5980
deal with increment 38
cut 1962
deal with increment 25
cut -565
deal with increment 45
cut 9490
deal with increment 21
cut -3936
deal with increment 64
deal into new stack
cut -7067
deal with increment 75
cut -3975
deal with increment 29
deal into new stack
cut -7770
deal into new stack
deal with increment 12
cut 8647
deal with increment 49
