from os import getcwd, chdir, stat
import json
from typing import Callable
from stat import S_IMODE


def json_read(file: str):
    with open(file, "r") as f:
        return json.load(f)


def json_write(file: str, data: list | dict, mode: str = "w") -> None:
    with open(file, mode) as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def get_permission(file: str):
    return S_IMODE(stat(file).st_mode)


def run_chdir(dir: str):
    def decorator(old_fn: Callable) -> Callable:
        def new_fn(*args, **kwargs):
            cwd = getcwd()
            chdir(dir)
            value = old_fn(*args, **kwargs)
            chdir(cwd)
            return value

        return new_fn

    return decorator


def run_chdir_async(dir: str):
    def decorator(old_fn: Callable) -> Callable:
        async def new_fn(*args, **kwargs):
            cwd = getcwd()
            chdir(dir)
            value = await old_fn(*args, **kwargs)
            chdir(cwd)
            return value

        return new_fn

    return decorator