#!/usr/bin/env python3
from sys import argv
from subprocess import run


def edit(files: list[str] | tuple[str, ...] = argv[1:]):
    if files == []:
        run(["/usr/bin/nvim"])
    else:
        run(["/usr/bin/nvim", "-o", *files, "-c", "wincmd H"])


if __name__ == "__main__":
    edit()
