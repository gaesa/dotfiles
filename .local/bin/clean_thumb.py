#!/usr/bin/env python3
from datetime import datetime
from pathlib import Path

from my_utils.stream import Stream


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


def clean_by_cache_mtime(cache_dir: Path):
    now = datetime.now()
    (
        Stream(cache_dir.iterdir())
        .filterfalse(
            lambda path: within_one_month(
                datetime.fromtimestamp(path.stat().st_mtime), now
            )
        )
        .for_each(lambda path: path.unlink(missing_ok=True))
    )


def main():
    cache_root = Path("~/.cache/lf_thumb").expanduser()
    if cache_root.is_dir():
        clean_by_cache_mtime(cache_root)
    else:
        return


if __name__ == "__main__":
    main()
