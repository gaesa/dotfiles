#!/usr/bin/env python3
from os.path import getsize
from subprocess import run
from sys import argv
from typing import Callable

from my_utils.os import get_mime_type

import thumb


def audio_has_cover(audio):
    from pymediainfo import MediaInfo

    media_info = MediaInfo.parse(audio)
    d = media_info.tracks[0].to_data()  # pyright: ignore [[reportAttributeAccessIssue]]
    return "cover" in d


def print_image(image: str):
    if len(argv) > 2:
        w, h, x, y = argv[2], argv[3], argv[4], argv[5]
        place = ("--place", f"{w}x{h}@{x}x{y}")
    else:
        place = ()
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


class Case:
    def __init__(
        self,
        init: list[tuple[set, Callable]] | None = None,
        default: Callable | None = None,
    ) -> None:
        self.__cases = [] if init is None else init
        self.__default = default

    def append(self, elements: set, action: Callable):
        self.__cases.append((elements, action))

    def extend(self, *pairs: tuple[set, Callable]):
        self.__cases.extend(pairs)

    def run(self, x):
        for elements, action in self.__cases:
            if x in elements:
                return action(x)
        return None if self.__default is None else self.__default(x)


def fallback_to_non_image(file: str, mime_type: tuple[str, str]):
    def make_archive_case():
        case.append(
            {
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
            },
            lambda mime_type: run(
                [
                    "atool",
                    "--list",
                    *(("-F", "zip") if mime_type[1] == "zip" else ()),
                    "--",
                    file,
                ],
                check=True,
            ),
        )
        case.append(
            {("application", "vnd.rar")},
            lambda _: run(["unrar", "lt", "-p-", "--", file], check=True),
        )
        case.append(
            {("application", "x-7z-compressed")},
            lambda _: run(["7z", "l", "-p", "--", file], check=True),
        )

    def make_document_case():
        case.extend(
            (
                {
                    ("application", "vnd.oasis.opendocument.text"),
                    ("application", "vnd.oasis.opendocument.spreadsheet"),
                },
                lambda _: run(["odt2txt", file], check=True),
            ),
            (
                {
                    (
                        "application",
                        "vnd.openxmlformats-officedocument.wordprocessingml.document",
                    )
                },
                lambda _: run(["pandoc", "-s", "-t", "gfm", "--", file], check=True),
            ),
        )

    def make_misc_case():
        case.extend(
            (
                {("application", "x-bittorrent")},
                lambda _: run(["transmission-show", "--", file], check=True),
            ),
            (
                {("text", "html"), ("application", "xhtml+xml")},
                lambda _: run(["w3m", "-dump", file], check=True),
            ),
            (
                {
                    ("application", "xml"),
                    ("application", "json"),
                    ("application", "yaml"),
                    ("application", "toml"),
                    ("application", "x-shellscript"),
                    ("application", "javascript"),
                    ("application", "x-desktop"),
                },
                lambda _: preview_text(file),
            ),
        )

    case = Case(
        default=lambda mime_type: (
            preview_text(file) if mime_type[0] == "text" else fallback_to_file_cmd(file)
        )
    )
    make_archive_case()
    make_document_case()
    make_misc_case()
    case.run(mime_type)


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


def print_pure_image(file: str):
    print_image(file)
    raise SystemExit(1)


def print_cache_image(file: str, mime_type: tuple[str, str]):
    print_image(thumb.main(file=file, mime_type=mime_type))
    raise SystemExit(1)


def fallback(file: str, mime_type: tuple[str, str]):
    mime_type_main = mime_type[0]
    if mime_type_main == "video":
        print_cache_image(file, mime_type)
    elif mime_type_main == "audio":
        if audio_has_cover(file):
            print_cache_image(file, mime_type)
        else:
            run(["mediainfo", "--", file], check=True)
    elif mime_type == ("application", "pdf"):
        print_cache_image(file, mime_type)
    elif mime_type == ("application", "epub+zip"):
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
