from collections import deque
from collections.abc import Sequence
from itertools import chain, filterfalse, groupby, islice, tee
from typing import Any, Callable, Iterable, Iterator, TypeVar

_T = TypeVar("_T")
_U = TypeVar("_U")


def nwise(iterable: Iterable[_T], n: int = 2) -> Iterator[tuple[_T, ...]]:
    """
    Generate overlapping n-tuples from an iterable.

    :param iterable: An iterable from which to produce n-tuples.
    :param n: The size of the n-tuple. Defaults to 2.
    :return: An iterator over n-tuples of consecutive elements.

    Example:
        >>> list(nwise([1, 2, 3, 4], 2))
        [(1, 2), (2, 3), (3, 4)]
        >>> list(nwise("abcde", 3))
        [('a', 'b', 'c'), ('b', 'c', 'd'), ('c', 'd', 'e')]
    """
    if n < 1:
        raise ValueError("Integer 'n' must be at least 1")
    elif n < 7:
        iterators = tee(iterable, n)
        for i, it in enumerate(iterators):
            for_each(
                lambda _: next(it, None),
                range(i),
            )
        return zip(*iterators)
    else:
        it = iter(iterable)
        window = deque(islice(it, n - 1), maxlen=n)
        for ele in it:
            window.append(ele)
            yield tuple(window)


def tree_map(
    operation: Callable[[Any], Any],
    iterable: Iterable[Any],
    inner_iterable_type: Callable[[Any], Iterable[Any]] | None = None,
) -> Iterator[Any]:
    """
    Applies a given operation to each element in a nested iterable structure.
    If an element is a sub-iterable, the function is called recursively on that element.

    Parameters:
        `operation`: A function to be applied to each element in the iterable.
        `iterable`: An iterable iterable to be mapped over.
        `inner_iterable_type`: A function to convert inner iterables, defaults to the type of the outermost iterable.

    Returns:
        An iterator over the transformed iterable.
    """

    def iter(iterable: Iterable[Any]):
        return map(
            (  # `convert_type` eagerly evaluates the inner `map` object
                lambda ele: (
                    convert_type(iter(ele))
                    if isinstance(ele, iterable_type)
                    else operation(ele)
                )
            ),
            iterable,
        )

    if not isinstance(iterable, Iterable):
        raise TypeError("'iterable' should be an instance of Iterable")
    else:
        iterable_type = type(iterable)
        convert_type = (
            iterable_type if inner_iterable_type is None else inner_iterable_type
        )
        return iter(iterable)


def flatmap(
    operation: Callable[[_T], Iterable[_U]], iterable: Iterable[_T]
) -> Iterator[_U]:
    """
    Applies a function to each element in an iterable then flattens the result.

    Parameters:
        `operation`: A function to be applied to each element in the iterable.
        `iterable`: An iterable iterable to be mapped over.

    Returns:
        An iterator over the flattened and transformed iterable.
    """
    return chain.from_iterable(map(operation, iterable))


def for_each(operation: Callable[[_T], Any], iterable: Iterable[_T]) -> None:
    """Like `map`, but doesn't construct an iterator."""
    for ele in iterable:
        operation(ele)


def star_foreach(
    operation: Callable[[_T, ...], Any],  # pyright: ignore
    iterable: Iterable[Iterable[_T]],
) -> None:
    """Like `starmap`, but doesn't construct an iterator."""
    for ele in iterable:
        operation(*ele)


def partition(
    predicate: Callable[[_T], bool], iterable: Iterable[_T], lazy: bool = False
) -> tuple[Iterator[_T], Iterator[_T]] | tuple[list[_T], list[_T]]:
    """Use a predicate to partition entries into true entries and false entries"""
    if lazy:
        it1, it2 = tee(iterable)
        return filter(
            predicate, it1  # pyright: ignore [reportGeneralTypeIssues]
        ), filterfalse(
            predicate, it2  # pyright: ignore [reportGeneralTypeIssues]
        )
    else:
        it1, it2 = [], []
        for ele in iterable:
            (it1 if predicate(ele) else it2).append(ele)
        return it1, it2


