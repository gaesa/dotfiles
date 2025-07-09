from collections.abc import Callable
from functools import wraps
from typing import Any


def after(post_fn: Callable[[], Any], is_async: bool = False):
    def decorator[**P, T](orig_fn: Callable[P, T]) -> Callable[P, T]:
        if is_async:

            @wraps(orig_fn)
            async def new_fn(  # pyright: ignore [reportRedeclaration]
                *args, **kwargs
            ) -> T:
                value = await orig_fn(  # pyright: ignore [reportGeneralTypeIssues]
                    *args, **kwargs
                )
                await post_fn()
                return value

        else:

            @wraps(orig_fn)
            def new_fn(*args, **kwargs) -> T:
                value = orig_fn(*args, **kwargs)
                post_fn()
                return value

        return new_fn  # pyright: ignore [reportReturnType]

    return decorator


def before(pre_fn: Callable[[], Any], is_async: bool = False):
    def decorator[**P, T](orig_fn: Callable[P, T]) -> Callable[P, T]:
        if is_async:

            @wraps(orig_fn)
            async def new_fn(  # pyright: ignore [reportRedeclaration]
                *args, **kwargs
            ) -> T:
                await pre_fn()
                return await orig_fn(  # pyright: ignore [reportGeneralTypeIssues]
                    *args, **kwargs
                )

        else:

            @wraps(orig_fn)
            def new_fn(*args, **kwargs) -> T:
                pre_fn()
                return orig_fn(*args, **kwargs)

        return new_fn  # pyright: ignore [reportReturnType]

    return decorator


def filter_return[T, U](filter_fn: Callable[[T], U]):
    def decorator[**P](orig_fn: Callable[P, T]) -> Callable[P, T]:
        @wraps(orig_fn)
        def new_fn(*args, **kwargs) -> U:
            return filter_fn(orig_fn(*args, **kwargs))

        return new_fn  # pyright: ignore [reportReturnType]

    return decorator


def cache_single_value[**P, T](orig_fn: Callable[P, T]):
    def new_fn(*args, **kwargs) -> T:
        value = orig_fn(*args, **kwargs)
        container[0] = lambda *_, **__: value
        return value

    container = [new_fn]
    return wraps(orig_fn)(lambda *args, **kwargs: container[0](*args, **kwargs))


def debug_fn[**P, T](orig_fn: Callable[P, T], name: str = ""):
    @wraps(orig_fn)
    def new_fn(*args, **kwargs) -> T:
        if name == "":
            print("args:", args, "kwargs:", kwargs)
        else:
            print(f"name: {name}", f"args: {args}", f"kwargs: {kwargs}", sep="\n")
        value = orig_fn(*args, **kwargs)
        print("returned value:", value, end="\n" * 2)
        return value

    return new_fn


class CannotInstantiateError(Exception):
    """Raised when trying to instantiate a non-instantiable class"""

    pass


def non_instantiable[Class: type](cls: Class) -> Class:
    def __init__(_):
        raise CannotInstantiateError(f"Cannot instantiate '{cls.__name__}'")

    cls.__init__ = __init__  # pyright: ignore [reportAttributeAccessIssue]

    return cls


def let_in[T, U](val: T, fn: Callable[[T], U]) -> U:
    return fn(val)


def drop(_: Any) -> None:
    return None
