from collections.abc import Callable
from time import sleep
from typing import Any

import httpx
from faker import Faker


def wait_online(url: str | None = None):
    url = "https://www.steamcommunity.com" if url is None else url
    faker = Faker()
    while True:
        try:
            response = httpx.head(
                url,
                timeout=5,
                headers={"User-Agent": faker.firefox()},
            )
            if response.status_code in {200, 301, 302}:
                return
            else:
                sleep(1)
        except (
            httpx.ReadError,
            httpx.ReadTimeout,
            httpx.ConnectTimeout,
            httpx.ConnectError,
            httpx.RemoteProtocolError,
        ):
            sleep(1)


def ensure_online(
    url: str | None = None,
    is_async: bool = False,
    wait_fn: Callable[[str | None], Any] | None = None,
):
    from .fntools import before

    wait_fn = wait_online if wait_fn is None else wait_fn
    return before(lambda: wait_fn(url), is_async)
