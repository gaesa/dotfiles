#!/usr/bin/env python3
# like `xdg-open`, but supports `open-with` and
# running in terminal directly
from subprocess import DEVNULL, Popen, run
from sys import argv
from os.path import expanduser, isfile, join, basename
from configparser import ConfigParser, SectionProxy
from my_utils.os import get_mime_type


def get_list_of_mimeapps(
    XDG_CONFIG_HOME: str,
    XDG_CURRENT_DESKTOP: tuple[str, ...],
    XDG_CONFIG_DIRS: list[str],
    XDG_DATA_DIRS: list[str],
) -> tuple[tuple[str, ...], tuple[str, ...]]:
    from my_utils.seq import flatmap

    return (
        (
            *map(
                lambda desktop: join(XDG_CONFIG_HOME, f"{desktop}-mimeapps.list"),
                XDG_CURRENT_DESKTOP,
            ),
            join(XDG_CONFIG_HOME, "mimeapps.list"),
        ),
        (
            *flatmap(
                lambda cfg_dir: tuple(
                    map(
                        lambda desktop: join(cfg_dir, f"{desktop}-mimeapps.list"),
                        XDG_CURRENT_DESKTOP,
                    )
                ),
                XDG_CONFIG_DIRS,
            ),
            *map(
                lambda cfg_dir: join(cfg_dir, "mimeapps.list"),
                XDG_CONFIG_DIRS,
            ),
            *flatmap(
                lambda data_dir: tuple(
                    map(
                        lambda desktop: join(
                            data_dir, f"applications/{desktop}-mimeapps.list"
                        ),
                        XDG_CURRENT_DESKTOP,
                    )
                ),
                XDG_DATA_DIRS,
            ),
            *map(
                lambda data_dir: join(data_dir, "applications/mimeapps.list"),
                XDG_DATA_DIRS,
            ),
        ),
    )


def get_default_desktops(mime_type: str, interactive=False):
    from my_utils.dirs import Xdg
    from os import environ

    config = ConfigParser()
    config.optionxform = (  # pyright: ignore [reportGeneralTypeIssues]
        str  # to make keys case-sensitive
    )
    XDG_CURRENT_DESKTOP = tuple(
        map(str.lower, environ["XDG_CURRENT_DESKTOP"].split(":"))
    )
    user_configs, system_configs = get_list_of_mimeapps(
        Xdg.user_config_dir(),
        XDG_CURRENT_DESKTOP,
        Xdg.site_config_dirs(),
        Xdg.site_data_dirs(),
    )

    def extract_desktops():
        def get_desktop_name_decide():
            def get_all(mime_section: SectionProxy, mime_type: str) -> list[str]:
                desktop = mime_section[mime_type]
                return desktop.rstrip(";").split(";")

            def get_first(mime_section: SectionProxy, mime_type: str) -> str:
                desktop = mime_section[mime_type]
                return desktop[: desktop.find(";")]

            return get_all if interactive else get_first

        get_desktop_name = get_desktop_name_decide()

        def extract_from_system_config():
            for mime_config in system_configs:
                if isfile(mime_config):
                    config.read(mime_config)
                    mime_section = config["MIME Cache"]
                    if mime_type in mime_section:
                        return get_desktop_name(mime_section, mime_type)
            return fallback()

        def extract_from_user_config():
            def extract_from_added_assoc():
                mime_section = config["Added Associations"]
                if mime_type in mime_section:
                    return get_desktop_name(mime_section, mime_type)
                else:
                    return extract_from_system_config()

            def extract_from_default_apps():
                mime_section = config["Default Applications"]
                if mime_type in mime_section:
                    return get_desktop_name(mime_section, mime_type)
                else:
                    return extract_from_added_assoc()

            for user_config in user_configs:
                if isfile(user_config):
                    config.read(user_config)
                    return (
                        extract_from_added_assoc()
                        if interactive
                        else extract_from_default_apps()
                    )
                else:
                    return extract_from_system_config()

        return extract_from_user_config()

    def fallback():
        def parse_desktop_names():
            i = 0
            start = i + 21
            desktop_names: list[str] = []
            while start < len(info):
                if info[i:start] == "\nDesktopEntryName : '":
                    i = start
                    while info[i] != "'":
                        i += 1
                    end = i
                    desktop_name = info[start:end] + ".desktop"
                    desktop_names.append(desktop_name)
                    i = end + 2
                else:
                    i += 1
                start = i + 21
            return desktop_names

        if XDG_CURRENT_DESKTOP[0] == "kde":
            info = run(
                ["ktraderclient5", "--mimetype", mime_type],
                check=True,
                capture_output=True,
                text=True,
            ).stdout

            desktop_names = parse_desktop_names()
            if desktop_names != []:
                return desktop_names if interactive else desktop_names[0]
            else:
                return fallback_to_choice()
        else:
            return fallback_to_choice()

    def fallback_to_choice():
        try:
            default_desktop = input(
                "No program found to open file. Please enter a program name: "
            )
            print()
            if not default_desktop.endswith(".desktop"):
                default_desktop += ".desktop"
            return [default_desktop] if interactive else default_desktop
        except (KeyboardInterrupt, EOFError):
            print()
            raise SystemExit(0)

    return extract_desktops()


