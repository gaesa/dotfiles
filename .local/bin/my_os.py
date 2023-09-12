from os import getcwd, chdir
import json
from typing import Callable


def json_read(file: str) -> list | dict:
    with open(file, "r") as f:
        return json.load(f)


def json_write(file: str, data: list | dict, mode: str = "w") -> None:
    with open(file, mode) as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


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
