#!/usr/bin/env python3
import json
from os.path import isfile, isdir, expanduser, realpath, join, basename
from os import makedirs, remove
import sys
from subprocess import DEVNULL, run
from uuid import uuid4
from mimetypes import guess_type


def input_len_check(input_list):
    if len(input_list) < 2:
        sys.exit(1)
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
            f.write("{}")
    else:
        return None


def clean(cache_dir, index):
    cache_list = run(
        ["fd", "-t", "--changed-before", "1months", r"(\.jpg)$", cache_dir],
        capture_output=True,
        text=True,
    ).stdout.splitlines()
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
    mime_type, _ = guess_type(media)
    if mime_type != None:
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
            sys.exit(1)
    else:
        sys.exit(1)


def main():
    input_list = sys.argv
    input_len_check(input_list)
    file = input_list[1]

    cache_dir = expanduser("~/.cache/vidthumb")
    cache_dir_check(cache_dir)

    index = f"{cache_dir}/index.json"
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
    else:
        pass

    print(thumb_path)  # to display the thumbnail on the screen


if __name__ == "__main__":
    main()
