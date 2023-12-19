#!/usr/bin/env python3
from datetime import datetime
from os import listdir, remove
from os.path import expanduser, getmtime, isdir, isfile, join

from my_utils.os import json_read, json_write, run_chdir
from my_utils.seq import filterfalse, for_each


def within_one_month(old_dt: datetime, new_dt: datetime) -> bool:
    def cmp_mon():
        d_mon = new_dt.month - old_dt.month
        if d_mon == 0:
            return True
        elif d_mon == 1:
            return cmp_day_to_msec()
        else:
            return False

    def cmp_day_to_msec() -> bool:
        next_unit_dict = {
            "day": "hour",
            "hour": "minute",
            "minute": "second",
            "second": "microsecond",
        }

        def cmp_msec():
            return not (new_dt.microsecond > old_dt.microsecond)

        def iter(date: str):
            old: int = getattr(old_dt, date)
            new: int = getattr(new_dt, date)
            delta = new - old
            if delta < 0:
                return True
            elif delta == 0:
                next_unit = next_unit_dict[date]
                if next_unit == "microsecond":
                    return cmp_msec()
                else:
                    return iter(next_unit)
            else:
                return False

        return iter("day")

    d_year = new_dt.year - old_dt.year
    if d_year == 0:
        return cmp_mon()
    elif d_year == 1:
        if new_dt.month == 1 and old_dt.month == 12:
            return cmp_day_to_msec()
        else:
            return False
    else:
        return False


def clean_by_cache_mtime(cache_dir: str, index: str) -> None:
    """Remove old cache files, and delete the corresponding JSON contents"""

    @run_chdir(cache_dir)
    def get_old_cache() -> tuple[str, ...]:
        return tuple(
            filter(
                lambda file: not within_one_month(
                    datetime.fromtimestamp(getmtime(file)), datetime.now()
                ),
                listdir(),
            )
        )

    @run_chdir(cache_dir)
    def pop_cache(caches: tuple[str, ...]) -> None:
        def p(cache: str):
            remove(cache)
            media = cache_to_media.pop(cache)
            media_to_cache.pop(media)

        d: list[dict[str, str]] = json_read(index)
        [media_to_cache, cache_to_media] = d
        for_each(p, caches)
        json_write(index, d)

    caches = get_old_cache()
    return None if caches == () else pop_cache(caches)


def clean_by_index_file(cache_dir: str, index: str):
    @run_chdir(cache_dir)
    def handle_nonexistent_media():
        def p(media):
            cache = media_to_cache.pop(media)
            cache_to_media.pop(cache)
            remove(cache) if isfile(cache) else None

        for_each(p, filterfalse(isfile, tuple(media_to_cache.keys())))

    @run_chdir(cache_dir)
    def handle_nonexistent_cache():
        def p(cache):
            media = cache_to_media.pop(cache)
            media_to_cache.pop(media)

        for_each(p, filterfalse(isfile, tuple(cache_to_media.keys())))

    d: list[dict[str, str]] = json_read(index)
    [media_to_cache, cache_to_media] = d
    length = len(media_to_cache)

    handle_nonexistent_media()
    handle_nonexistent_cache()
    if len(media_to_cache) != length:
        json_write(index, d)
    else:
        return


def main():
    index_root = expanduser("~/.cache/lf_thumb")
    cache_root = join(index_root, "img")
    index = join(index_root, "index.json")

    if isdir(cache_root) and isfile(index):
        clean_by_cache_mtime(cache_root, index)
        clean_by_index_file(cache_root, index)
    else:
        return


if __name__ == "__main__":
    main()
