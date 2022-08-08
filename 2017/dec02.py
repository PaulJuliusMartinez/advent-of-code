data = open("dec02.input").read().strip()
lines = data.split("\n")
digits = [[int(num) for num in line.split()] for line in lines]

cksum = 0
for row in digits:
    cksum += max(row) - min(row)

print("Part 1:", cksum)


cksum = 0
for row in digits:
    found = False
    for (start, num) in enumerate(row):
        for other in row[start + 1:]:
            larger = max(num, other)
            smaller = min(num, other)
            if larger % smaller == 0:
                cksum += larger // smaller
                found = True
                break

        if found:
            break

print("Part 2:", cksum)
