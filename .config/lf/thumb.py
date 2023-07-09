#!/usr/bin/env python3
# Inspired by the following program
# https://raw.githubusercontent.com/duganchen/kitty-pistol-previewer/main/vidthumb
import json
from os.path import (
    isfile,
    isdir,
    expanduser,
    realpath,
    join,
    basename,
    splitext,
    getmtime,
)
from os import makedirs, remove, listdir, environ
from datetime import datetime
from sys import exit as sys_exit, argv
from subprocess import DEVNULL, run
from uuid import uuid4


def within_one_month(old_dt: datetime, new_dt: datetime):
    def cmp_mon():
        d_mon = new_dt.month - old_dt.month
        if d_mon == 0:
            return True
        elif d_mon == 1:
            return cmp_day()
        else:
            return False

    def cmp_day():
        def cmp_date(date: str):
            old: int = getattr(old_dt, date)
            new: int = getattr(new_dt, date)
            delta = new - old
            if delta < 0:
                return True
            elif delta == 0:
                next_unit_dict = {
                    "day": "hour",
                    "hour": "minute",
                    "minute": "second",
                    "second": "microsecond",
                }
                next_unit = next_unit_dict[date]
                if next_unit == "microsecond":
                    return cmp_msec()
                else:
                    return cmp_date(next_unit)
            else:
                return False

        return cmp_date("day")

    def cmp_msec():
        return not (new_dt.microsecond > old_dt.microsecond)

    d_year = new_dt.year - old_dt.year
    if d_year == 0:
        return cmp_mon()
    elif d_year == 1:
        if new_dt.month == 1 and old_dt.month == 12:
            return cmp_day()
        else:
            return False
    else:
        return False


def clean(cache_dir, index):
    # Remove old cache files, including those
    # whose respective media files no longer exist,
    # and delete the corresponding JSON contents
    def get_old_cache():
        cache_list = []
        for obj in listdir(cache_dir):
            full_path = join(cache_dir, obj)
            if splitext(obj)[1] == ".jpg" and (
                not within_one_month(
                    datetime.fromtimestamp(getmtime(full_path)), datetime.now()
                )
            ):
                cache_list.append(full_path)
        return cache_list

    old_cache_list = get_old_cache()
    if old_cache_list == []:
        return
    else:
        with open(index) as f:
            d = json.load(f)
        for cache in old_cache_list:
            remove(cache)
            cache = basename(cache)
            media = d[1].pop(cache)
            d[0].pop(media)
        with open(index, "w") as f:
            json.dump(d, f, indent=2, ensure_ascii=False)


def gen_thumb(media, thumb_path):
    def gen_for_video():
        run(
            [
                "ffmpegthumbnailer",
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
                "ffmpeg",
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
            ["pdftoppm", "-singlefile", "-jpeg", media, thumb_path[:-4]],
            # remove `.jpg`
            check=True,
            stdout=DEVNULL,
        )

    def exit_with_msg():
        mes = (
            "This program only supports generating thumbnails "
            "for videos, audios that have covers, pdfs"
        )
        sys_exit(mes)

    mime_type = environ["mime_type"]
    if mime_type.startswith("video"):
        gen_for_video()
    elif mime_type.startswith("audio"):
        gen_for_audio()
    elif mime_type == "application/pdf":
        gen_for_pdf()
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
            with open(index, "w+") as f:
                d = [{}, {}]
                json.dump(d, f, indent=2, ensure_ascii=False)
        else:
            return

    check_dir(cache_dir)
    check_index(index)


def get_thumb_path(cache_dir, index, media):
    def upd_index():
        if need_upd_index:
            d[0][media] = thumb
            d[1][thumb] = media
            with open(index, "w") as f:
                json.dump(d, f, indent=2, ensure_ascii=False)
        else:
            return

    with open(index) as f:
        d = json.load(f)
    media_to_thumb = d[0]
    if media in media_to_thumb:
        need_upd_index = False
        thumb = media_to_thumb[media]
    else:
        need_upd_index = True
        thumb = str(uuid4()) + ".jpg"

    thumb_path = join(cache_dir, thumb)
    return thumb_path, upd_index


def upd_thumb(media: str, thumb_path: str):
    if isfile(thumb_path):
        return
    else:
        gen_thumb(media, thumb_path)


def main(file=argv[1]):
    cache_dir = expanduser("~/.cache/lf_thumb")
    index = join(cache_dir, "index.json")
    prepare(cache_dir, index)
    clean(cache_dir, index)
    media = realpath(file, strict=True)

    thumb_path, upd_index = get_thumb_path(cache_dir, index, media)
    upd_thumb(media, thumb_path)
    upd_index()

    return thumb_path


if __name__ == "__main__":
    main()
