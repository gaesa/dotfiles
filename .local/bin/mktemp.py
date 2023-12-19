#!/usr/bin/env python3
from os import chmod, getenv
from os.path import join
from uuid import uuid4

from my_utils.os import get_permission


def mktemp(prefix=""):
    if prefix != "":
        name = f"{prefix}-{str(uuid4())}"
    else:
        name = str(uuid4())
    dir = getenv("TMPDIR", "/tmp")
    path = join(dir, name)
    open(path, "w").close()

    chmod(path, 0o600) if get_permission(path) != 0o600 else None
    return path
