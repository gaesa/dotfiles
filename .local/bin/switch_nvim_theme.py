#!/usr/bin/env python3
from os import environ, listdir, stat as os_stat, remove
from os.path import expanduser, isdir, join
from stat import S_ISSOCK
from pynvim import attach
from sys import argv
from typing import Iterator


def is_socket(file: str):
    try:
        return S_ISSOCK(os_stat(file).st_mode)
    except FileNotFoundError:
        return False


def get_nvim_socket_list() -> Iterator[str]:
    dir = environ["XDG_RUNTIME_DIR"]
    if isdir(dir):
        prefix = "nvim."
        return filter(
            is_socket,
            map(
                lambda file: join(dir, file),
                (filter(lambda file: file.startswith(prefix), listdir(dir))),
            ),
        )
    else:
        raise SystemExit(0)


def main():
    def load_theme(color):
        for path in get_nvim_socket_list():
            try:
                with attach("socket", path=path) as nvim:
                    nvim.vars["mycolor"] = color
                    nvim.lua.vim.cmd({"cmd": cmd, "args": args})
            # neovim may exit unexpectedly
            # but to tell if `OSError` is caused by that is hard
            except OSError as e:
                code = e.errno
                if code in {22, None}:
                    remove(path)
                else:
                    raise

    cmd = "source"
    colors_file = expanduser("~/.config/nvim/plugin/colors.lua")
    args = [colors_file]  # h: vim.cmd()

    if len(argv) < 2:
        load_theme(False)  # to clear mycolor variable
    else:
        color = argv[1]
        if color in {"light", "dark"}:
            load_theme(color)
        else:
            return


if __name__ == "__main__":
    main()
