#!/usr/bin/env python3
from subprocess import run
from os import getenv, makedirs
from os.path import expanduser, join, isdir, realpath
from sys import argv
from typing import Iterable, Literal
from my_utils.seq import fallback, flatmap


def get_cmd(CURRENT_FILE: str, HOME: str) -> list[str]:
    opt_table: dict[Literal["ro", "dev"] | None, str] = {
        "ro": "--ro-bind",
        "dev": "--dev-bind",
        None: "--bind",
    }

    def bind(opt_abbr: Literal["ro", "dev"] | None, dirs: list[str]) -> Iterable[str]:
        opt = [opt_table[opt_abbr]]
        return flatmap(lambda dir: opt + [dir] * 2, dirs)

    def bind_thumb() -> Iterable[str]:
        path = join(HOME, ".cache/lf_thumb")
        None if isdir(path) else makedirs(path)
        return bind(None, [path])

    def bind_pycache() -> Iterable[str]:
        prefix = join(HOME, ".cache/python")
        dir_lf = join(prefix, join(HOME, ".config/lf")[1:])
        dir_utils = join(prefix, join(XDG_DATA_HOME, "python/lib/my_utils")[1:])
        dir_usr = join(prefix, "usr")
        return bind(None, [dir_lf, dir_utils, dir_usr])

    preview = join(HOME, ".config/lf/preview.py")
    XDG_DATA_HOME: str = fallback(
        lambda: getenv("XDG_DATA_HOME"), lambda: join(HOME, ".local/share")
    )
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
                join(XDG_DATA_HOME, "python/lib/my_utils/os.py"),
                CURRENT_FILE,
            ],
        ),
        *bind("dev", ["/dev/tty", "/dev/null", "/dev/shm"]),
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
        argv[1] = realpath(argv[1], strict=True)
        process = run(
            get_cmd(argv[1], expanduser("~")),
            stderr=log_file,
        )
    raise SystemExit(process.returncode)
    # the intention is to clear the last displayed image,
    # maybe it's a bad way used by lf to know if it's essential to refresh screen


if __name__ == "__main__":
    main()
