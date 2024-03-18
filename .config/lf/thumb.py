#!/usr/bin/env python3
"""
See also:
https://raw.githubusercontent.com/duganchen/kitty-pistol-previewer/main/vidthumb
"""
import hashlib
from pathlib import Path
from sys import argv


def get_file_id(
    file_path: Path,
    algorithm: str = "sha256",
    chunk_size: int = 65536,
    entire: bool = False,
) -> str:
    stats = file_path.stat()
    mtime, size = stats.st_mtime_ns, stats.st_size
    hash_obj = hashlib.new(algorithm, str(f"{mtime}{size}").encode())
    with open(file_path, "rb") as f:
        if entire:
            chunks = iter(lambda: f.read(chunk_size), b"")
            for chunk in chunks:
                hash_obj.update(chunk)
        else:
            head_chunk = f.read(chunk_size)
            hash_obj.update(head_chunk)

            if size > chunk_size:
                f.seek(-chunk_size, 2)  # 2 means "relative to the end of the file"
                tail_chunk = f.read(chunk_size)
                hash_obj.update(tail_chunk)
    return hash_obj.hexdigest()


def gen_thumb(
    media: str | Path, thumb_path: str | Path, mime_type: tuple[str, str] | None = None
):
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
                str(thumb_path).removesuffix(".jpg"),
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
            from my_utils.os import get_mime_type as get_type

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


def prepare(cache_dir: Path):
    cache_dir.mkdir(mode=0o700, parents=True, exist_ok=True)


def create_thumb_if_necessary(
    media: Path, thumb_path: Path, mime_type: tuple[str, str] | None = None
):
    if (thumb_path).is_file():
        return
    else:
        gen_thumb(media, thumb_path, mime_type)


def main(file: Path | None = None, mime_type: tuple[str, str] | None = None):
    file = Path(argv[1]) if file is None else file

    cache_root = Path("~/.cache/lf_thumb").expanduser()
    prepare(cache_root)

    thumb = f"{get_file_id(file)}.jpg"
    thumb_path = Path(cache_root, thumb)
    create_thumb_if_necessary(file, thumb_path, mime_type)

    return thumb_path


if __name__ == "__main__":
    main()