def get_differences(a: Iterable[_T], b: Iterable[_T]) -> tuple[set[_T], set[_T]]:
    """
    Compute the differences between two iterables.

    Parameters:
        `a (Iterable[T])`: The first iterable.
        `b (Iterable[T])`: The second iterable.

    Returns:
        `tuple[set[T], set[T]]`: A tuple of two sets. The first set is `a - b`, and the second set is `b - a`.
    """

    a = a if isinstance(a, (set, frozenset, dict)) else frozenset(a)
    b = b if isinstance(b, (set, frozenset, dict)) else frozenset(b)
    a_minus_b, b_minus_a = set(), set()

    if isinstance(a, dict):
        if isinstance(b, dict):
            union = {**a, **b}
        else:
            union = b.union(a)
    else:
        union = a.union(b)

    for ele in union:
        if ele in a:
            if ele not in b:
                a_minus_b.add(ele)
        else:
            b_minus_a.add(ele)

    return a_minus_b, b_minus_a


def fallback(*args: Callable[[], Any]) -> Any:
    """Returns the first non-empty or non-None element in an iterable, the laziness is implemented by function"""

    def cond(var):
        return len(var) != 0 if isinstance(var, Sequence) else var is not None

    for arg in args:
        value = arg()
        if cond(value):
            return value
    return None


def cond(*args: tuple[Callable[[], bool], Callable[[], Any]]) -> Any:
    for condition, action in args:
        if condition():
            return action()
    return object()


def skip_first(iterable: Iterable[_T], k: int = 1) -> Iterator[_T]:
    """Like `seq[k:]` or `itertools.islice(seq, k, None)`, but more time-efficient"""
    if k < 0:
        raise ValueError("'k' must be greater than or equal to zero")
    else:
        it = iter(iterable)
        for_each(lambda _: next(it, None), range(k))
        return it


def first(iterable: Iterable[_T], k: int = 1) -> Iterator[_T]:
    """An alias for `itertools.islice(seq, k)`"""
    if k < 0:
        raise ValueError("'k' must be greater than or equal to zero")
    else:
        return islice(iterable, k)


def skip_last(iterable: Iterable[_T], k: int = 1) -> Iterator[_T]:
    if k < 0:
        raise ValueError("'k' must be greater than or equal to zero")
    else:
        return iter(tuple(iterable)[:-k])


def last(iterable: Iterable[_T], k: int = 1) -> Iterator[_T]:
    if k < 0:
        raise ValueError("'k' must be greater than or equal to zero")
    else:
        return iter(tuple(iterable)[-k:])


def all_equal(iterable: Iterable[_T]) -> bool:
    g = groupby(iterable)
    return (next(g, True) is True) or (next(g, True) is True)


def begin(*args: Callable[[], Any]) -> Any:
    """
    Executes a sequence of functions in order and returns the result of the last function.

    Each argument should be a function that takes no arguments. Functions are called in the order they are given.
    """
    value = None
    for arg in args:
        value = arg()
    return value


def begin1(*args: Callable[[], Any]) -> Any:
    """
    Executes a sequence of functions in order and returns the result of the first function.

    Each argument should be a function that takes no arguments. Functions are called in the order they are given.
    """
    value = args[0]()
    for_each(lambda arg: arg(), args[1:])
    return value


async def abegin(*args: Callable[[], Any]) -> Any:
    """async version of `begin`"""
    value = None
    for arg in args:
        value = await arg()
    return value


def natsort(strings: Iterable[str]) -> list[str]:
    import re

    def key(s: str) -> tuple[int | str, ...]:
        split_list: list[str] = re.split(r"(\d+)", s)
        split_list.pop(0) if split_list[0] == "" else None
        split_list.pop(-1) if len(split_list) > 0 and split_list[-1] == "" else None
        return tuple(
            map(
                lambda text: int(text) if text.isdigit() else text,
                split_list,
            )
        )

    return sorted(strings, key=key)
