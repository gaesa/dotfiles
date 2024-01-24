from os import getenv, getuid
from pathlib import Path
from typing import final

from .fntools import cache_single_value, non_instantiable
from .seq import fallback


class CannotInstantiateError(Exception):
    """Raised when trying to instantiate a non-instantiable class"""

    pass


def __init():
    CONFIG_HOME = ("XDG_CONFIG_HOME", ".config")
    DATA_HOME = ("XDG_DATA_HOME", ".local/share")
    STATE_HOME = ("XDG_STATE_HOME", ".local/state")
    CACHE_HOME = ("XDG_CACHE_HOME", ".cache")

    # Because there is no static property, and `@functools.cached_property` is not read-only
    @cache_single_value
    def home_path() -> Path:
        return Path().home()

    def get(env: str, dir: str) -> str | Path:
        return fallback(lambda: getenv(env), lambda: Path(home_path(), dir))

    def get_str(env: str, dir: str) -> str:
        return str(get(env, dir))

    def get_path(env: str, dir: str) -> Path:
        value = get(env, dir)
        return value if isinstance(value, Path) else Path(value)

    @non_instantiable
    @final
    class Xdg:
        """
        This class provides methods for accessing directories as per the XDG Base
        Directory specification. This helps standardize the location of certain
        directories across different programs.

        Environment variables are used when available, with defaults provided when
        they are not set.

        Methods ending with `dir` return `str`, and those ending with `dirs` return
        `list[str]`. Methods ending with `path` return `Path`, and those ending
        with `paths` return `list[Path]`.
        """

        @staticmethod
        def home() -> Path:
            """
            Returns the home directory as a `Path` object. The return value is cached.
            """
            return home_path()

        @staticmethod
        def user_config_dir() -> str:
            """
            Returns the user config directory (`XDG_CONFIG_HOME`) as a string.
            """
            return get_str(*CONFIG_HOME)

        @staticmethod
        def user_config_path() -> Path:
            """
            Returns the user config directory (`XDG_CONFIG_HOME`) as a `Path`
            object.
            """
            return get_path(*CONFIG_HOME)

        @staticmethod
        def user_data_dir() -> str:
            """
            Returns the user data directory (`XDG_DATA_HOME`) as a string.
            """
            return get_str(*DATA_HOME)

        @staticmethod
        def user_data_path() -> Path:
            """
            Returns the user data directory (`XDG_DATA_HOME`) as a `Path` object.
            """
            return get_path(*DATA_HOME)

        @staticmethod
        def user_state_dir() -> str:
            """
            Returns the user state directory (`XDG_STATE_HOME`) as a string.
            """
            return get_str(*STATE_HOME)

        @staticmethod
        def user_state_path() -> Path:
            """
            Returns the user state directory (`XDG_STATE_HOME`) as a `Path` object.
            """
            return get_path(*STATE_HOME)

        @staticmethod
        def user_cache_dir() -> str:
            """
            Returns the user cache directory (`XDG_CACHE_HOME`) as a string.
            """
            return get_str(*CACHE_HOME)

        @staticmethod
        def user_cache_path() -> Path:
            """
            Returns the user cache directory (`XDG_CACHE_HOME`) as a `Path` object.
            """
            return get_path(*CACHE_HOME)

        @staticmethod
        def user_runtime_dir() -> str:
            """
            Returns the user runtime directory (`XDG_RUNTIME_DIR`) as a string.
            """
            return fallback(
                lambda: getenv("XDG_RUNTIME_DIR"), lambda: f"/run/user/{getuid()}"
            )

        @classmethod
        def user_runtime_path(cls) -> Path:
            """
            Returns the user runtime directory (`XDG_RUNTIME_DIR`) as a `Path`
            object.
            """
            return Path(cls.user_runtime_dir())

        @staticmethod
        def site_config_dirs() -> list[str]:
            """
            Returns the site config directories (`XDG_CONFIG_DIRS`) as a list of
            strings.
            """
            return fallback(
                lambda: getenv("XDG_CONFIG_DIRS"), lambda: "/etc/xdg"
            ).split(":")

        @classmethod
        def site_config_paths(cls) -> list[Path]:
            """
            Returns the site config directories (`XDG_CONFIG_DIRS`) as a list of
            `Path` objects.
            """
            return list(map(Path, cls.site_config_dirs()))

        @staticmethod
        def site_data_dirs() -> list[str]:
            """
            Returns the site data directories (`XDG_DATA_DIRS`) as a list of
            strings.
            """
            return fallback(
                lambda: getenv("XDG_DATA_DIRS"), lambda: "/usr/local/share:/usr/share"
            ).split(":")

        @classmethod
        def site_data_paths(cls) -> list[Path]:
            """
            Returns the site data directories (`XDG_DATA_DIRS`) as a list of `Path`
            objects.
            """
            return list(map(Path, cls.site_data_dirs()))

    return Xdg


Xdg = __init()
del __init  # due to python's syntax limitations of lambda
