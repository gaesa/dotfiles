#!/usr/bin/env python3
from subprocess import run
from sys import argv

from my_utils.iters import is_empty


def edit(files: list[str] | tuple[str, ...] | None = None):
    files = argv[1:] if files is None else files
    if is_empty(files):
        run(["/usr/bin/nvim"])
    else:
        run(["/usr/bin/nvim", "-o", *files, "-c", "wincmd H"])


if __name__ == "__main__":
    edit()
