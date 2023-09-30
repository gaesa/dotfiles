#!/usr/bin/env python3
from sys import argv
from typing import Callable
from opener import get_mime_type
from subprocess import run
import thumb
from os.path import getsize


def audio_has_cover(audio):
    from pymediainfo import MediaInfo

    media_info = MediaInfo.parse(audio)
    d = media_info.tracks[0].to_data()  # pyright: ignore [reportGeneralTypeIssues]
    if "cover" in d:
        return True
    else:
        return False


def print_image(image: str):
    if len(argv) > 2:
        w = argv[2]
        h = argv[3]
        x = argv[4]
        y = argv[5]
        place = ["--place", f"{w}x{h}@{x}x{y}"]
    else:
        place = []
    with open("/dev/tty", "w") as tty:
        run(
            [
                "kitten",
                "icat",
                "--stdin",
                "no",
                "--transfer-mode",
                "memory",
                *place,
                image,
            ],
            check=True,
            stdout=tty,
        )


class Switch:
    def __init__(
        self,
        cases: dict | None = None,
        default: Callable = lambda *_, **__: None,  # pyright: ignore ["__" is not accessed]
    ):
        self.table = dict() if cases is None else cases
        self.default = default

    def __getitem__(self, key):
        return self.table[key]

    def __setitem__(self, keys, val):
        if type(keys) not in {list, tuple, set}:
            self.table[keys] = val
        else:
            for key in keys:
                self.table[key] = val

    def __call__(self, key, var):
        if key in self.table:
            self.table[key](key)
        else:
            self.default(var)


def create_switch_case(file):
    def create_archive_case():
        switch[
            ("application", "x-compressed-tar"),
            ("application", "x-tar"),
            ("application", "x-archive"),
            ("application", "x-bzip"),
            ("application", "x-bzip-compressed-tar"),
            ("application", "vnd.ms-cab-compressed"),
            ("application", "gzip"),
            ("application", "x-java-archive"),
            ("application", "x-lzma"),
            ("application", "x-lz4"),
            ("application", "x-xz-compressed-tar"),
            ("application", "x-xz"),
            ("application", "x-xpinstall"),
            ("application", "x-compress"),
            ("application", "zip"),
        ] = lambda mime_type: run(
            [
                "atool",
                "--list",
                *(["-F", "zip"] if mime_type[1] == "zip" else []),
                "--",
                file,
            ],
            check=True,
        )
        switch[("application", "vnd.rar")] = lambda _: run(
            ["unrar", "lt", "-p-", "--", file], check=True
        )
        switch[("application", "x-7z-compressed")] = lambda _: run(
            ["7z", "l", "-p", "--", file], check=True
        )

    def create_document_case():
        switch[
            ("application", "vnd.oasis.opendocument.text"),
            ("application", "vnd.oasis.opendocument.spreadsheet"),
        ] = lambda _: run(["odt2txt", file], check=True)
        switch[
            (
                "application",
                "vnd.openxmlformats-officedocument.wordprocessingml.document",
            ),
        ] = lambda _: run(["pandoc", "-s", "-t", "gfm", "--", file], check=True)

    def create_other_case():
        switch[("application", "x-bittorrent")] = lambda _: run(
            ["transmission-show", "--", file], check=True
        )
        switch[("text", "html"), ("application", "xhtml+xml")] = lambda _: run(
            ["w3m", "-dump", file], check=True
        )
        switch[
            ("application", "xml"),
            ("application", "json"),
            ("application", "x-shellscript"),
        ] = lambda _: preview_text(file)

    def default(mime_type_main: str):
        if mime_type_main == "text":
            preview_text(file)
        else:
            fallback_to_file_cmd(file)

    switch = Switch(default=default)
    create_archive_case()
    create_document_case()
    create_other_case()
    return switch


def preview_text(file):
    # `lf` can't show output for a line of long string
    # See: https://github.com/gokcehan/lf/pull/1447
    line_length_limit = 200
    s = run(
        ["bat", "--color=always", "-pp", "--", file],
        check=True,
        text=True,
        capture_output=True,
    ).stdout.rstrip()
    if "\n" not in s and len(s) > line_length_limit:
        print(s[:line_length_limit])
    else:
        print(s)


def fallback_to_file_cmd(file):
    print("----- File Type Classification -----")
    res = run(  # to correct the strange print order
        ["file", "-Lb", file], check=True, capture_output=True, text=True
    ).stdout
    print(res, end="")


def fallback_to_non_image(file: str, mime_type: tuple[str, str]):
    switch = create_switch_case(file)
    switch(mime_type, mime_type[0])


def print_pure_image(file: str):
    print_image(file)
    raise SystemExit(1)


def print_cache_image(file: str, mime_type: tuple[str, str]):
    print_image(thumb.main(file=file, mime_type=mime_type))
    raise SystemExit(1)


def get_mime_type_main(mime_type):
    slash_pos = mime_type.find("/")
    mime_type_main = mime_type[:slash_pos]
    return mime_type_main


def fallback(file: str, mime_type: tuple[str, str]):
    mime_type_main = mime_type[0]
    if mime_type_main == "video":
        print_cache_image(file, mime_type)
    elif mime_type_main == "audio":
        if audio_has_cover(file):
            print_cache_image(file, mime_type)
        else:
            run(["mediainfo", "--", file], check=True)
    elif mime_type == "application/pdf":
        print_cache_image(file, mime_type)
    elif mime_type == "application/epub+zip":
        print_cache_image(file, mime_type)
    else:
        fallback_to_non_image(file, mime_type)


def main():
    file = argv[1]

    if getsize(file) == 0:
        fallback_to_file_cmd(file)
    else:
        mime_type = get_mime_type(file)
        if mime_type[0] == "image":
            print_pure_image(file)
        else:
            fallback(file, mime_type)


if __name__ == "__main__":
    main()
