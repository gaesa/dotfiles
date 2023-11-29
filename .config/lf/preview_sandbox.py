#!/usr/bin/env python3
from subprocess import run
from pathlib import Path
from sys import argv
from typing import Iterable, Literal
from tempfile import gettempdir
from my_utils.seq import flatmap
from my_utils.dirs import Xdg


def get_cmd(CURRENT_FILE: str, XDG: tuple[Path, Path, Path]) -> list[str | Path]:
    opt_table: dict[Literal["ro", "dev"] | None, str] = {
        "ro": "--ro-bind",
        "dev": "--dev-bind",
        None: "--bind",
    }

    def bind(
        opt_abbr: Literal["ro", "dev"] | None, dirs: tuple[str | Path, ...]
    ) -> Iterable[str | Path]:
        opt = opt_table[opt_abbr]
        return flatmap(lambda dir: (opt, dir, dir), dirs)

    def bind_thumb() -> Iterable[str | Path]:
        path = Path(XDG_CACHE_HOME, "lf_thumb")
        None if path.is_dir() else path.mkdir(parents=True, exist_ok=True)
        return bind(None, (path,))

    def bind_pycache() -> Iterable[str | Path]:
        prefix = Path(XDG_CACHE_HOME, "python")
        dir_lf = Path(prefix, *Path(XDG_CONFIG_HOME, "lf").parts[1:])
        dir_utils = Path(prefix, *Path(XDG_DATA_HOME, "python/lib/my_utils").parts[1:])
        dir_usr = Path(prefix, "usr")
        return bind(None, (dir_lf, dir_utils, dir_usr))

    XDG_CACHE_HOME, XDG_CONFIG_HOME, XDG_DATA_HOME = XDG
    preview = Path(XDG_CONFIG_HOME, "lf/preview.py")
    return [
        "/usr/bin/bwrap",
        *bind("ro", ("/usr/bin", "/usr/share", "/usr/lib", "/usr/lib64")),
        *("--symlink", "/usr/bin", "/bin"),
        *("--symlink", "/usr/lib64", "/lib64"),
        *("--proc", "/proc"),
        *bind(
            "ro",
            (
                preview,
                Path(XDG_CONFIG_HOME, "lf/opener.py"),
                Path(XDG_CONFIG_HOME, "lf/thumb.py"),
                Path(XDG_CONFIG_HOME, "bat/config"),
                Path(XDG_DATA_HOME, "python/lib/my_utils/os.py"),
                CURRENT_FILE,
            ),
        ),
        *bind("dev", ("/dev/tty", "/dev/null", "/dev/shm")),
        *bind_thumb(),
        *bind_pycache(),
        "--unshare-all",
        "--die-with-parent",
        preview,
        *argv[1:],
    ]


def main():
    XDG_DATA_HOME = Xdg.user_data_path()
    XDG_CACHE_HOME = Xdg.user_cache_path()
    XDG_CONFIG_HOME = Xdg.user_config_path()
    TMPDIR = gettempdir()

    with open(Path(TMPDIR, "lf.log"), "w") as log_file:
        argv[1] = str(Path(argv[1]).resolve(strict=True))
        process = run(
            get_cmd(argv[1], (XDG_CACHE_HOME, XDG_CONFIG_HOME, XDG_DATA_HOME)),
            stderr=log_file,
        )
    raise SystemExit(process.returncode)
    # the intention is to clear the last displayed image,
    # maybe it's a bad way used by lf to know if it's essential to refresh screen


if __name__ == "__main__":
    main()
