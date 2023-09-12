#!/usr/bin/env python3
# like `xdg-open`, but supports `open-with` and
# running in terminal directly
from subprocess import DEVNULL, Popen, run
from sys import argv
from os.path import expanduser, isfile, join, splitext, basename
from os import environ
from configparser import ConfigParser, SectionProxy


def get_mime_type(file):
    # `xdg-mime query filetype` are better than
    # `file -Lb --mime_type` & `mimetypes.guess_type()`
    # although they are all not perfect
    # such as: `.md` (with CJK character), `.ts`,
    # `.m4a`, `.tm`, `.xopp`, `.org`, `.scm`
    extension = splitext(file)[1]
    if extension in {".ts", ".bak"}:
        mime_type = run(
            ["file", "-Lb", "--mime-type", file],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.rstrip()
        return mime_type
    else:
        mime_type = run(
            ["xdg-mime", "query", "filetype", file],
            check=True,
            capture_output=True,
            text=True,
        ).stdout.rstrip()
        return mime_type


def get_default_desktops(mime_type: str, interactive=False):
    config = ConfigParser()
    config.optionxform = (  # pyright: ignore [reportGeneralTypeIssues]
        str  # to make keys case-sensitive
    )
    XDG_CURRENT_DESKTOP = environ["XDG_CURRENT_DESKTOP"]
    mime_configs = [
        expanduser("~/.config/mimeapps.list"),
        f"/etc/xdg/{XDG_CURRENT_DESKTOP}-mimeapps.list",
        "/etc/xdg/mimeapps.list",
        "/usr/local/share/applications/mimeapps.list",
        "/usr/share/applications/mimeinfo.cache",
    ]

    def extract_desktops():
        def get_desktop_name_decide():
            def gen_list(mime_section: SectionProxy, mime_type: str) -> list[str]:
                desktop = mime_section[mime_type]
                if desktop[-1] == ";":
                    default_desktops = desktop[:-1].split(";")
                else:
                    default_desktops = desktop.split(";")
                return default_desktops

            def gen_str(mime_section: SectionProxy, mime_type: str) -> str:
                desktop = mime_section[mime_type]
                index = desktop.find(";")
                default_desktop = desktop[:index]
                return default_desktop

            if interactive:
                return gen_list
            else:
                return gen_str

        get_desktop_name = get_desktop_name_decide()

        def extract_from_system_config():
            for mime_config in mime_configs[1:]:
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

            mime_user_config = mime_configs[0]
            if isfile(mime_user_config):
                config.read(mime_user_config)
                if interactive:
                    return extract_from_added_assoc()
                else:
                    return extract_from_default_apps()
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

        if XDG_CURRENT_DESKTOP == "KDE":
            info = run(
                ["ktraderclient5", "--mimetype", mime_type],
                check=True,
                capture_output=True,
                text=True,
            ).stdout

            desktop_names = parse_desktop_names()
            if desktop_names != []:
                if interactive:
                    return desktop_names
                else:
                    return desktop_names[0]
            else:
                return fallback_to_choice()
        else:
            return fallback_to_choice()

    def fallback_to_choice():
        try:
            default_desktop = input(
                "No program found to open file. Please enter a program name: "
            )
            if not default_desktop.endswith(".desktop"):
                default_desktop += ".desktop"
            if interactive:
                return [default_desktop]
            else:
                return default_desktop
        except (KeyboardInterrupt, EOFError):
            print()
            raise SystemExit(0)

    return extract_desktops()


def open(default_desktop, file):
    default_program = default_desktop[:-8]  # remove `.desktop`
    if default_program in {"nvim", "mpv"}:
        # ignore Exec entry & show output in terminal
        run([join("/usr/bin", default_program), file])
    else:

        def choose_desktop():
            application_paths = [
                expanduser(f"~/.local/share/applications/{default_desktop}"),
                f"/usr/local/share/applications/{default_desktop}",
                f"/usr/share/applications/{default_desktop}",
            ]
            desktop = ConfigParser(interpolation=None)  # to make `%` raw
            for i in range(len(application_paths)):
                path = application_paths[i]
                if isfile(path):
                    desktop.read(path)
                    return desktop
            raise FileNotFoundError("No .dekstop found")

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


def open_with(default_desktop, file):
    for i in range(len(default_desktop)):
        print(f"{i}. {default_desktop[i]}")
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
    if argv[1] == "-i":
        interactive = True
        file = argv[2]
    else:
        interactive = False
        file = argv[1]

    mime_type = get_mime_type(file)
    if mime_type == "application/x-executable":
        run([file], check=True)
    elif mime_type == "text/plain" and basename(file) == "playlist":
        run(["/usr/bin/mpv", f"--playlist={file}"])
    else:
        default_desktops = get_default_desktops(mime_type, interactive=interactive)
        if interactive:
            open_with(default_desktops, file)
        else:
            open(default_desktops, file)


if __name__ == "__main__":
    main()
