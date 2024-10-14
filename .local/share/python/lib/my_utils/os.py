from collections.abc import Callable
from os import chdir, getcwd, stat
from pathlib import Path
from stat import S_IMODE
from typing import Literal


def slice_path(
    path: str | Path,
    slice_obj: slice,
) -> Path:
    path = path if isinstance(path, Path) else Path(path)
    return Path(*path.parts[slice_obj])


def get_mime_type(
    file: str | Path, exts_for_file_cmd: set[str] = {".bak", ".txt"}
) -> tuple[str, str]:
    # `xdg-mime query filetype` are better than
    # `file -Lb --mime-type` & `mimetypes.guess_type()`
    # although both of them are not perfect
    # problematic extensions:
    # `.md` (with CJK character), `.ts`,
    # `.m4a`, `.tm`, `.xopp`, `.org`, `.scm`

    from subprocess import run

    def xdg_mime(file: Path) -> tuple[str, str]:
        file_str = str(file)
        stdout = run(
            [
                "xdg-mime",
                "query",
                "filetype",
                f"./{file_str}" if file_str.startswith("-") else file_str,
            ],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.rstrip()
        lst = stdout.split("/", maxsplit=1)
        assert len(lst) == 2
        return (lst[0], lst[1])

    file = file if isinstance(file, Path) else Path(file)
    extension = file.suffix.lower()

    if extension in exts_for_file_cmd:
        file_args = ["file", "-Lb", "--mime-type", "--", file]
        p = run(file_args, capture_output=True, text=True)
        if p.returncode == 0:
            raw_out = p.stdout.rstrip()
            mime = tuple(raw_out.split("/", 1))
            if len(mime) != 2:
                raise ValueError(f"{file_args} returns: '{raw_out}'")
            else:
                return mime
        else:
            return xdg_mime(file)
    else:
        return xdg_mime(file)


async def get_mime_type_async(
    file: str | Path, exts_for_file_cmd: set[str] = {".bak", ".txt"}
) -> tuple[str, str]:
    from .aio import run

    async def xdg_mime(file: Path) -> tuple[str, str]:
        file_str = str(file)
        stdout = (
            await run(
                [
                    "xdg-mime",
                    "query",
                    "filetype",
                    f"./{file_str}" if file_str.startswith("-") else file_str,
                ],
                text=True,
                check=True,
            )
        ).stdout.rstrip()  # pyright: ignore [reportAttributeAccessIssue, reportOptionalMemberAccess]
        lst = stdout.split("/", maxsplit=1)
        assert len(lst) == 2
        return (lst[0], lst[1])

    file = file if isinstance(file, Path) else Path(file)
    extension = file.suffix.lower()

    if extension in exts_for_file_cmd:
        file_args = ["file", "-Lb", "--mime-type", "--", file]
        p = await run(file_args, text=True)
        raw_out = (
            p.stdout.rstrip()  # pyright: ignore [reportAttributeAccessIssue, reportOptionalMemberAccess]
        )
        if p.returncode == 0:
            mime = tuple(raw_out.split("/", 1))
            if len(mime) != 2:
                raise ValueError(f"{file_args} returns: '{raw_out}'")
            else:
                return mime
        else:
            return await xdg_mime(file)
    else:
        return await xdg_mime(file)


def get_file_id(
    file_path: Path,
    algorithm: Literal[
        "sha1",
        "sha224",
        "sha256",
        "sha384",
        "sha512",
        "sha3_224",
        "sha3_256",
        "sha3_384",
        "sha3_512",
        "shake_128",
        "shake_256",
        "blake2",
        "blake2s",
        "md5",
    ] = "sha256",
    entire: bool = False,
    chunk_size: int = 256 * 1024,  # 0.25 MiB
    chunk_count: int = 3,
) -> str:
    def get_sample_points(
        total_size: int, chunk_size: int, chunk_count: int
    ) -> list[int]:
        if total_size < 0 or chunk_size <= 0 or chunk_count <= 0:
            raise ValueError(
                f"total_size: {total_size}, chunk_size: {chunk_size}, chunk_count: {chunk_count}"
            )
        else:
            if total_size <= chunk_size:
                return [0]
            else:
                count, offset = chunk_count, chunk_size // 2
                match count:
                    case 1:
                        return [total_size // 2 - offset]
                    case 2:
                        interval = total_size // 3
                        return [
                            max(0, interval - offset),
                            max(0, interval * 2 - offset),
                        ]
                    case 3:
                        return [0, total_size // 2 - offset, total_size - chunk_size]
                    case _:
                        extra_slot_count = count - 2
                        interval = total_size // (extra_slot_count + 1)
                        lst = [0] * count
                        lst.extend(
                            map(
                                lambda factor: max(0, factor * interval - offset),
                                range(1, extra_slot_count + 1),
                            )
                        )
                        lst.append(total_size - chunk_size)
                        return lst

    import hashlib

    stats = file_path.stat()
    mtime, size = stats.st_mtime_ns, stats.st_size
    hasher = hashlib.new(
        algorithm, data=mtime.to_bytes(length=16, byteorder="little", signed=False)
    )
    hasher.update(size.to_bytes(length=8, byteorder="little", signed=False))
    with open(file_path, "rb") as f:
        if entire:
            chunks = iter(lambda: f.read(chunk_size), b"")
            for chunk in chunks:
                hasher.update(chunk)
        else:
            for pos in get_sample_points(size, chunk_size, chunk_count):
                f.seek(pos)
                hasher.update(f.read(chunk_size))
    return hasher.hexdigest()


def get_permission(file: str | Path):
    return S_IMODE(stat(file).st_mode)


def run_chdir(dir: str | Path):
    def decorator(old_fn: Callable) -> Callable:
        def new_fn(*args, **kwargs):
            cwd = getcwd()
            chdir(dir)
            value = old_fn(*args, **kwargs)
            chdir(cwd)
            return value

        return new_fn

    return decorator
