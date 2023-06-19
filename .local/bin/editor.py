#!/usr/bin/env python3
from sys import argv
from subprocess import run, Popen, DEVNULL
from os.path import splitext


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
                "-nc",
                "--eval",
                sexp,
            ],
            stdout=DEVNULL,
        )
        return p


def wait_editor(editor):
    if editor is not None:
        editor.wait()
    else:
        return


def edit(files=argv[1:]):
    if files == []:
        run(["nvim"])
    else:
        nvim_files = []
        emacs_files = []

        for file in files:
            if splitext(file)[1] in {".org", ".el", ".scm"}:
                emacs_files.append(file)
            else:
                nvim_files.append(file)

        nvim = open_with_nvim(nvim_files)
        emacs = open_with_emacs(emacs_files)

        wait_editor(nvim)
        wait_editor(emacs)


if __name__ == "__main__":
    edit()
