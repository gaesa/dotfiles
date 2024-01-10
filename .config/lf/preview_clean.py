#!/usr/bin/env python3
from base64 import standard_b64encode
from itertools import starmap


def serialize(payload: bytes | str = b"", **cmd: dict[str, str]) -> bytes:
    "Modified from https://github.com/kovidgoyal/kitty/blob/master/kittens/tui/images.py#L382-L397."

    cmds = ",".join(starmap(lambda k, v: f"{k}={v}", cmd.items()))
    ans = [b"\033_G", cmds.encode("ascii")]
    if payload not in {"", b""}:
        ans.extend(
            (
                b";",
                (
                    standard_b64encode(payload.encode())
                    if isinstance(payload, str)
                    else payload
                ),
                b"\033\\",
            )
        )
    else:
        ans.append(b"\033\\")
    return b"".join(ans)


def main():
    # `sys.stdout` doesn't work as expected here, we have to access the low-level device `/dev/tty` directly.
    with open("/dev/tty", "w") as tty:
        tty.buffer.write(
            serialize(a="d", d="A")  # pyright: ignore [reportGeneralTypeIssues]
        )


if __name__ == "__main__":
    main()
