#!/usr/bin/env python3
from subprocess import run
from os import getenv, makedirs
from os.path import expanduser, join, isdir
from sys import argv
from typing import Literal
from my_seq import flatmap


def get_cmd(CURRENT_FILE: str, HOME: str, TMPDIR: str) -> list[str]:
    opt_table: dict[Literal["ro", "dev"] | None, str] = {
        "ro": "--ro-bind",
        "dev": "--dev-bind",
        None: "--bind",
    }

    def bind(opt_abbr: Literal["ro", "dev"] | None, dirs: list[str]) -> list[str]:
        opt = [opt_table[opt_abbr]]
        return flatmap(lambda dir: opt + [dir] * 2, dirs)

    def bind_thumb() -> list[str]:
        path = join(HOME, ".cache/lf_thumb")
        None if isdir(path) else makedirs(path)
        return bind(None, [path])

    def bind_pycache() -> list[str]:
        dir = join(HOME, ".config/lf/__pycache__")
        return bind(None, [dir]) if isdir(dir) else []

    preview = join(HOME, ".config/lf/preview.py")
    return [
        "/usr/bin/bwrap",
        *bind("ro", ["/usr/bin", "/usr/share", "/usr/lib", "/usr/lib64"]),
        *("--symlink", "/usr/bin", "/bin"),
        *("--symlink", "/usr/lib64", "/lib64"),
        *("--proc", "/proc"),
        *bind(
            "ro",
            [
                preview,
                join(HOME, ".config/lf/opener.py"),
                join(HOME, ".config/lf/thumb.py"),
                join(HOME, ".config/bat/config"),
                join(HOME, ".local/bin/my_os.py"),
                CURRENT_FILE,
            ],
        ),
        *bind("dev", ["/dev/tty", "/dev/null", TMPDIR]),
        *bind_thumb(),
        *bind_pycache(),
        "--unshare-all",
        "--die-with-parent",
        preview,
        *argv[1:],
    ]


def main():
    TMPDIR = getenv("TMPDIR", "/tmp")
    with open(join(TMPDIR, "lf.log"), "w") as log_file:
        process = run(
            get_cmd(argv[1], expanduser("~"), TMPDIR),
            stderr=log_file,
        )
    raise SystemExit(process.returncode)
    # the intention is to clear the last displayed image,
    # maybe it's a bad way used by lf to know if it's essential to refresh screen


if __name__ == "__main__":
    main()
