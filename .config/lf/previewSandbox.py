#!/usr/bin/env python3
from subprocess import run
from os import getenv, makedirs
from os.path import expanduser, join, isdir, realpath
from sys import argv
from typing import Iterable, Literal
from my_utils.seq import fallback, flatmap


def get_cmd(CURRENT_FILE: str, XDG: tuple[str, str, str]) -> list[str]:
    opt_table: dict[Literal["ro", "dev"] | None, str] = {
        "ro": "--ro-bind",
        "dev": "--dev-bind",
        None: "--bind",
    }

    def bind(opt_abbr: Literal["ro", "dev"] | None, dirs: list[str]) -> Iterable[str]:
        opt = [opt_table[opt_abbr]]
        return flatmap(lambda dir: opt + [dir] * 2, dirs)

    def bind_thumb() -> Iterable[str]:
        path = join(XDG_CACHE_HOME, "lf_thumb")
        None if isdir(path) else makedirs(path)
        return bind(None, [path])

    def bind_pycache() -> Iterable[str]:
        prefix = join(XDG_CACHE_HOME, "python")
        dir_lf = join(prefix, join(XDG_CONFIG_HOME, "lf")[1:])
        dir_utils = join(prefix, join(XDG_DATA_HOME, "python/lib/my_utils")[1:])
        dir_usr = join(prefix, "usr")
        return bind(None, [dir_lf, dir_utils, dir_usr])

    XDG_CACHE_HOME, XDG_CONFIG_HOME, XDG_DATA_HOME = XDG
    preview = join(XDG_CONFIG_HOME, "lf/preview.py")
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
                join(XDG_CONFIG_HOME, "lf/opener.py"),
                join(XDG_CONFIG_HOME, "lf/thumb.py"),
                join(XDG_CONFIG_HOME, "bat/config"),
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
    HOME = expanduser("~")
    XDG_DATA_HOME: str = fallback(
        lambda: getenv("XDG_DATA_HOME"), lambda: join(HOME, ".local/share")
    )
    XDG_CACHE_HOME: str = fallback(
        lambda: getenv("XDG_CACHE_HOME"), lambda: join(HOME, ".cache")
    )
    XDG_CONFIG_HOME: str = fallback(
        lambda: getenv("XDG_CONFIG_HOME"), lambda: join(HOME, ".config")
    )
    TMPDIR = getenv("TMPDIR", "/tmp")

    with open(join(TMPDIR, "lf.log"), "w") as log_file:
        argv[1] = realpath(argv[1], strict=True)
        process = run(
            get_cmd(argv[1], (XDG_CACHE_HOME, XDG_CONFIG_HOME, XDG_DATA_HOME)),
            stderr=log_file,
        )
    raise SystemExit(process.returncode)
    # the intention is to clear the last displayed image,
    # maybe it's a bad way used by lf to know if it's essential to refresh screen


if __name__ == "__main__":
    main()
