#!/usr/bin/env python3
from sys import argv
from subprocess import run, Popen, DEVNULL
from os.path import isfile, splitext
from typing import Callable, Iterable
from opener import get_mime_type


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
    for editor in editors:
        if editor is not None:
            editor.wait()
        else:
            continue


def open_with(nvim_files, emacs_files):
    nvim = open_with_nvim(nvim_files)
    emacs = open_with_emacs(emacs_files)
    return nvim, emacs


def split_condition(file: str) -> bool:
    if isfile(file):
        return get_mime_type(file) in {
            "text/org",
            "text/x-emacs-lisp",
            "text/x-scheme",
        }
    else:
        return splitext(file)[1] in {".org", ".el", ".scm", ".ss"}


def split_into2(group: Iterable, predicate: Callable) -> tuple[list, list]:
    true_group: list = []
    false_group: list = []
    for elem in group:
        (true_group if predicate(elem) else false_group).append(elem)
    return true_group, false_group


def edit(files=argv[1:]):
    if files == []:
        run(["nvim"])
    else:
        emacs_files, nvim_files = split_into2(files, split_condition)
        nvim, emacs = open_with(nvim_files, emacs_files)
        wait_editor(nvim, emacs)


if __name__ == "__main__":
    edit()
