import atexit
import readline
from pathlib import Path

from my_utils.dirs import Xdg


def main():
    histfile = Path(Xdg.user_state_path(), "python/history")
    if histfile.is_file():
        readline.read_history_file(histfile)
        readline.set_history_length(1000)
        atexit.register(readline.write_history_file, histfile)
    else:
        return


if __name__ == "__main__":
    main()
