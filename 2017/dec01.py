data = open("dec01.input").read().rstrip()

total = 0
chars = list(data)
last = chars[-1]

for ch in chars:
    if ch == last:
        total += int(ch)
    last = ch

print("Part 1:", total)

total = 0
length = len(chars)
offset = length // 2

for (i, ch) in enumerate(chars):
    half = chars[(i + offset) % length]
    if ch == half:
        total += int(ch)

print("Part 2:", total)
