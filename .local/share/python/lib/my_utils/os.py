from os import getcwd, chdir, stat
from pathlib import Path
from typing import Callable
from stat import S_IMODE


def get_mime_type(file: str | Path) -> tuple[str, str]:
    # `xdg-mime query filetype` are better than
    # `file -Lb --mime_type` & `mimetypes.guess_type()`
    # although both of them are not perfect
    # problematic extensions:
    # `.md` (with CJK character), `.ts`,
    # `.m4a`, `.tm`, `.xopp`, `.org`, `.scm`
    from subprocess import run

    file = file if isinstance(file, Path) else Path(file)
    extension = file.suffix

    file_args = ["file", "-Lb", "--mime-type", "--", file]
    args = (
        file_args
        if extension in {".ts", ".bak", ".txt", ".TXT"}
        else [
            "xdg-mime",
            "query",
            "filetype",
            f"./{file}" if str(file).startswith("-") else file,
        ]
    )

    string = run(args, capture_output=True, text=True, check=True).stdout.rstrip()
    mime_type = tuple(string.split("/", 1))
    if len(mime_type) != 2:
        if args[0] == "xdg-mime":
            new_str = run(
                file_args, capture_output=True, text=True, check=True
            ).stdout.rstrip()
            new_type = tuple(new_str.split("/", 1))
            if len(new_type) != 2:
                raise ValueError(f"{file_args} returns: '{new_str}'")
            else:
                return new_type
        else:
            raise ValueError(f"{file_args} returns: '{string}'")
    else:
        return mime_type


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


def run_chdir_async(dir: str | Path):
    def decorator(old_fn: Callable) -> Callable:
        async def new_fn(*args, **kwargs):
            cwd = getcwd()
            chdir(dir)
            value = await old_fn(*args, **kwargs)
            chdir(cwd)
            return value

        return new_fn

    return decorator
