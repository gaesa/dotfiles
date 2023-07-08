#!/usr/bin/env python3
from subprocess import run


def main():
    with open("/dev/tty", "w") as tty:
        run(
            [
                "kitten",
                "icat",
                "--stdin",
                "no",
                "--transfer-mode",
                "file",
                "--clear",
            ],
            check=True,
            stdout=tty,
        )


if __name__ == "__main__":
    main()
