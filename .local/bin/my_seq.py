from collections.abc import Sequence
from functools import reduce  # fold-left
from typing import Callable, Iterable, Any


def append(lst: list[Any], elem: Any) -> list[Any]:
    """
    Returns the updated list with the appended element.
    This function is more efficient than using the `+` or list unpacking
    (using the `*` operator within square brackets) to concatenate lists.
    """
    lst.append(elem)
    return lst


def flatmap(apply: Callable, seq: Iterable) -> list | tuple:
    return reduce(lambda x, y: x + y, map(apply, seq))


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


def fallback(*args: Callable[[], Any]) -> Any:
    """Returns the first non-empty or non-None element in a sequence, the laziness is implemented by function"""

    def is_seq(var):
        return isinstance(var, Sequence)

    def cond(var):
        return len(var) != 0 if is_seq(var) else var is not None

    for arg in args:
        value = arg()
        if cond(value):
            return value
        else:
            continue


def cond(*args: tuple[Callable[[], bool], Callable[[], Any]]) -> Any:
    for condition, action in args:
        if condition():
            return action()
        else:
            continue


def begin(*args: Callable[[], Any]) -> Any:
    """
    Executes a sequence of functions in order and returns the result of the last function.

    Each argument should be a function that takes no arguments. Functions are called in the order they are given.
    """
    value = None
    for arg in args:
        value = arg()
    return value
