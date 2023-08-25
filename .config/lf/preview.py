#!/usr/bin/env python3
from sys import argv, exit as sys_exit
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
                "file",
                *place,
                image,
            ],
            check=True,
            stdout=tty,
        )


class Switch:
    def __init__(self):
        self.table = {}

    def __getitem__(self, key):
        return self.table[key]

    def __setitem__(self, keys, val):
        if type(keys) not in {list, tuple, set}:
            self.table[keys] = val
        else:
            for key in keys:
                self.table[key] = val

    def __call__(self, key):
        self.table[key]()


def create_switch_case(file):
    def create_archive_case():
        switch[
            "application/x-compressed-tar",
            "application/x-tar",
            "application/x-archive",
            "application/x-bzip",
            "application/x-bzip-compressed-tar",
            "application/vnd.ms-cab-compressed",
            "application/gzip",
            "application/x-java-archive",
            "application/x-lzma",
            "application/x-lz4",
            "application/x-xz-compressed-tar",
            "application/x-xz",
            "application/x-xpinstall",
            "application/x-compress",
            "application/zip",
        ] = lambda: run(["atool", "--list", "--", file], check=True)
        switch["application/vnd.rar"] = lambda: run(
            ["unrar", "lt", "-p-", "--", file], check=True
        )
        switch["application/x-7z-compressed"] = lambda: run(
            ["7z", "l", "-p", "--", file], check=True
        )

    def create_document_case():
        switch[
            "application/vnd.oasis.opendocument.text",
            "application/vnd.oasis.opendocument.spreadsheet",
        ] = lambda: run(["odt2txt", file], check=True)
        switch[
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ] = lambda: run(["pandoc", "-s", "-t", "gfm", "--", file], check=True)

    def create_other_case():
        switch["application/x-bittorrent"] = lambda: run(
            ["transmission-show", "--", file], check=True
        )
        switch["text/html", "application/xhtml+xml"] = lambda: run(
            ["w3m", "-dump", file], check=True
        )
        switch["application/xml", "application/json"] = lambda: run(
            ["bat", "--color=always", "-pp", "--", file], check=True
        )

    switch = Switch()
    create_archive_case()
    create_document_case()
    create_other_case()
    return switch


def fallback_to_file_cmd(file):
    print("----- File Type Classification -----")
    res = run(  # to correct the strange print order
        ["file", "-Lb", file], check=True, capture_output=True, text=True
    ).stdout
    print(res)


def fallback_to_non_image(file, mime_type, mime_type_main):
    switch = create_switch_case(file)
    if mime_type in switch.table:
        switch(mime_type)
    else:
        if mime_type_main == "text":
            run(["bat", "--color=always", "-pp", "--", file], check=True)
        else:
            fallback_to_file_cmd(file)


def print_pure_image(file: str):
    print_image(file)
    sys_exit(1)
    # to clear the last displayed image, no idea on why we need to do this


def print_cache_image(file: str):
    print_image(thumb.main(file=file))
    sys_exit(1)


def get_mime_type_main(mime_type):
    slash_pos = mime_type.find("/")
    mime_type_main = mime_type[:slash_pos]
    return mime_type_main


def fallback(file, mime_type, mime_type_main):
    from os import environ

    environ["mime_type"] = mime_type
    if mime_type_main == "video":
        print_cache_image(file)
    elif mime_type_main == "audio":
        if audio_has_cover(file):
            print_cache_image(file)
        else:
            run(["mediainfo", "--", file], check=True)
    elif mime_type == "application/pdf":
        print_cache_image(file)
    elif mime_type == "application/epub+zip":
        print_cache_image(file)
    else:
        fallback_to_non_image(file, mime_type, mime_type_main)


def main():
    file = argv[1]

    if getsize(file) == 0:
        fallback_to_file_cmd(file)
    else:
        mime_type = get_mime_type(file)
        mime_type_main = get_mime_type_main(mime_type)

        if mime_type_main == "image":
            print_pure_image(file)
        else:
            fallback(file, mime_type, mime_type_main)


if __name__ == "__main__":
    main()
