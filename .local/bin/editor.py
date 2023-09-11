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


def open_with_emacs(files):
    if files == []:
        return
    else:
        len_files = len(files)
        sexp = f'(progn (find-file "{files[0]}") '
        if len_files == 1:
            sexp += ")"
        else:
            sexp += f'(split-window-right) (other-window 1) (find-file "{files[1]}") '
            for file in files[2:]:
                sexp += f'(split-window-below) (other-window 1) (find-file "{file}") '
            sexp += "(other-window 1))"
        p = Popen(
            [
                "emacsclient",
                "--alternate-editor=",
                "-c",
                "--eval",
                sexp,
            ],
            stdout=DEVNULL,
        )
        return p


def wait_editor(*editors: Popen[bytes] | None):
    for_each(
        lambda editor: editor.wait(),
        filter(lambda editor: editor is not None, editors),
    )


def open_with(nvim_files, emacs_files):
    nvim = open_with_nvim(nvim_files)
    emacs = open_with_emacs(emacs_files)
    return nvim, emacs


def split_cond(file: str) -> bool:
    return splitext(file)[1] in {".org", ".el", ".scm", ".ss", ".rkt"}


def edit(files=argv[1:]):
    if files == []:
        run(["nvim"])
    else:
        emacs_files, nvim_files = split(split_cond, files)
        nvim, emacs = open_with(nvim_files, emacs_files)
        wait_editor(nvim, emacs)


if __name__ == "__main__":
    edit()
