from collections.abc import Sequence
from itertools import chain, filterfalse, tee
from typing import Any, Callable, Iterable, Iterator, TypeVar

_T = TypeVar("_T")
_U = TypeVar("_U")


def unique(sequence: Iterable[_T]) -> dict[_T, None]:
    return dict.fromkeys(sequence)


def nwise(sequence: Iterable[_T], n: int = 2) -> Iterator[tuple[_T, ...]]:
    """
    Generate overlapping n-tuples from a sequence.

    :param sequence: An iterable from which to produce n-tuples.
    :param n: The size of the window (n-tuple) to use when generating the
              sequence. Defaults to 2.
    :return: An iterator over n-tuples of consecutive elements.

    Example:
        >>> list(nwise([1, 2, 3, 4], 2))
        [(1, 2), (2, 3), (3, 4)]
        >>> list(nwise("abcde", 3))
        [('a', 'b', 'c'), ('b', 'c', 'd'), ('c', 'd', 'e')]
    """
    iterables = tee(sequence, n)
    for i, sequence in enumerate(iterables):
        for_each(
            lambda _: next(sequence, None),  # pyright: ignore [reportGeneralTypeIssues]
            range(i),
        )
    return zip(*iterables)


def tree_map(
    operation: Callable[[Any], Any],
    sequence: Iterable[Any],
    inner_sequence_type: Callable[[Any], Iterable[Any]] | None = None,
) -> Iterator[Any]:
    """
    Applies a given operation to each element in a nested sequence structure.
    If an element is a sub-sequence, the function is called recursively on that element.

    Parameters:
        `operation`: A function to be applied to each element in the sequence.
        `sequence`: An iterable sequence to be mapped over.
        `inner_sequence_type`: A function to convert inner sequences, defaults to the type of the outermost sequence.

    Returns:
        An iterator over the transformed sequence.
    """

    def iter(sequence: Iterable[Any]):
        return map(
            (  # `convert_type` eagerly evaluates the inner `map` object
                lambda ele: convert_type(iter(ele))
                if isinstance(ele, sequence_type)
                else operation(ele)
            ),
            sequence,
        )

    if not isinstance(sequence, Iterable):
        raise TypeError("`sequence` should be an instance of Iterable")
    else:
        sequence_type = type(sequence)
        convert_type = (
            sequence_type if inner_sequence_type is None else inner_sequence_type
        )
        return iter(sequence)


def flatmap(
    operation: Callable[[_T], Iterable[_U]], sequence: Iterable[_T]
) -> Iterator[_U]:
    """
    Applies a function to each element in a sequence then flattens the result.

    Parameters:
        `operation`: A function to be applied to each element in the sequence.
        `sequence`: An iterable sequence to be mapped over.

    Returns:
        An iterator over the flattened and transformed sequence.
    """
    return chain.from_iterable(map(operation, sequence))


def for_each(operation: Callable[[_T], Any], sequence: Iterable[_T]) -> None:
    "Like `map`, but doesn't construct a sequence."
    for ele in sequence:
        operation(ele)


def partition(
    predicate: Callable[[_T], bool], iterable: Iterable[_T], lazy: bool = False
) -> tuple[Iterator[_T], Iterator[_T]] | tuple[list[_T], list[_T]]:
    "Use a predicate to partition entries into true entries and false entries"
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
    """Returns the first non-empty or non-None element in a sequence, the laziness is implemented by function"""

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
    """
    async version of `begin`
    """
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