def open(default_desktop: str, file: str):
    default_program = default_desktop[: -len(".desktop")]
    if default_program in {"nvim", "mpv"}:
        # ignore Exec entry & show output in terminal
        run([join("/usr/bin", default_program), file])
        print() if default_program in {"mpv"} else None
    else:

        def choose_desktop():
            application_paths = (
                expanduser(f"~/.local/share/applications/{default_desktop}"),
                f"/usr/local/share/applications/{default_desktop}",
                f"/usr/share/applications/{default_desktop}",
            )
            desktop = ConfigParser(interpolation=None)  # to make `%` raw
            for path in application_paths:
                if isfile(path):
                    desktop.read(path)
                    return desktop
            raise FileNotFoundError("No '.dekstop' found")

        def parse_exec():
            # remove `%f`, `--` etc.
            exec_key = desktop["Desktop Entry"]["Exec"]
            string = ""
            i = 0
            while i < len(exec_key):
                if exec_key[i : i + 2] == " %" or exec_key[i : i + 4] == " -- ":
                    i += 3
                else:
                    string += exec_key[i]
                    i += 1
            return string

        desktop = choose_desktop()
        exec_key = parse_exec()

        from shlex import split

        cmd = split(exec_key)
        Popen(cmd + [file], stdout=DEVNULL, stderr=DEVNULL)
        # the reason for using `Popen`: don't care the output in terminals.
        # To ensure that lf displays the correct TUI,
        # it is necessary to suppress the output of any background processes


def open_with(default_desktop: list[str], file: str):
    from my_utils.seq import for_each

    for_each(lambda id: print(f"{id[0]}. {id[1]}"), enumerate(default_desktop))
    try:
        choice = int(
            input(
                "Please choose a program to use "
                "by entering its corresponding number: "
            )
        )
        open(default_desktop[choice], file)
        print()
    except (KeyboardInterrupt, EOFError):
        print()
        raise SystemExit(0)


def main():
    interactive, file = (True, argv[2]) if argv[1] == "-i" else (False, argv[1])

    mime_type = get_mime_type(file)
    if mime_type == ("application", "x-executable"):
        run([file], check=True)
    elif mime_type == ("text", "plain") and basename(file) == "playlist":
        run(["/usr/bin/mpv", f"--playlist={file}"])
    else:
        default_desktops = get_default_desktops(
            "/".join(mime_type), interactive=interactive
        )
        open_with(
            default_desktops, file  # pyright: ignore [reportGeneralTypeIssues]
        ) if interactive else open(
            default_desktops, file  # pyright: ignore [reportGeneralTypeIssues]
        )


if __name__ == "__main__":
    main()
