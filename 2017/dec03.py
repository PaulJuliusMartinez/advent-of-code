num = int(open("dec03.input").read().strip())

x, y = (0, 0)

dx = None
dy = None
step = 1
total = 1

while True:
    # Step right
    dx = 1
    dy = 0
    if total + step > num:
        break
    else:
        x += dx * step
        y += dy * step
        total += step

    # Step up
    dx = 0
    dy = 1
    if total + step > num:
        break
    else:
        x += dx * step
        y += dy * step
        total += step

    step += 1

    # Step left
    dx = -1
    dy = 0
    if total + step > num:
        break
    else:
        x += dx * step
        y += dy * step
        total += step

    # Step up
    dx = 0
    dy = -1
    if total + step > num:
        break
    else:
        x += dx * step
        y += dy * step
        total += step

    step += 1

remaining = num - total
x += dx * remaining
y += dy * remaining

print("Part 1:", abs(x) + abs(y))


x, y = (0, 0)
dpos_and_checks = [
    ((1, 0), (0, 1)),
    ((0, 1), (-1, 0)),
    ((-1, 0), (0, -1)),
    ((0, -1), (1, 0)),
]

h = { (0, 0): 1 }

dir_index = 0

while h[(x, y)] < num:
    dpos, dcheck = dpos_and_checks[dir_index]
    dx, dy = dpos
    x += dx
    y += dy

    s = 0
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if (dx != 0 or dy != 0) and (x + dx, y + dy) in h:
                s += h[(x + dx, y + dy)]
    h[(x, y)] = s

    cx, cy = dcheck
    if (x + cx, y + cy) not in h:
        dir_index = (dir_index + 1) % 4


print("Part 2:", h[(x, y)])
