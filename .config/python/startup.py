import atexit
from os import getenv
import readline
from os.path import join, expanduser
from my_utils.seq import fallback


def main():
    histfile = join(
        fallback(
            lambda: getenv("XDG_STATE_HOME"), lambda: expanduser("~/.local/state")
        ),
        "python/history",
    )

    readline.read_history_file(histfile)
    readline.set_history_length(1000)

    atexit.register(readline.write_history_file, histfile)


if __name__ == "__main__":
    main()
