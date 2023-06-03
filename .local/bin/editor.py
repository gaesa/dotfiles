#!/usr/bin/env python3
from sys import argv
from subprocess import run


def edit(files=argv[1:]):
    if files == []:
        run(["nvim"])
    else:
        run(["nvim", "-o", *files, "-c", "wincmd H"])


if __name__ == "__main__":
    edit()
