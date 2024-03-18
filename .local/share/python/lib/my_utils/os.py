from collections.abc import Callable
from os import chdir, getcwd, stat
from pathlib import Path
from stat import S_IMODE


def slice_path(
    path: str | Path,
    slice_obj: slice,
) -> Path:
    path = path if isinstance(path, Path) else Path(path)
    return Path(*path.parts[slice_obj])


def get_mime_type(
    file: str | Path, exts_for_file_cmd: set[str] = {".ts", ".bak", ".txt", ".TXT"}
) -> tuple[str, str]:
    # `xdg-mime query filetype` are better than
    # `file -Lb --mime_type` & `mimetypes.guess_type()`
    # although both of them are not perfect
    # problematic extensions:
    # `.md` (with CJK character), `.ts`,
    # `.m4a`, `.tm`, `.xopp`, `.org`, `.scm`

    from subprocess import run

    from xdg import Mime

    def xdg_mime(file: Path) -> tuple[str, str]:
        mime = Mime.get_type2(file)
        return mime.media, mime.subtype  # pyright: ignore [reportAttributeAccessIssue]

    file = file if isinstance(file, Path) else Path(file)
    extension = file.suffix

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
    file: str | Path, exts_for_file_cmd: set[str] = {".ts", ".bak", ".txt", ".TXT"}
) -> tuple[str, str]:
    from xdg import Mime

    from .aio import run

    def xdg_mime(file: Path) -> tuple[str, str]:
        mime = Mime.get_type2(file)
        return mime.media, mime.subtype  # pyright: ignore [reportAttributeAccessIssue]

    file = file if isinstance(file, Path) else Path(file)
    extension = file.suffix

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
            return xdg_mime(file)
    else:
        return xdg_mime(file)


def json_read(file: str | Path):
    import json

    with open(file, "r") as f:
        return json.load(f)


def json_write(file: str | Path, data: list | dict, mode: str = "w") -> None:
    import json

    with open(file, mode) as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


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
