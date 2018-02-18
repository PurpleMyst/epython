#!/usr/bin/env python3


def double(xs):
    i = 0
    l = len(xs)

    while i < l:
        xs[i] = xs[i] * 2
        i += 1


xs = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
print(xs)
double(xs)
print(xs)
