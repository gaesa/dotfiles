#!/usr/bin/env python3
import json
from os.path import isfile, isdir, expanduser, realpath, join, basename
from os import makedirs, remove
import sys
from subprocess import DEVNULL, PIPE, run
from uuid import uuid4


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
    cache_list = (
        run(
            ["fd", "-t", "--changed-before", "1months", r"(\.jpg)$", cache_dir],
            stdout=PIPE,
        )
        .stdout.decode("utf-8")
        .rstrip()
        .splitlines()
    )
    for cache in cache_list:
        remove(cache)
        cache = basename(cache)
        with open(index) as f:
            d = json.load(f)
            for key, value in d.items():
                if value == cache:
                    d.pop(key)
                else:
                    pass
        with open(index, "w") as f:
            json.dump(d, f, indent=2, ensure_ascii=False)


def gen_thumb(video, thumb_path):
    run(
        [
            "ffmpegthumbnailer",
            "-i",
            video,
            "-o",
            thumb_path,
            "-s",
            "0",
            "-t",
            "25%",
        ],
        stderr=DEVNULL,
    )


def main():
    input_list = sys.argv
    input_len_check(input_list)
    file = input_list[1]

    cache_dir = expanduser("~/.cache/vidthumb")
    cache_dir_check(cache_dir)

    index = f"{cache_dir}/index.json"
    index_file_check(index)
    clean(cache_dir, index)

    video = realpath(file, strict=True)

    need_update_index = False
    with open(index) as f:
        d = json.load(f)
        if video in d:
            thumb = d[video]
            thumb_path = join(cache_dir, thumb)
            if not isfile(thumb_path):
                gen_thumb(video, thumb_path)
            else:
                pass
        else:
            thumb = str(uuid4()) + ".jpg"
            thumb_path = join(cache_dir, thumb)
            gen_thumb(video, thumb_path)
            need_update_index = True
    if need_update_index:
        with open(index, "w") as f:
            d[video] = thumb
            json.dump(d, f, indent=2, ensure_ascii=False)
    else:
        pass

    print(thumb_path)  # to display the thumbnail on the screen


if __name__ == "__main__":
    main()
