import itertools
from collections import deque
from collections.abc import Callable, Collection, Iterable, Iterator, Sized
from typing import Any, Literal, TypeVar, overload

T = TypeVar("T")
U = TypeVar("U")


def count(iterable: Iterable[T]) -> int:
    counter = itertools.count()
    deque(zip(iterable, counter), maxlen=0)
    return next(counter)


def is_empty(iterable: Iterable[Any]) -> bool:
    return (len(iterable) if isinstance(iterable, Sized) else count(iterable)) == 0


def startswith(collection: Collection[T], iterable: Iterable[T]) -> bool:
    len_coll = len(collection)
    if len_coll == 0:
        return count(iterable) == 0
    else:
        if isinstance(iterable, Sized):  # assume sized iterable is not lazy
            len_iter = len(iterable)
            it = iterable
        else:
            it = tuple(iterable)
            len_iter = len(it)
        len_diff = len_coll - len_iter

        if len_diff < 0:
            return False
        else:
            return (
                next(
                    filter(
                        lambda eles: eles[0] != eles[1],
                        zip(collection, it),
                    ),
                    True,
                )
                is True
            )


def endswith(collection: Collection[T], iterable: Iterable[T]) -> bool:
    from my_utils.stream import Stream

    len_coll = len(collection)
    if len_coll == 0:
        return count(iterable) == 0
    else:
        if isinstance(iterable, Sized):  # assume sized iterable is not lazy
            len_iter = len(iterable)
            it = iterable
        else:
            it = tuple(iterable)
            len_iter = len(it)
        len_diff = len_coll - len_iter

        if len_diff < 0:
            return False
        else:
            return (
                Stream(collection)
                .drop_first(len_diff)
                .zip(it)
                .all_match(lambda eles: eles[0] == eles[1])
            )


def for_each(operation: Callable[[T], Any], iterable: Iterable[T]) -> None:
    """Like `map`, but doesn't construct an iterator."""
    for ele in iterable:
        operation(ele)


def star_foreach(
    operation: Callable[[T, ...], Any],  # pyright: ignore
    iterable: Iterable[tuple[T, ...]],
) -> None:
    """Like `starmap`, but doesn't construct an iterator."""
    for ele in iterable:
        operation(*ele)


def flatmap(
    operation: Callable[[T], Iterable[U]], iterable: Iterable[T]
) -> Iterator[U]:
    """
    Applies a function to each element in the iterable then flattens the result.

    Parameters:
        `operation`: A function to be applied to each element in the iterable.

    Returns:
        An iterator over the flattened and transformed iterable.
    """
    return itertools.chain.from_iterable(map(operation, iterable))


def tree_map(
    operation: Callable[[Any], Any],
    iterable: Iterable[Any],
    inner_iterable_type: Callable[[Any], Iterable[Any]] | None = None,
) -> Iterator[Any]:
    """
    Applies a given operation to each element in a nested stream structure.
    If an element is a sub-iterable, the function is called recursively on that element.

    Parameters:
        `operation`: A function to be applied to each element in the stream.
        `inner_iterable_type`: A function to convert inner iterables, defaults to Stream.

    Returns:
        A Stream over the transformed stream.
    """
    if not isinstance(iterable, Iterable):
        raise TypeError("'iterable' should be an instance of Iterable")
    else:

        def iteration(iterable: Iterable[Any]) -> Iterator[Any]:
            return map(
                (  # `convert_type` eagerly evaluates the inner `map` object
                    lambda ele: (
                        convert_type(iteration(ele))
                        if isinstance(ele, iterable_type)
                        else operation(ele)
                    )
                ),
                iterable,
            )

        iterable_type = type(iterable)
        convert_type = (
            iterable_type if inner_iterable_type is None else inner_iterable_type
        )
        return iteration(iterable)


def drop_first(iterable: Iterable[T], k: int = 1) -> Iterator[T]:
    """Like `list[k:]` or `itertools.islice(seq, k, None)`, but more time-efficient"""
    if k < 0:
        raise ValueError("'k' must be greater than or equal to zero")
    else:
        it = iter(iterable)
        deque(zip(itertools.repeat(None, k), it), maxlen=0)
        return it


@overload
def partition(
    predicate: Callable[[T], bool], iterable: Iterable[T], lazy: Literal[True] = True
) -> tuple[Iterator[T], Iterator[T]]: ...


@overload
def partition(
    predicate: Callable[[T], bool], iterable: Iterable[T], lazy: Literal[False] = False
) -> tuple[list[T], list[T]]: ...


def partition(
    predicate: Callable[[T], bool], iterable: Iterable[T], lazy: bool = True
) -> tuple[Iterator[T], Iterator[T]] | tuple[list[T], list[T]]:
    if lazy:
        it1, it2 = itertools.tee(iterable)
        return filter(predicate, it1), itertools.filterfalse(predicate, it2)
    else:
        lst1, lst2 = [], []
        for ele in iterable:
            (lst1 if predicate(ele) else lst2).append(ele)
        return lst1, lst2


def diff(a: Iterable[T], b: Iterable[T]) -> tuple[set[T], set[T], set[T]]:
    """
    Compute the differences and intersection between two iterables.

    It is usually less efficient than using python's built-in set operations
    (like `&` for intersection and `-` for difference), which are highly optimized.

    Parameters:
        `a (Iterable[T])`: The first iterable.
        `b (Iterable[T])`: The second iterable.

    Returns:
        `tuple[set[T], set[T]]`: A tuple of two sets.
        The first set is `a - b`, the second set is `b - a`, the third set is `a & b`.
    """

    a = a if isinstance(a, (set, frozenset, dict)) else frozenset(a)
    b = b if isinstance(b, (set, frozenset, dict)) else frozenset(b)
    a_minus_b, b_minus_a, intersection = set(), set(), set()

    for ele in itertools.chain(a, b):
        if ele in a:
            if ele not in b:
                a_minus_b.add(ele)
            else:
                intersection.add(ele)
        else:
            b_minus_a.add(ele)

    return a_minus_b, b_minus_a, intersection


def fallback(*args: Callable[[], Any]) -> Any:
    """
    Returns the first non-empty or non-None element in an iterable,
    the laziness is implemented by function
    """

    from my_utils.stream import NoSuchElementException, Stream

    def is_not_empty_or_none(arg: Any):
        return (not is_empty(arg)) if isinstance(arg, Iterable) else arg is not None

    try:
        return Stream(args).map(lambda arg: arg()).find(is_not_empty_or_none)
    except NoSuchElementException:
        return None


def cond(*args: tuple[Callable[[], bool], Callable[[], Any]]) -> Any:
    for condition, action in args:
        if condition():
            return action()
    return object()


def begin(*args: Callable[[], Any]) -> Any:
    """
    Executes a sequence of functions in order and returns the result of the last function.

    Each argument should be a function that takes no arguments.
    Functions are called in the order they are given.
    """
    value = None
    for arg in args:
        value = arg()
    return value


def begin1(*args: Callable[[], Any]) -> Any:
    """
    Executes a sequence of functions in order and returns the result of the first function.

    Each argument should be a function that takes no arguments.
    Functions are called in the order they are given.
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


def natsort(s: str) -> tuple[int | str, ...]:
    import re

    split_list: list[str] = re.split(r"(\d+)", s)
    split_list.pop(0) if split_list[0] == "" else None
    split_list.pop(-1) if len(split_list) > 0 and split_list[-1] == "" else None
    return tuple(
        map(
            lambda text: int(text) if text.isdigit() else text,
            split_list,
        )
    )
