#!/usr/bin/env python3


def fib(n):
    if n == 0:
        return 0
    elif n == 1:
        return 1
    else:
        return fib(n - 1) + fib(n - 2)


def fib_upto(n):
    if n > 0:
        fib_upto(n - 1)
    print(n, fib(n))


fib_upto(10)
