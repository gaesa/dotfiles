"""A simple typed stream lib mainly inspired by Java."""

from __future__ import annotations

import itertools
import operator
from collections import Counter, deque
from collections.abc import Callable, Collection, Hashable, Iterable, Iterator, Sized
from functools import reduce
from typing import Any, Generic, Literal, Protocol, TypeVar, final, overload

T = TypeVar("T")
U1 = TypeVar("U1")
U2 = TypeVar("U2")


class Comparable(Protocol):
    def __lt__(self, __other) -> bool: ...
    def __eq__(self, __other: object) -> bool: ...


H = TypeVar("H", bound=Hashable)
C = TypeVar("C", bound=Comparable)


class NoSuchElementException(Exception):
    """Exception to be raised when unable to get required elements."""

    pass


class _MissingDefault:
    """Used to generate a global single unique variable with specific type."""

    pass


@final
class __StrictClassMethodOfStream(type):
    """
    A workaround to make class-only methods.

    See also:
        https://stackoverflow.com/questions/42322936/how-do-i-disallow-a-classmethod-from-being-called-on-an-instance
        https://discuss.python.org/t/feature-proposal-a-new-classmethod-decorator-that-only-allows-calling-from-the-class-type/32984
        https://docs.python.org/3/library/functions.html#classmethod
        https://docs.python.org/3/library/typing.html#typing.ClassVar
    """

    def of(cls, *elements: T) -> Stream[T]:
        return cls(elements)

    @overload
    def range(cls, __stop: int) -> Stream[int]: ...
    @overload
    def range(cls, __start: int, __stop: None, step: int = 1) -> Stream[int]: ...
    @overload
    def range(cls, __start: int, __stop: int, step: int = 1) -> Stream[int]: ...

    def range(
        cls,
        __start: int,
        __stop: int | type[_MissingDefault] | None = _MissingDefault,
        step: int = 1,
    ) -> Stream[int]:
        # `builtins.range` doesn't support `None` `stop` unlike `itertools.islice`
        if __stop is _MissingDefault:
            return cls(range(__start))
        elif __stop is None:
            return cls(itertools.count(__start, step))
        else:
            return cls(
                range(__start, __stop, step)  # pyright: ignore [reportArgumentType]
            )

    @overload
    def repeat(cls, obj: T) -> Stream[T]: ...
    @overload
    def repeat(cls, obj: T, times: int) -> Stream[T]: ...

    def repeat(
        cls, obj: T, times: int | type[_MissingDefault] = _MissingDefault
    ) -> Stream[T]:
        """
        Same as `Stream.generate(lambda: object).limit(times)` when times is not `None`,
        when times is `None`, it works same as `Stream.generate(lambda: object)`.
        """
        return cls(
            itertools.repeat(obj, *((times,) if times is not _MissingDefault else ()))
        )

    @overload
    def generate(cls, operation: Callable[[], T]) -> Stream[T]: ...
    @overload
    def generate(cls, operation: Callable[[], T], stop_value: T) -> Stream[T]: ...

    def generate(
        cls,
        operation: Callable[[], T],
        stop_value: T | _MissingDefault = _MissingDefault,
    ) -> Stream[T]:
        def generator(operation: Callable[[], T]) -> Iterator[T]:
            while True:
                yield operation()

        return (
            cls(generator(operation))
            if stop_value is _MissingDefault
            else cls(iter(operation, stop_value))
        )

    def iterate(cls, seed: T, operation: Callable[[T], T]) -> Stream[T]:
        def generator(seed: T, operation: Callable[[T], T]) -> Iterator[T]:
            acc = seed
            yield acc
            while True:
                acc = operation(acc)
                yield acc

        return cls(generator(seed, operation))


