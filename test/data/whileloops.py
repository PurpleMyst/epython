#!/usr/bin/env python3


def sqrt(n):
    x = 0

    while x * x < n:
        x += 1

    return x


print(sqrt(2))
print(sqrt(64))
print(sqrt(65))
