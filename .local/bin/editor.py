#!/usr/bin/env python3
from os.path import splitext
from subprocess import DEVNULL, Popen, run
from sys import argv

from my_utils.seq import for_each, is_empty, partition, skip_first


def open_with_nvim(files: list[str]):
    if not is_empty(files):
        p = Popen(["nvim", "-o", *files, "-c", "wincmd H"])
        return p
    else:
        return


def open_with_emacs(files: list[str], allow_empty: bool = False):
    len_files = len(files)
    if len_files == 0 and (not allow_empty):
        return
    else:
        if len_files == 0 and allow_empty:
            sexp = "(call-interactively #'+workspace/delete)"
        else:
            sexp = (
                "(progn (call-interactively #'+workspace/delete)"
                f'      (find-file "{files[0]}") '
            )
            if len_files == 1:
                sexp += ")"
            else:
                sexp += (
                    f'(split-window-right) (other-window 1) (find-file "{files[1]}") '
                )
                for file in skip_first(files, 2):
                    sexp += (
                        f'(split-window-below) (other-window 1) (find-file "{file}") '
                    )
                sexp += "(other-window 1))"
        p = Popen(
            [
                "/usr/bin/emacsclient",
                "-c",
                "--eval",
                sexp,
                "--alternate-editor=",
            ],
            stdout=DEVNULL,
        )
        return p


def wait_editor(*editors: Popen[bytes] | None):
    for_each(
        lambda editor: editor.wait(),  # pyright: ignore [reportOptionalMemberAccess]
        filter(lambda editor: editor is not None, editors),
    )


def open_with(nvim_files: list[str], emacs_files: list[str]):
    nvim = open_with_nvim(nvim_files)
    emacs = open_with_emacs(emacs_files)
    return nvim, emacs


def split_cond(
    file: str, _extensions={".org", ".el", ".scm", ".ss", ".rkt", ".fnl"}
) -> bool:
    return splitext(file)[1] in _extensions


def edit(files: list[str] | tuple[str, ...] | None = None):
    files = argv[1:] if files is None else files
    if is_empty(files):
        run(["/usr/bin/nvim"])
    else:
        emacs_files, nvim_files = partition(split_cond, files)
        nvim, emacs = open_with(
            nvim_files, emacs_files  # pyright: ignore [reportArgumentType]
        )
        wait_editor(nvim, emacs)


if __name__ == "__main__":
    edit()
