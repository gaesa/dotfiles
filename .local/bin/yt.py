#!/usr/bin/env python3
import logging
import os
import random
from argparse import ArgumentParser
from collections.abc import Iterable, Sequence
from contextlib import contextmanager
from dataclasses import dataclass
from subprocess import run
from tempfile import NamedTemporaryFile
from typing import Literal, TypedDict, final

import yt_dlp
from pydantic import PositiveInt, BaseModel, field_validator, Field
from my_utils.stream import Stream

logging.basicConfig(level=os.environ.get("LOG_LEVEL_PROGRAM", "WARNING").upper())
logger = logging.getLogger(__name__)


@final
@dataclass(frozen=True, kw_only=True)
class Video:
    title: str
    url: str


@final
class RawVideoEntry(TypedDict):
    title: str
    url: str
    duration: float | None
    live_status: Literal["is_live", "was_live", None]


class Videos(tuple):
    @classmethod
    def from_videos(cls, videos: Iterable[Video]):
        return cls((list(videos),))

    def serialize_to_m3u(self, duration: int | None = None) -> str:
        duration = duration if duration is not None else -1
        lines = [""] * (2 * len(self[0]) + 1)
        lines[0] = "#EXTM3U"
        for i, video in map(lambda pair: (2 * pair[0], pair[1]), enumerate(self[0])):
            lines[i] = f"#EXTINF:{duration},{video.title}"
            lines[i + 1] = video.url
        return "\n".join(lines)

    # TODO: make url in edl be read by mpv
    def serialize_to_edl(self, duration: int) -> str:
        lines = [""] * (len(self[0]) + 1)
        lines[0] = "# mpv EDL v0"
        for i, video in enumerate(self[0], start=1):
            lines[i] = f"{video.url},0,{duration},title={video.title}"
        return "\n".join(lines)


# noinspection PyShadowingBuiltins
def get_videos(
    keyword: str, limit: int = 5, load_factor: float = 0.25, format: str | None = None
) -> Videos:
    if not isinstance(keyword, str) or keyword == "":
        raise ValueError("keyword must be a non-empty string")
    elif not isinstance(limit, int) or limit <= 0:
        raise ValueError("limit must be a positive integer")
    elif not isinstance(load_factor, float) or (load_factor <= 0 or load_factor >= 1):
        raise ValueError("load_factor must be a float between 0 and 1")
    else:
        with yt_dlp.YoutubeDL(
            {
                "quiet": True,
                "no_warnings": True,
                "simulate": True,
                "noplaylist": True,
                "format": format,
            }
        ) as ydl:
            upper_bound = round(limit / load_factor)
            info_dict = ydl.extract_info(
                f"ytsearch{upper_bound}:{keyword}",
                download=False,
                process=False,
            )
            assert isinstance(info_dict, dict)
            entries: Sequence[RawVideoEntry] = list(info_dict["entries"])

            chosen_entries: list[RawVideoEntry] = random.sample(entries, limit)
            videos = Videos.from_videos(
                Stream(chosen_entries)
                .filterfalse(lambda v: v["live_status"] == "is_live")
                .filterfalse(lambda v: v["duration"] is None)
                .map(lambda v: Video(title=v["title"], url=v["url"]))
            )
            return videos


@contextmanager
def create_playlist_file(videos: Videos, duration: int | None):
    with NamedTemporaryFile(mode="w", suffix=".m3u") as temp:
        temp.write(videos.serialize_to_m3u(duration))
        temp.seek(0)  # file pointers are inherited by child processes
        logger.info("playlist path: %s", temp.name)
        yield temp.name


def play(playlist_path: str, duration: int | None, profile: str):
    cmd = [
        "mpv",
        f"--profile={profile}",
        *((f"--length={duration}",) if duration is not None else ()),
        playlist_path,
    ]
    logger.info("mpv command: %s", cmd)
    run(cmd, check=True)


@final
class Cli(BaseModel):
    keyword: str = Field(..., min_length=1)
    limit: PositiveInt
    duration: PositiveInt | None
    profile: str = Field(..., min_length=1)
    format: str = Field(..., min_length=1)

    # noinspection PyNestedDecorators
    @field_validator("duration")
    @classmethod
    def min_to_sec(cls, v: PositiveInt | None) -> PositiveInt | None:
        return v * 60 if v is not None else v

    class Config:
        frozen = True

    @classmethod
    def parse(cls) -> "Cli":
        parser = ArgumentParser(description="Play random videos from YouTube.")
        parser.add_argument(
            "keyword",
            type=str,
            help="Keyword to search for videos",
        )
        parser.add_argument(
            "--limit",
            type=int,
            default=1,
            help="Limit for the number of videos to fetch (default: 1)",
        )
        parser.add_argument(
            "--duration",
            type=int,
            default=None,
            help="Duration for each video in minutes (default: no limit)",
        )
        parser.add_argument(
            "--profile",
            type=str,
            default="default",
            help="Profile to use for mpv (default: 'default')",
        )
        parser.add_argument(
            "--format",
            type=str,
            default=None,
            help="Format to use for the videos",
        )
        args = parser.parse_args()
        return cls(**vars(args))


# noinspection PyShadowingBuiltins
def search_and_play(
    keyword: str,
    limit: int,
    profile: str,
    format: str | None = None,
    duration: int | None = None,
):
    with create_playlist_file(
        get_videos(keyword, limit, format=format), duration=duration
    ) as playlist_path:
        play(playlist_path, duration, profile)


def main():
    try:
        cli = Cli.parse()
        search_and_play(cli.keyword, cli.limit, cli.profile, cli.format, cli.duration)
    except KeyboardInterrupt:
        print()


if __name__ == "__main__":
    main()
