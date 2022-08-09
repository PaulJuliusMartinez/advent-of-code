data = open("dec05.input").readlines()

jumps = [int(line.strip()) for line in data]

index = 0
num_steps = 0

while 0 <= index < len(jumps):
    delta = jumps[index]
    jumps[index] += 1
    index += delta
    num_steps += 1

print("Part 1:", num_steps)

jumps = [int(line.strip()) for line in data]

index = 0
num_steps = 0

while 0 <= index < len(jumps):
    delta = jumps[index]
    if delta >= 3:
        jumps[index] -= 1
    else:
        jumps[index] += 1
    index += delta
    num_steps += 1

print("Part 2:", num_steps)
