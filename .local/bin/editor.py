#!/usr/bin/env python3
from sys import argv
from subprocess import run


def edit(files: list[str] | tuple[str, ...] | None = None):
    files = argv[1:] if files is None else files
    if files == () or files == []:
        run(["/usr/bin/nvim"])
    else:
        run(["/usr/bin/nvim", "-o", *files, "-c", "wincmd H"])


if __name__ == "__main__":
    edit()