@final
class Stream(Generic[T], metaclass=__StrictClassMethodOfStream):
    def __init__(self, iterable: Iterable[T] = ()) -> None:
        self.__iterable = iter(iterable)

    def __iter__(self) -> Iterator[T]:
        return self.__iterable

    def __str__(self) -> str:
        return f"<Stream object at {hex(id(self))}>"

    def cycle(self) -> Stream[T]:
        return Stream(itertools.cycle(self.__iterable))

    def accumulate(self) -> Stream[T]:
        return Stream(itertools.accumulate(self.__iterable))

    # Wait python 3.12 release on Arch
    # def batched(self, n: int) -> Stream[T]:
    #     return Stream(itertools.batched(self.__iterable, n))

    def map(self, operation: Callable[[T], U1]) -> Stream[U1]:
        return Stream(map(operation, self.__iterable))

    def starmap(
        self, operation: Callable[[T, ...], U1]  # pyright: ignore
    ) -> Stream[U1]:  # Iterable[tuple[T, ...]] -> Stream[U]
        return Stream(
            itertools.starmap(
                operation, self.__iterable  # pyright: ignore [reportArgumentType]
            )
        )

    def filter(self, predicate: Callable[[T], bool]) -> Stream[T]:
        return Stream(filter(predicate, self.__iterable))

    def filterfalse(self, predicate: Callable[[T], bool]) -> Stream[T]:
        return Stream(itertools.filterfalse(predicate, self.__iterable))

    @overload
    def reduce(self, operation: Callable[[T, T], T]) -> T: ...
    @overload
    def reduce(self, operation: Callable[[T, T], T], init: T) -> T: ...

    # The following two overloads can't be inferred properly by pyright
    @overload
    def reduce(  # pyright: ignore [reportOverlappingOverload]
        self, operation: Callable[[U1, T], U1]
    ) -> U1: ...

    @overload
    def reduce(  # pyright: ignore [reportOverlappingOverload]
        self, operation: Callable[[U1, T], U1], init: U1
    ) -> U1: ...

    def reduce(
        self,
        operation: Callable[[U1, T], U1],
        init: U1 | _MissingDefault = _MissingDefault,
    ) -> U1:
        return reduce(
            operation,  # pyright: ignore [reportCallIssue,reportArgumentType]
            self.__iterable,
            *((init,) if init is not _MissingDefault else ()),
        )

    @overload
    def group_by(self, key: None = None) -> Stream[tuple[T, Stream[T]]]: ...
    @overload
    def group_by(self, key: Callable[[T], U1]) -> Stream[tuple[U1, Stream[T]]]: ...
    def group_by(
        self, key: Callable[[T], U1] | None = None
    ) -> Stream[tuple[U1, Stream[T]]] | Stream[tuple[T, Stream[T]]]:
        return Stream(
            map(
                lambda pair: (pair[0], Stream(pair[1])),
                itertools.groupby(self.__iterable, key),
            )  # pyright: ignore [reportReturnType]
        )

    @overload
    def partition(
        self, predicate: Callable[[T], bool], lazy: Literal[True] = True
    ) -> tuple[Stream[T], Stream[T]]: ...

    @overload
    def partition(
        self, predicate: Callable[[T], bool], lazy: Literal[False] = False
    ) -> tuple[list[T], list[T]]: ...

    def partition(
        self, predicate: Callable[[T], bool], lazy: bool = True
    ) -> tuple[Stream[T], Stream[T]] | tuple[list[T], list[T]]:
        if lazy:
            it1, it2 = itertools.tee(self.__iterable)
            return Stream(filter(predicate, it1)), Stream(
                itertools.filterfalse(predicate, it2)
            )
        else:
            lst1, lst2 = [], []
            for ele in self.__iterable:
                (lst1 if predicate(ele) else lst2).append(ele)
            return lst1, lst2

    @overload
    def zip(
        self, iterable: Iterable[T], strict: bool = False
    ) -> Stream[tuple[T, T]]: ...
    @overload
    def zip(
        self, iterable: Iterable[T], *iterables: Iterable[T], strict: bool = False
    ) -> Stream[tuple[T, ...]]: ...
    def zip(  # pyright: ignore [reportInconsistentOverload]
        self, *iterables: Iterable[T], strict: bool = False
    ) -> Stream[tuple[T, ...]]:
        return Stream(zip(self.__iterable, *iterables, strict=strict))

    @overload
    def zip_longest(
        self, iterable: Iterable[T], fillvalue: Any = None
    ) -> Stream[tuple[T, T]]: ...
    @overload
    def zip_longest(
        self, iterable: Iterable[T], *iterables: Iterable[T], fillvalue: Any = None
    ) -> Stream[tuple[T, ...]]: ...
    def zip_longest(  # pyright: ignore [reportInconsistentOverload]
        self, *iterables: Iterable[T], fillvalue: Any = None
    ) -> Stream[tuple[T, ...]]:
        return Stream(itertools.zip_longest(self.__iterable, *iterables, fillvalue))

    def enumerate(self, start: int = 0) -> Stream[tuple[int, T]]:
        return Stream(enumerate(self.__iterable, start=start))

    def concat(
        self, *iterables: Iterable[T]
    ) -> Stream[T]:  # tuple[Iterable[T], ...] -> Stream[T]
        return Stream(itertools.chain(self.__iterable, *iterables))

    def pre_concat(self, *iterables: Iterable[T]) -> Stream[T]:
        return Stream(itertools.chain(*iterables, self.__iterable))

    # Hack: this is a workaround for covariant
    # No idea how to extract `T` from `U = Iterable[T]`
    # In typescript we can achieve this by:
    # type Inner<T> = T extends Iterable<infer U> ? U : never;
    # type U = Iterable<string>;
    # type T = Inner<U>; // T is now string
    @overload
    def flatten(self: Stream[list[U1]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[tuple[U1, ...]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[set[U1]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[frozenset[U1]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[dict[U1, U2]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[deque[U1]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[Stream[U1]]) -> Stream[U1]: ...
    @overload
    def flatten(self: Stream[Iterator[U1]]) -> Stream[U1]: ...

    # @overload
    # def flatten(  # this doesn't work since `T` is not covariant
    #     self: Stream[Iterable[U1]],
    # ) -> Stream[U1]: ...

    # @overload  # a fallback to suppresss type errors for custom iterable
    # def flatten(self) -> Stream[Any]: ...

    def flatten(  # pyright: ignore [reportInconsistentOverload]
        self: Stream[Iterable[U1]],
    ) -> Stream[U1]:
        return Stream(itertools.chain.from_iterable(self.__iterable))

    def flatmap(self, operation: Callable[[T], Iterable[U1]]) -> Stream[U1]:
        """
        Applies a function to each element in the stream then flattens the result.

        Parameters:
            `operation`: A function to be applied to each element in the stream.

        Returns:
            A new stream over the flattened and transformed stream.
        """
        return Stream(itertools.chain.from_iterable(map(operation, self.__iterable)))

    def compress(self, selectors: Iterable[T]) -> Stream[T]:
        return Stream(itertools.compress(self.__iterable, selectors))

    def product(
        self, *iterables: Iterable[T], repeat: int = 1
    ) -> Stream[tuple[T, ...]]:
        return Stream(itertools.product(self.__iterable, *iterables, repeat=repeat))

    def permutations(self, r: int | None = None) -> Stream[tuple[T, ...]]:
        return Stream(itertools.permutations(self.__iterable, r=r))

    def combinations(self, r: int) -> Stream[tuple[T, ...]]:
        return Stream(itertools.combinations(self.__iterable, r=r))

    def combinations_with_replacement(self, r: int) -> Stream[tuple[T, ...]]:
        return Stream(itertools.combinations_with_replacement(self.__iterable, r=r))

    def limit(self, max_size: int) -> Stream[T]:
        """
        Returns a new stream consisting of same elements as original,
        truncated to be no longer than `k` in length.
        """
        return Stream(itertools.islice(self.__iterable, max_size))

    def drop_first(self, k: int = 1) -> Stream[T]:
        """Like `list[k:]` or `itertools.islice(seq, k, None)`, but more time-efficient"""
        if k < 0:
            raise ValueError("'k' must be greater than or equal to zero")
        else:
            it = iter(self.__iterable)
            deque(zip(itertools.repeat(None, k), it), maxlen=0)
            return Stream(it)

    def take_first(self, k: int = 1) -> Stream[T]:
        """An alias for `itertools.islice(seq, k)`"""
        if k < 0:
            raise ValueError("'k' must be greater than or equal to zero")
        else:
            return Stream(itertools.islice(self.__iterable, k))

    def drop_last(self, k: int = 1) -> Stream[T]:
        """
        Returns a stream that skips the last `k` elements from the original stream.
        Use it with caution as it can fully consume your iterator.

        Parameters:
            `k`: Number of elements to skip from the end. Default is 1.

        Returns:
            `Stream[T]`: Stream with the specified elements skipped.

        Raises:
            `ValueError`: If `k` is negative.

        Example:
            >>> Stream([1, 2, 3, 4, 5]).drop_last(2).to_list()
            [1, 2, 3]
        """

        def generator(iterable: Iterable[T], k: int) -> Iterator[T]:
            if k < 0:
                raise ValueError("'k' must be greater than or equal to zero")
            elif k == 0:
                return iter(iterable)
            else:
                it, window = iter(iterable), deque(maxlen=k)
                try:
                    for _ in itertools.repeat(None, k):
                        window.append(next(it))
                    for ele in it:
                        yield window.popleft()
                        window.append(ele)
                except StopIteration:
                    return iter(())

        return Stream(generator(self.__iterable, k))

    def take_last(self, k: int = 1) -> Stream[T]:
        """
        Returns a stream containing the last `k` elements from the original stream.
        Use it with caution as it can fully consume your iterator.

        Parameters:
            `k`: Number of elements to include from the end. Default is 1.

        Returns:
            `Stream[T]`: Stream with the specified last elements.

        Raises:
            `ValueError`: If `k` is negative.

        Example:
            >>> Stream([1, 2, 3, 4, 5]).take_last(2).to_list()
            [4, 5]
        """
        if k < 0:
            raise ValueError("'k' must be greater than or equal to zero")
        elif k == 0:
            return Stream()  # pyright: ignore [reportReturnType]
        else:
            return Stream(deque(self.__iterable, maxlen=k))

    def take_while(self, predicate: Callable[[T], bool]) -> Stream[T]:
        return Stream(itertools.takewhile(predicate, self.__iterable))

    def drop_while(self, predicate: Callable[[T], bool]) -> Stream[T]:
        return Stream(itertools.dropwhile(predicate, self.__iterable))

    def tee(self, n: int = 2) -> tuple[Stream[T], ...]:
        return tuple(map(Stream, itertools.tee(self.__iterable, n)))

    @overload
    def slice(self, __stop: int) -> Stream[T]: ...
    @overload
    def slice(self, __start: int, __stop: None = None, step: int = 1) -> Stream[T]: ...
    @overload
    def slice(self, __start: int, __stop: int, step: int = 1) -> Stream[T]: ...

    def slice(
        self, __start: int, __stop: int | None = None, step: int = 1
    ) -> Stream[T]:
        return Stream(itertools.islice(self.__iterable, __start, __stop, step))

    def pairwise(self) -> Stream[tuple[T, ...]]:
        return Stream(itertools.pairwise(self.__iterable))

    def nwise(self, n: int = 2) -> Stream[tuple[T, ...]]:
        """
        Generate overlapping n-tuples from the stream.

        Parameters:
            n: The size of the n-tuple. Defaults to 2.

        Returns: A stream over n-tuples of consecutive elements.

        Example:
            >>> Stream([1, 2, 3, 4]).nwise(2).to_list()
            [(1, 2), (2, 3), (3, 4)]
            >>> Stream("abcde").nwise(3).to_list()
            [('a', 'b', 'c'), ('b', 'c', 'd'), ('c', 'd', 'e')]
        """

        def generator(iterable: Iterable[T], n: int = 2) -> Iterator[tuple[T, ...]]:
            if n < 1:
                raise ValueError("Integer 'n' must be at least 1")
            elif n < 7:
                iterators = itertools.tee(iterable, n)
                for i, it in enumerate(iterators):
                    deque(zip(itertools.repeat(None, i), it), maxlen=0)
                return zip(*iterators)
            else:
                it = iter(iterable)
                window = deque(itertools.islice(it, n - 1), maxlen=n)
                for ele in it:
                    window.append(ele)
                    yield tuple(window)

        return Stream(generator(self.__iterable, n))

    def peek(self, operation: Callable[[T], None]) -> Stream[T]:
        def generator(
            operation: Callable[[T], None], iterable: Iterable[T]
        ) -> Iterator[T]:
            for ele in iterable:
                operation(ele)
                yield ele

        return Stream(generator(operation, self.__iterable))

    @overload
    def sorted(
        self: Stream[C], key: None = None, reverse: bool = False
    ) -> Stream[T]: ...
    @overload
    def sorted(self, key: Callable[[T], C], reverse: bool = False) -> Stream[T]: ...

    def sorted(
        self,
        key: Callable[[T], C] | None = None,
        reverse: bool = False,
    ) -> Stream[T]:
        return Stream(
            sorted(
                self.__iterable,
                key=key,  # pyright: ignore [reportCallIssue,reportArgumentType]
                reverse=reverse,
            )
        )

    @overload
    def unique_everseen(self: Stream[H], key: None = None) -> Stream[T]: ...
    @overload
    def unique_everseen(self, key: Callable[[T], H]) -> Stream[T]: ...

    def unique_everseen(self, key: Callable[[T], H] | None = None) -> Stream[T]:
        def generator(
            iterable: Iterable[T], key: Callable[[T], H] | None = None
        ) -> Iterator[T]:
            visited: set[H] = set()
            trans: Callable[[T], T | H] = (
                (lambda ele: key(ele)) if key is not None else (lambda ele: ele)
            )

            for ele in iterable:
                k = trans(ele)
                if k not in visited:
                    # if `key` is None and T is not Hashable,
                    # `TypeError: non-hashable type` would be raised
                    visited.add(k)  # pyright: ignore [reportArgumentType]
                    yield ele

        return Stream(generator(self.__iterable, key=key))

    def unique_justseen(self, key: Callable[[T], Any] | None = None) -> Stream[T]:
        return Stream(
            map(
                next,
                map(operator.itemgetter(1), itertools.groupby(self.__iterable, key)),
            )
            if key is not None
            else map(operator.itemgetter(0), itertools.groupby(self.__iterable))
        )

    def for_each(self, operation: Callable[[T], Any]) -> None:
        """Like `map`, but doesn't construct an iterator."""
        for_each(operation, self.__iterable)

    def star_foreach(
        self, operation: Callable[[T, ...], Any]  # pyright: ignore
    ) -> None:
        """Like `starmap`, but doesn't construct an iterator."""
        star_foreach(operation, self.__iterable)  # pyright: ignore [reportArgumentType]

    def count(self) -> int:
        return count(self.__iterable)

    def is_empty(self) -> bool:
        """
        Checks if the iterable is empty.

        Returns:
            True if the iterable is empty, otherwise False.
        """
        return is_empty(self.__iterable)

    def sum(self: Stream[int] | Stream[float], start: int = 0) -> T:
        return sum(self.__iterable, start)  # pyright: ignore [reportReturnType]

    @overload
    def min(self: Stream[C], key: None = None) -> T: ...
    @overload
    def min(self, key: Callable[[T], C]) -> T: ...

    def min(self, key: Callable[[T], C] | None = None) -> T:
        return min(
            self.__iterable,
            key=key,  # pyright: ignore [reportCallIssue,reportArgumentType]
        )

    @overload
    def max(self: Stream[C], key: None = None) -> T: ...
    @overload
    def max(self, key: Callable[[T], C]) -> T: ...

    def max(self, key: Callable[[T], C] | None = None) -> T:
        return max(
            self.__iterable,
            key=key,  # pyright: ignore [reportCallIssue,reportArgumentType]
        )

    def any_match(self, predicate: Callable[[T], bool]) -> bool:
        """
        Checks if at least one element in the stream satisfies the given predicate.

        Parameters:
            predicate: The function used to test each element.

        Returns:
            True if at least one element satisfies the predicate, otherwise False.
        """
        return any(map(predicate, self.__iterable))

    def all_match(self, predicate: Callable[[T], bool]) -> bool:
        """
        Checks if all elements in the stream satisfy the given predicate.

        Parameters:
            predicate: The function used to test each element.

        Returns:
            True if all elements satisfy the predicate, otherwise False.
        """
        return all(map(predicate, self.__iterable))

    def all_equal(self) -> bool:
        g = itertools.groupby(self.__iterable)
        return (next(g, True) is True) or (next(g, True) is True)

    def find(self, predicate: Callable[[T], bool]) -> T:
        """
        Finds the first element in the stream that satisfies the given predicate.

        Parameters:
            predicate: The function used to test each element.

        Returns:
            The first element that satisfies the predicate.

        Raises:
            NoSuchElementException: If no values in the stream satisfy the predicate.
        """
        try:
            return next(filter(predicate, self.__iterable))
        except StopIteration:
            raise NoSuchElementException(
                "No values in the iterable satisfy the predicate"
            )

    def counter(self: Stream[H]) -> Counter[H]:
        return Counter(self.__iterable)

    def repeated_elements(self: Stream[H]) -> Stream[H]:
        return Stream(ele for ele, count in self.counter().items() if count > 1)

    def to_list(self) -> list[T]:
        return list(self.__iterable)

    def to_tuple(self) -> tuple[T, ...]:
        return tuple(self.__iterable)

    def to_set(self) -> set[T]:
        return set(self.__iterable)

    def to_frozenset(self) -> frozenset[T]:
        return frozenset(self.__iterable)

    def to_dict(self: Stream[tuple[U1, U2]]) -> dict[U1, U2]:
        return dict(self.__iterable)

    def to_dict_fromkeys(self, value: U1 = None) -> dict[T, U1]:
        return dict.fromkeys(self.__iterable, value)

    def join_to_str(self: Stream[str], sep="") -> str:
        return sep.join(self.__iterable)

    def join_to_bytes(self: Stream[bytes], sep=b"") -> bytes:
        return sep.join(self.__iterable)

    def collect(self, operation: Callable[[Iterable[T]], U1]) -> U1:
        return operation(self.__iterable)

    def collects(self, operation: Callable[[Iterable[T]], Iterable[U1]]) -> Stream[U1]:
        return Stream(operation(self.__iterable))


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
