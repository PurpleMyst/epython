#!/usr/bin/env python3


def map(f, xs):
    i = 0
    l = len(xs)

    while i < l:
        xs[i] = f(xs[i])
        i += 1

xs = [1, 2, 3, 4, 5]
print(xs)
map(lambda x: x / 2, xs)
print(xs)
