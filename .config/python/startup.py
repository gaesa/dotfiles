import atexit
import readline
from pathlib import Path

try:
    from xdg import BaseDirectory
except ModuleNotFoundError:
    import sys

    sys.path.append(f"/usr/lib/python3.11/site-packages")

    from xdg import BaseDirectory


def main():
    histfile = Path(BaseDirectory.xdg_state_home, "python/history")
    if histfile.is_file():
        readline.read_history_file(histfile)
        readline.set_history_length(1000)
        atexit.register(readline.write_history_file, histfile)
    else:
        return


if __name__ == "__main__":
    main()
