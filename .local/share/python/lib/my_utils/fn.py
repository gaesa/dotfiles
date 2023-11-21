from typing import Callable


def after(post_fn: Callable):
    def decorator(old_fn: Callable) -> Callable:
        def new_fn(*args, **kwargs):
            value = old_fn(*args, **kwargs)
            post_fn()
            return value

        return new_fn

    return decorator


def before(pre_fn: Callable):
    def decorator(old_fn: Callable) -> Callable:
        def new_fn(*args, **kwargs):
            pre_fn()
            return old_fn(*args, **kwargs)

        return new_fn

    return decorator


def filter_return(filter_fn: Callable):
    def decorator(old_fn: Callable) -> Callable:
        return lambda *args, **kwargs: filter_fn(old_fn(*args, **kwargs))

    return decorator


def cache_single_value(orig_fn: Callable):
    def new_fn(*args, **kwargs):
        value = orig_fn(*args, **kwargs)
        container[0] = lambda *_, **__: value
        return value

    container = [new_fn]
    return lambda *args, **kwargs: container[0](*args, **kwargs)


def debug_fn(old_fn: Callable, name: str = ""):
    def new_fn(*args, **kwargs):
        print("args:", args, "kwargs:", kwargs) if name == "" else print(
            f"name: {name}", f"args: {args}", f"kwargs: {kwargs}", sep="\n"
        )
        value = old_fn(*args, **kwargs)
        print("returned value:", value, end="\n" * 2)
        return value

    return new_fn
