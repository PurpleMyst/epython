#!/usr/bin/env python3


def foo(x):
    y = x % 2

    print("x:", x)
    print("y:", y)

    if y:
        print("odd")
    else:
        print("even")


foo(7)
foo(8)
foo(13)
foo(10)
