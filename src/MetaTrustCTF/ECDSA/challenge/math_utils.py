#!/usr/bin/python3
from sympy.core.numbers import igcdex


def safe_div(x: int, y: int):
    """
    Computes x / y and fails if x is not divisible by y.
    """
    assert isinstance(x, int) and isinstance(y, int)
    assert y != 0
    assert x % y == 0, f"{x} is not divisible by {y}."
    return x // y


def div_ceil(x, y):
    assert isinstance(x, int) and isinstance(y, int)
    return -((-x) // y)


def div_mod(n, m, p):
    """
    Finds a nonnegative integer x < p such that (m * x) % p == n.
    """
    a, b, c = igcdex(m, p)
    assert c == 1
    return (n * a) % p
