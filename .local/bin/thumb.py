#!/usr/bin/env python3
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
from os import makedirs, remove, environ, listdir
from datetime import datetime
from sys import exit as sys_exit, argv
from subprocess import DEVNULL, run
from uuid import uuid4


def input_len_check(input_list):
    if len(input_list) < 2:
        sys_exit(1)
    else:
        return None


def cache_dir_check(cache_dir):
    if not isdir(cache_dir):
        makedirs(cache_dir, mode=0o700)
    else:
        return None


def index_file_check(index):
    if not isfile(index):
        with open(index, "w+") as f:
            d = [{}, {}]
            json.dump(d, f, indent=2, ensure_ascii=False)
    else:
        return None


def within_one_month(old_dt, new_dt):
    def evaluate():
        d_mon = new_dt.month - old_dt.month
        if d_mon == 0:
            return True
        elif d_mon == 1:
            d_day = new_dt.day - old_dt.day
            if d_day < 0:
                return True
            elif d_day == 0:
                d_hour = new_dt.hour - old_dt.hour
                if d_hour < 0:
                    return True
                elif d_hour == 0:
                    d_min = new_dt.minute - old_dt.minute
                    if d_min < 0:
                        return True
                    elif d_min == 0:
                        d_sec = new_dt.second - old_dt.second
                        if d_sec < 0:
                            return True
                        elif d_sec == 0:

                            def int_to_decimal(num):
                                k = len(str(num))
                                return num / (10**k)

                            d_msec = int_to_decimal(
                                new_dt.microsecond
                            ) - int_to_decimal(old_dt.microsecond)

                            if d_msec > 0:
                                return False
                            else:
                                return True
                        else:
                            return False
                    else:
                        return False
                else:
                    return False
            else:
                return False
        else:
            return False

    d_year = new_dt.year - old_dt.year
    if d_year == 0:
        return evaluate()
    elif d_year == 1:
        if new_dt.month == 1 and old_dt.month == 12:
            return evaluate()
        else:
            return False
    else:
        return False


def clean(cache_dir, index):
    def get_cache_list():
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

    cache_list = get_cache_list()
    for cache in cache_list:
        remove(cache)
        cache = basename(cache)
        with open(index) as f:
            d = json.load(f)
            media = d[1].pop(cache)
            d[0].pop(media)
        with open(index, "w") as f:
            json.dump(d, f, indent=2, ensure_ascii=False)


def gen_thumb(media, thumb_path):
    mime_type = environ["filetype"]
    if mime_type.startswith("video"):
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
    elif mime_type.startswith("audio"):
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
    else:
        sys_exit(1)


def main():
    input_len_check(argv)
    file = argv[1]

    cache_dir = expanduser("~/.cache/lf_thumb")
    cache_dir_check(cache_dir)

    index = join(cache_dir, "index.json")
    index_file_check(index)

    # Remove old caches, including those whose respective media files no longer exist,
    # and delete the corresponding JSON contents
    clean(cache_dir, index)

    media = realpath(file, strict=True)

    need_update_index = False
    with open(index) as f:
        d = json.load(f)
        if media in d[0]:
            thumb = d[0][media]
            thumb_path = join(cache_dir, thumb)
            # record: yes, cache: no
            if not isfile(thumb_path):
                gen_thumb(media, thumb_path)
            else:
                pass
        else:
            # record: no, cache: any
            thumb = str(uuid4()) + ".jpg"
            thumb_path = join(cache_dir, thumb)
            gen_thumb(media, thumb_path)
            need_update_index = True
    if need_update_index:
        with open(index, "w") as f:
            d[0][media] = thumb
            d[1][thumb] = media
            json.dump(d, f, indent=2, ensure_ascii=False)

    print(thumb_path)  # to pass data to bash through STDOUT


if __name__ == "__main__":
    main()
