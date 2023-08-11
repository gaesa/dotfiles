#!/usr/bin/env python3
from uuid import uuid4
from os import getenv, chmod, stat
from stat import S_IMODE
from os.path import join


def mktemp(prefix=""):
    if prefix != "":
        name = f"{prefix}-{str(uuid4())}"
    else:
        name = str(uuid4())
    dir = getenv("TMPDIR", "/tmp")
    path = join(dir, name)
    open(path, "w").close()

    permission = oct(S_IMODE(stat(path).st_mode))
    if permission != 0o600:
        chmod(path, 0o600)
        return path
    else:
        return path
