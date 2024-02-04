#!/usr/bin/env python3
import argparse
import logging
import re
from subprocess import CalledProcessError, run


def parse_args() -> tuple[str, bool, bool, int]:
    def non_negative_int(value: str) -> int:
        int_value = int(value)
        if int_value < 0:
            raise argparse.ArgumentTypeError(
                f"'{value}' is an invalid non-negative int value"
            )
        else:
            return int_value

    parser = argparse.ArgumentParser(
        description="Retrieve a specific log entry based on recency from a specified systemd "
        "unit"
    )
    parser.add_argument("unit", type=str, help="Specify the unit")
    parser.add_argument(
        "--user",
        "-u",
        action="store_true",
        help="whether to get logs for the user",
    )
    parser.add_argument(
        "--status",
        action="store_true",
        help="whether to include status header",
    )
    parser.add_argument(
        "-p",
        "--position",
        type=non_negative_int,
        default=0,
        help="specify the position of the log entry to retrieve from the most recent",
    )
    args = parser.parse_args()
    return args.unit, args.user, args.status, args.position


def get_raw_logs(unit: str, user: bool) -> str:
    return run(
        ["journalctl", "--no-pager", *(("--user",) if user else ()), "-u", unit],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.rstrip()


def group_by_line(string: str, pattern: str) -> list[str]:
    if string == "":
        return []
    else:
        lines = string.splitlines(keepends=True)
        groups = [lines[0]]  # The first line is always included
        line_iter = iter(lines)
        next(line_iter)  # Skip the first line
        for line in line_iter:
            if re.search(pattern, line) is not None:
                groups.append(line)
            else:
                groups[-1] += line
        return groups


def split_logs(unit: str, user: bool) -> list[str]:
    return group_by_line(
        get_raw_logs(unit, user), r"(systemd\[\d+\]): Start(ed|ing) .*\.$"
    )


def recency_to_index(i: int):
    return -(i + 1)


def get_raw_status(unit: str, user: bool) -> str:
    cmd = [
        "systemctl",
        "--no-pager",
        *(("--user",) if user else ()),
        "status",
        "--full",
        unit,
    ]
    p = run(
        cmd,
        capture_output=True,
        text=True,
    )
    if p.returncode in {0, 1, 3}:  # active, failed, not active
        return p.stdout.rstrip()
    else:  # no such unit
        e = p.stderr.rstrip()
        logging.error(e)
        raise CalledProcessError(p.returncode, cmd, p.stdout.rstrip(), e)


def truncate_till_empty_line(string: str) -> str:
    from itertools import islice

    lines = string.splitlines(keepends=True)
    newlines = frozenset(("\n", "\r\n", "\r"))
    for i, line in enumerate(lines):
        if line in newlines:
            return "".join(islice(lines, i))  # More efficient than `lines[:i]`
    else:
        return string


def get_status_header(unit: str, user: bool):
    return truncate_till_empty_line(get_raw_status(unit, user))


def log(unit: str, user: bool, status: bool, position: int = 0) -> str:
    return (
        f"{get_status_header(unit, user)}\n"
        f"{split_logs(unit, user)[recency_to_index(position)]}"
        if status
        else split_logs(unit, user)[recency_to_index(position)]
    )


def main():
    unit, user, status, position = parse_args()
    print(log(unit, user, status, position))


if __name__ == "__main__":
    main()
