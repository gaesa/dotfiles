from typing import Callable
from functools import wraps


def after(post_fn: Callable, is_async: bool = False):
    def decorator(orig_fn: Callable) -> Callable:
        if is_async:

            @wraps(orig_fn)
            async def new_fn(  # pyright: ignore [reportGeneralTypeIssues]
                *args, **kwargs
            ):
                value = await orig_fn(*args, **kwargs)
                await post_fn()
                return value

        else:

            @wraps(orig_fn)
            def new_fn(*args, **kwargs):
                value = orig_fn(*args, **kwargs)
                post_fn()
                return value

        return new_fn

    return decorator


def before(pre_fn: Callable, is_async: bool = False):
    def decorator(orig_fn: Callable) -> Callable:
        if is_async:

            @wraps(orig_fn)
            async def new_fn(  # pyright: ignore [reportGeneralTypeIssues]
                *args, **kwargs
            ):
                await pre_fn()
                return await orig_fn(*args, **kwargs)

        else:

            @wraps(orig_fn)
            def new_fn(*args, **kwargs):
                pre_fn()
                return orig_fn(*args, **kwargs)

        return new_fn

    return decorator


def filter_return(filter_fn: Callable):
    def decorator(orig_fn: Callable) -> Callable:
        return wraps(orig_fn)(
            lambda *args, **kwargs: filter_fn(orig_fn(*args, **kwargs))
        )

    return decorator


def cache_single_value(orig_fn: Callable):
    def new_fn(*args, **kwargs):
        value = orig_fn(*args, **kwargs)
        container[0] = lambda *_, **__: value
        return value

    container = [new_fn]
    return wraps(orig_fn)(lambda *args, **kwargs: container[0](*args, **kwargs))


def debug_fn(orig_fn: Callable, name: str = ""):
    @wraps(orig_fn)
    def new_fn(*args, **kwargs):
        print("args:", args, "kwargs:", kwargs) if name == "" else print(
            f"name: {name}", f"args: {args}", f"kwargs: {kwargs}", sep="\n"
        )
        value = orig_fn(*args, **kwargs)
        print("returned value:", value, end="\n" * 2)
        return value

    return new_fn
