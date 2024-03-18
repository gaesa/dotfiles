#!/usr/bin/env python3
from collections.abc import Iterator
from pathlib import Path
from sys import argv

from pynvim import attach
from xdg import BaseDirectory


def get_nvim_socket_list(XDG_RUNTIME_DIR: Path) -> Iterator[Path]:
    if XDG_RUNTIME_DIR.is_dir():
        prefix = "nvim."
        return filter(
            lambda file: file.name.startswith(prefix) and file.is_socket(),
            Path.iterdir(XDG_RUNTIME_DIR),
        )
    else:
        raise SystemExit(0)


def load_theme(color, socket_list: Iterator[Path]):
    def clean(exception: OSError, code_range: set[int | None]):
        code = exception.errno
        if code in code_range:
            path.unlink()
        else:
            raise

    for path in socket_list:
        try:
            with attach(
                "socket", path=path  # pyright: ignore [reportArgumentType]
            ) as nvim:
                nvim.vars["mycolor"] = color
                args = [str(Path("~/.config/nvim/plugin/colors.lua").expanduser())]
                nvim.lua.vim.cmd({"cmd": "source", "args": args})
        # neovim may exit unexpectedly
        # but to tell if `OSError` is caused by that is hard
        except ConnectionRefusedError as e:
            clean(e, {111})
        except OSError as e:
            clean(e, {22, None})


def main():
    XDG_RUNTIME_DIR = Path(BaseDirectory.get_runtime_dir())
    socket_list = get_nvim_socket_list(XDG_RUNTIME_DIR)

    if len(argv) < 2:
        load_theme(False, socket_list)  # to reset `mycolor` variable
    else:
        color = argv[1]
        if color in {"light", "dark"}:
            load_theme(color, socket_list)
        else:
            return


if __name__ == "__main__":
    main()
