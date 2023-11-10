from collections.abc import Sequence
from itertools import chain, tee, filterfalse
from typing import Callable, Iterable, Iterator, Any, TypeVar

_T = TypeVar("_T")


def flatmap(
    operation: Callable[[_T], Iterable[Any]], sequence: Iterable[_T]
) -> Iterator[Any]:
    return chain.from_iterable(map(operation, sequence))


def for_each(operation: Callable[[_T], Any], sequence: Iterable[_T]) -> None:
    "Like `map`, but doesn't construct a sequence."
    for ele in sequence:
        operation(ele)


def partition(predicate: Callable[[Any], bool], iterable: Iterable[Any]):
    "Use a predicate to partition entries into true entries and false entries"
    it1, it2 = (
        tee(iterable) if isinstance(iterable, (Iterator, range)) else (iterable,) * 2
    )
    return filter(predicate, it1), filterfalse(predicate, it2)


def fallback(*args: Callable[[], Any]) -> Any:
    """Returns the first non-empty or non-None element in a sequence, the laziness is implemented by function"""

    def cond(var):
        return len(var) != 0 if isinstance(var, Sequence) else var is not None

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
