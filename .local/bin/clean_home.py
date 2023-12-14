#!/usr/bin/env python3
from subprocess import run
from pathlib import Path
from my_utils.seq import for_each
from my_utils.os import get_permission, slice_path
from my_utils.dirs import Xdg


def set_permission(file: Path, pre: int, post: int):
    def decorator(orig_fn):
        def new_fn(*args, **kwargs):
            Path(file).chmod(pre) if get_permission(file) != pre else None
            orig_fn(*args, **kwargs)
            Path(file).chmod(post) if get_permission(file) != post else None

        return new_fn

    return decorator


def trash(file: str | Path):
    run(["trash", file], check=True)


@set_permission(Xdg.home(), 0o710, 0o510)
def cleanup(white_list: set[str]):
    for_each(
        trash,
        filter(
            lambda file: file.name.startswith(".")
            and (not file.is_symlink())
            and (not is_bind_mount(file))
            and (file.name not in white_list),
            Path.iterdir(Xdg.home()),
        ),
    )


def is_bind_mount(path: str | Path):
    mounts = set(
        map(
            lambda line: line.split()[4],
            Path("/proc/self/mountinfo").read_text().splitlines(),
        )
    )
    path = path if isinstance(path, Path) else Path(path)
    return str(path.resolve()) in mounts


def get_extra_white_list(
    user_config_dir: str | Path, file: str | Path | None = None
) -> list[str]:
    file = (
        Path(user_config_dir, "clean/white-list")
        if file is None
        else (file if isinstance(file, Path) else Path(file))
    )
    return file.read_text().splitlines() if file.is_file() else []


def init_white_list(user_config_dir: str | Path) -> set[str]:
    return set(
        map(
            str,
            (
                slice_path(
                    user_config_dir,
                    slice(-1, None),
                ),
                slice_path(Xdg.user_cache_dir(), slice(-1, None)),
                slice_path(Xdg.user_data_dir(), slice(-2, -1)),
            ),
        )
    )


def main():
    user_config_dir = Xdg.user_config_dir()
    white_list = init_white_list(user_config_dir)
    white_list.update(get_extra_white_list(user_config_dir))
    cleanup(white_list)


if __name__ == "__main__":
    main()
