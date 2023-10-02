#!/usr/bin/env python3
from sys import argv
from subprocess import run, Popen, DEVNULL
from os.path import splitext
from my_seq import for_each, split


def open_with_nvim(files):
    if files != []:
        p = Popen(["nvim", "-o", *files, "-c", "wincmd H"])
        return p
    else:
        return


def open_with_emacs(files: list[str], allow_empty: bool = False):
    if files == [] and (not allow_empty):
        return
    else:
        len_files = len(files)
        if files == [] and allow_empty:
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
                for file in files[2:]:
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
        lambda editor: editor.wait(),
        filter(lambda editor: editor is not None, editors),
    )


def open_with(nvim_files: list[str], emacs_files: list[str]):
    nvim = open_with_nvim(nvim_files)
    emacs = open_with_emacs(emacs_files)
    return nvim, emacs


def split_cond(file: str) -> bool:
    return splitext(file)[1] in {".org", ".el", ".scm", ".ss", ".rkt", ".fnl"}


def edit(files: list[str] | tuple[str, ...] | None = None):
    files = argv[1:] if files is None else files
    if files == []:
        run(["/usr/bin/nvim"])
    else:
        emacs_files, nvim_files = split(split_cond, files)
        nvim, emacs = open_with(nvim_files, emacs_files)
        wait_editor(nvim, emacs)


if __name__ == "__main__":
    edit()
