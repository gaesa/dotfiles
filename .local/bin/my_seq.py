from collections.abc import Sequence
from functools import reduce  # fold-left
from typing import Callable, Iterable


def append(lst: list, elem) -> list:
    """
    Returns the updated list with the appended element.
    This function is more efficient than using the `+` or list unpacking
    (using the `*` operator within square brackets) to concatenate lists.
    """
    lst.append(elem)
    return lst


def flatmap(apply: Callable, lst: list) -> list:
    return reduce(lambda x, y: x + y, map(apply, lst))


def for_each(apply: Callable, seq: Iterable) -> None:
    "Like `map`, but doesn't construct a sequence."
    for ele in seq:
        apply(ele)


def split(predicate: Callable, group: Iterable) -> tuple[list, list]:
    true_group, false_group = [], []
    for_each(
        lambda ele: (true_group if predicate(ele) else false_group).append(ele), group
    )
    return true_group, false_group


def fallback(seq: Iterable):
    """Returns the first non-empty or non-None element in a sequence, although it's not lazy enough"""

    def is_seq(var):
        return isinstance(var, Sequence)

    def cond(var):
        seq_cond = is_seq(var)
        return len(var) != 0 if seq_cond else var is not None

    for item in seq:
        if cond(item):
            return item
