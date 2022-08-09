data = open("dec06.input").readlines()

blocks_in_blanks = [int(s) for s in data[0].split("\t")]

seen = set([tuple(blocks_in_blanks)])
part1 = 0
part2 = 0
num_blanks = len(blocks_in_blanks)
first_dup = None

while True:
    max_index = 0
    max_value = 0

    for i, val in enumerate(blocks_in_blanks):
        if val > max_value:
            max_index = i
            max_value = val

    to_reallocate = blocks_in_blanks[max_index]
    blocks_in_blanks[max_index] = 0
    index = max_index

    while to_reallocate > 0:
        index += 1
        if index == num_blanks:
            index = 0

        blocks_in_blanks[index] += 1
        to_reallocate -= 1

    if first_dup is None:
        part1 += 1
    else:
        part2 += 1

    blocks_in_blanks_tup = tuple(blocks_in_blanks)
    if first_dup is None:
        if blocks_in_blanks_tup in seen:
            first_dup = blocks_in_blanks_tup
        seen.add(blocks_in_blanks_tup)
    else:
        if blocks_in_blanks_tup == first_dup:
            break

print("Part 1:", part1)
print("Part 2:", part2)
