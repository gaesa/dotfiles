#!/usr/bin/env python3
from pathlib import Path
from subprocess import run

from my_utils.os import get_permission, slice_path
from my_utils.seq import for_each
from xdg import BaseDirectory


class Config:
    home = Path.home()


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


@set_permission(Config.home, 0o710, 0o510)
def cleanup(white_list: set[str]):
    for_each(
        trash,
        filter(
            lambda file: file.name.startswith(".")
            and (not file.is_symlink())
            and (not file.is_mount())
            and (not is_bind_mount(file))
            and (file.name not in white_list),
            Path.iterdir(Config.home),
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
                slice_path(BaseDirectory.xdg_cache_home, slice(-1, None)),
                slice_path(BaseDirectory.xdg_data_home, slice(-2, -1)),
            ),
        )
    )


def main():
    user_config_dir = BaseDirectory.xdg_config_home
    white_list = init_white_list(user_config_dir)
    white_list.update(get_extra_white_list(user_config_dir))
    white_list.add(".identity")  # for systemd-homed
    cleanup(white_list)


if __name__ == "__main__":
    main()
