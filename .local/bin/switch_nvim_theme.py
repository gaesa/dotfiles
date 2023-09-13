#!/usr/bin/env python3
from os import environ, stat as os_stat, remove, listdir, chdir
from os.path import isdir
from stat import S_ISSOCK
from pynvim import attach
from sys import argv
from typing import Iterator


def is_socket(file: str):
    try:
        return S_ISSOCK(os_stat(file).st_mode)
    except FileNotFoundError:
        return False


def get_nvim_socket_list(XDG_RUNTIME_DIR) -> Iterator[str]:
    if isdir(XDG_RUNTIME_DIR):
        prefix = "nvim."
        return (
            filter(
                lambda file: file.startswith(prefix) and is_socket(file),
                listdir(),
            ),
        )[0]
    else:
        raise SystemExit(0)


def load_theme(color, socket_list: Iterator[str]):
    def clean(exception: OSError, code_range: set[int | None]):
        code = exception.errno
        if code in code_range:
            remove(path)
        else:
            raise

    for path in socket_list:
        try:
            with attach("socket", path=path) as nvim:
                nvim.vars["mycolor"] = color
                lua_exp = "require('plugins.colors')[1].init()"
                nvim.lua.vim.cmd({"cmd": "lua", "args": [lua_exp]})
        # neovim may exit unexpectedly
        # but to tell if `OSError` is caused by that is hard
        except ConnectionRefusedError as e:
            clean(e, {111})
        except OSError as e:
            clean(e, {22, None})


def main():
    XDG_RUNTIME_DIR = environ["XDG_RUNTIME_DIR"]
    chdir(XDG_RUNTIME_DIR)
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
