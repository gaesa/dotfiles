#!/usr/bin/env python3
# Inspired by the following program
# https://raw.githubusercontent.com/duganchen/kitty-pistol-previewer/main/vidthumb
from os.path import (
    isfile,
    isdir,
    expanduser,
    join,
)
from os import makedirs
from sys import argv
from my_os import json_read, json_write


def gen_thumb(media: str, thumb_path: str, mime_type: tuple[str, str] | None = None):
    from subprocess import DEVNULL, run

    def gen_for_video():
        run(
            [
                "/usr/bin/ffmpegthumbnailer",
                "-i",
                media,
                "-o",
                thumb_path,
                "-s",
                "0",
                "-t",
                "25%",
            ],
            check=True,
            stdout=DEVNULL,
        )

    def gen_for_audio():
        run(
            [
                "/usr/bin/ffmpeg",
                "-i",
                media,
                "-an",
                "-vcodec",
                "copy",
                thumb_path,
            ],
            check=True,
            stdout=DEVNULL,
        )

    def gen_for_pdf():
        run(
            [
                "/usr/bin/pdftoppm",
                "-singlefile",
                "-jpeg",
                media,
                thumb_path[:-4],  # remove `.jpg`
            ],
            check=True,
            stdout=DEVNULL,
        )

    def gen_for_epub():
        run(
            [
                "/usr/bin/ebook-meta",
                media,
                f"--get-cover={thumb_path}",
            ],
            check=True,
            stdout=DEVNULL,
        )

    def exit_with_msg():
        mes = (
            "This program only supports generating thumbnails "
            "for videos, audios that have covers, pdfs"
        )
        raise SystemExit(mes)

    def get_mime_type() -> tuple[str, str]:
        if mime_type is None:
            from opener import get_mime_type as get_type

            return get_type(media)
        else:
            return mime_type

    mime_type = get_mime_type()
    main = mime_type[0]
    if main == "video":
        gen_for_video()
    elif main == "audio":
        gen_for_audio()
    elif mime_type == ("application", "pdf"):
        gen_for_pdf()
    elif mime_type == ("application", "epub+zip"):
        gen_for_epub()
    else:
        exit_with_msg()


def prepare(cache_dir, index):
    def check_dir(dir):
        if not isdir(dir):
            makedirs(dir, mode=0o700)
        else:
            return

    def check_index(index):
        if not isfile(index):
            json_write(index, [{}, {}], mode="w+")
        else:
            return

    check_dir(cache_dir)
    check_index(index)


def upd_index_and_get_thumb(index, media):
    def upd():
        if need_upd_index:
            media_to_thumb[media] = thumb
            d[1][thumb] = media
            json_write(index, d)
        else:
            return

    d = json_read(index)
    media_to_thumb = d[0]
    if media in media_to_thumb:
        need_upd_index = False
        thumb = media_to_thumb[media]
    else:
        need_upd_index = True

        from uuid import uuid4

        thumb = str(uuid4()) + ".jpg"
    upd()
    return thumb


def upd_thumb(media: str, thumb_path: str, mime_type: tuple[str, str] | None = None):
    if isfile(thumb_path):
        return
    else:
        gen_thumb(media, thumb_path, mime_type)


def main(file: str | None = None, mime_type: tuple[str, str] | None = None):
    file = argv[1] if file is None else file

    index_root = expanduser("~/.cache/lf_thumb")
    cache_root = join(index_root, "img")
    index = join(index_root, "index.json")
    prepare(cache_root, index)

    thumb = upd_index_and_get_thumb(index, file)
    thumb_path = join(cache_root, thumb)
    upd_thumb(file, thumb_path, mime_type)

    return thumb_path


if __name__ == "__main__":
    main()
