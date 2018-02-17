#!/usr/bin/env python3

xs = []
x = 0
while x < 10:
    xs = xs + [x * x]
    x += 1

y = 3
print("The square for", y, "is", xs[y])
