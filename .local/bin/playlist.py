#!/usr/bin/env python3
from pathlib import Path
from subprocess import run
from argparse import ArgumentParser
import asyncio
import re
from typing import Iterable
from my_utils.os import get_mime_type_async


def gen_playlist_file(file: str | Path, lst: list[str]) -> None:
    if lst != []:
        with open(file, "w") as f:
            f.write("\n".join(lst))
    else:
        return


def natsort(strings: Iterable[str]) -> list[str]:
    def key(s):
        split_list = re.split(r"(\d+)", s)
        split_list.pop(0) if split_list[0] == "" else None
        split_list.pop(-1) if len(split_list) > 0 and split_list[-1] == "" else None
        return tuple(
            map(
                lambda text: int(text) if text.isdigit() else text,
                split_list,
            )
        )

    return sorted(strings, key=key)


async def gen_playlist(dir: Path) -> list[str]:
    files = tuple(filter(lambda f: f.is_file(), dir.iterdir()))
    tasks = map(lambda file: get_mime_type_async(file), files)
    mime_types: list[tuple[str, str]] = await asyncio.gather(*tasks)
    allowed_mime_types = {"video", "audio"}
    return natsort(
        map(
            lambda file_mime: file_mime[0].parts[-1],
            filter(
                lambda file_mime: file_mime[1][0] in allowed_mime_types,
                zip(files, mime_types, strict=True),
            ),
        )
    )


def get_args() -> tuple[Path, bool, bool, Path]:
    parser = ArgumentParser(
        description="A script to generate and play a playlist using mpv"
    )
    parser.add_argument(
        "directory",
        type=Path,
        nargs="?",
        default=".",
        help="The directory path where videos are located "
        "or will be generated. "
        "Default is the current working directory.",
    )
    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Force regeneration of the playlist file even if it already exists",
    )
    parser.add_argument(
        "-s",
        "--skip-play",
        action="store_true",
        help="skip the play of the playlist",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=str,
        nargs="?",
        default=None,
        help="The playlist file path. Default is 'directory/playlist'",
    )
    args = parser.parse_args()
    args.output = (
        Path(args.directory, "playlist") if args.output is None else args.output
    )
    return args.directory, args.force, args.skip_play, args.output


def main():
    dir, force_regen, skip_play, playlist_path = get_args()

    if playlist_path.is_file() and (not force_regen) and (not skip_play):
        run(["/usr/bin/mpv", f"--playlist={playlist_path}"])
    else:
        playlist: list[str] = asyncio.run(gen_playlist(dir))
        gen_playlist_file(playlist_path, playlist)

        if (not skip_play) and playlist_path.is_file():
            run(["/usr/bin/mpv", f"--playlist={playlist_path}"])
        else:
            return


if __name__ == "__main__":
    main()
