from collections import Counter

data = open("dec04.input").readlines()

num_valid = 0
for line in data:
    words = set()
    any_dupes = False
    for word in line.split():
        if word in words:
            any_dupes = True
            break
        words.add(word)
    if not any_dupes:
        num_valid += 1

print("Part 1:", num_valid)

num_valid = 0
for line in data:
    if not any([cnt > 1 for cnt in Counter(line.split()).values()]):
        num_valid += 1

print("Part 1 [Alternate]:", num_valid)

num_valid = 0
for line in data:
    words = set()
    any_dupes = False
    for word in line.split():
        word = "".join(sorted(list(word)))
        if word in words:
            any_dupes = True
            break
        words.add(word)
    if not any_dupes:
        num_valid += 1

print("Part 2:", num_valid)
