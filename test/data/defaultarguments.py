#!/usr/bin/env python3


def increment(number, by=1, mul=2):
    result = mul*(number + by)
    print(mul, "* (", number, "+", by, ") =", result)
    return result


print(increment(5, 3))
print(increment(8))
