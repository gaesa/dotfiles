#!/usr/bin/env python3
import re
from collections.abc import Iterator
from dataclasses import dataclass
from pathlib import Path
from typing import ClassVar, Self, final

import anyio
import httpx
from faker import Faker
from result import Err, Ok, Result, as_async_result, as_result
from tqdm import tqdm


@final
@dataclass(frozen=True, kw_only=True, slots=True)
class Config:
    ua: str


config = Config(ua=Faker().firefox())


@final
@dataclass(frozen=True, kw_only=True, slots=True)
class Cli:
    directory: Path
    url_pattern: str
    no_html: bool
    no_html_images_inline: bool

    @classmethod
    def parse(cls) -> Self:
        from argparse import ArgumentParser

        parser = ArgumentParser(description="Download images from URLs")
        parser.add_argument("directory", type=Path, help="Directory to save the images")
        parser.add_argument("url_pattern", type=str, help="URL pattern")
        parser.add_argument(
            "--no-html", action="store_true", help="Do not generate HTML file"
        )
        parser.add_argument(
            "--no-html-images-inline",
            action="store_true",
            help="Do not inline images in HTML file",
        )
        args = parser.parse_args()

        cli = cls(**vars(args))
        directory = cli.directory.expanduser().resolve()
        directory.mkdir(exist_ok=True)
        return cls(
            directory=directory,
            url_pattern=cli.url_pattern.rstrip("/"),
            no_html=cli.no_html,
            no_html_images_inline=cli.no_html_images_inline,
        )


def get_url_last_componenet(url: str) -> Result[str, type[ValueError]]:
    t = url.rstrip("/").rsplit("/", 1)
    return Ok(t[1]) if len(t) == 2 else Err(ValueError)


@final
class UrlFilePairs:
    pattern: ClassVar[re.Pattern[str]] = re.compile(
        r"(.*)(?:\{\s*(\d+)\s*(\.\.=?)\s*(\d+)\s*(?::\s*(\d+))?\s*\})(.*)"
    )

    @classmethod
    def from_pattern(
        cls, url_pattern: str
    ) -> Result[tuple[int, Iterator[tuple[str, str]]], type[SyntaxError]]:
        # `{i..[=]j[: padding_count]}`
        match = cls.pattern.match(url_pattern)

        if match is None:
            return (
                Err(SyntaxError)
                if "{" in url_pattern or "}" in url_pattern
                else Ok(
                    (
                        1,
                        iter(
                            (
                                (
                                    url_pattern,
                                    get_url_last_componenet(url_pattern).unwrap(),
                                ),
                            )
                        ),
                    )
                )
            )
        else:
            left, start_s, sep, end_s, padding_count_s, right = match.groups()
            left: str
            start_s: str
            sep: str
            end_s: str
            padding_count_s: str | None
            right: str
            if (
                left == ""
                or ("{" in left)
                or ("}" in left)
                or ("{" in right)
                or ("}" in right)
            ):
                return Err(SyntaxError)

            start, end = int(start_s), int(end_s)
            end = end + 1 if sep.endswith("=") else end
            count = end - start

            url_to_pair = lambda url: (url, get_url_last_componenet(url).unwrap())
            index_to_pair = lambda i: url_to_pair(f"{left}{i}{right}")
            assert left.count("/") > 2
            if padding_count_s is None:
                return Ok((count, map(index_to_pair, range(start, end))))
            else:
                padding_count = int(padding_count_s)
                return Ok(
                    (
                        count,
                        map(
                            lambda i: index_to_pair(str(i).zfill(padding_count)),
                            range(start, end),
                        ),
                    )
                )


@as_result(httpx.HTTPStatusError)
def check_response_status(response: httpx.Response):
    response.raise_for_status()


@as_async_result(httpx.ReadTimeout, httpx.ConnectTimeout)
async def client_get(
    client: httpx.AsyncClient, url: str, timeout: int, headers: dict[str, str]
) -> httpx.Response:
    return await client.get(url, timeout=timeout, headers=headers)


async def try_get_response(
    url: str, client: httpx.AsyncClient, times: int = 3
) -> Result[
    httpx.Response,
    type[ValueError] | httpx.HTTPStatusError | httpx.ReadTimeout | httpx.ConnectTimeout,
]:
    if times <= 0:
        return Err(ValueError)
    else:
        last_error = ValueError
        while times > 0:
            unchecked_response = await client_get(
                client=client, url=url, timeout=10, headers={"User-Agent": config.ua}
            )
            if unchecked_response.is_ok():
                response = unchecked_response.unwrap()
                check_result = check_response_status(response)
                if check_result.is_ok():
                    return Ok(response)
                else:
                    last_error = check_result.unwrap_err()
                    times -= 1
            else:
                last_error = unchecked_response.unwrap_err()
                times -= 1
        else:
            return Err(last_error)


async def download(
    url: str, client: httpx.AsyncClient, output: Path
) -> Result[None, httpx.HTTPStatusError | httpx.ReadTimeout | httpx.ConnectTimeout]:
    response = await try_get_response(url, client, times=3)
    if response.is_err():
        e = response.unwrap_err()
        assert isinstance(
            e, (httpx.HTTPStatusError, httpx.ReadTimeout, httpx.ConnectTimeout)
        )
        return Err(e)
    else:
        res = response.unwrap()
        check_result = check_response_status(res)
        if check_result.is_err():
            return Err(check_result.unwrap_err())
        else:
            async with await anyio.open_file(output, "wb") as f:
                await f.write(res.content)
            return Ok(None)


async def download_with_progress(
    url: str,
    client: httpx.AsyncClient,
    output: Path,
    progress_bar: tqdm,
    semaphore: anyio.Semaphore,
):
    async with semaphore:
        (await download(url=url, client=client, output=output)).unwrap()
        progress_bar.update(1)


async def download_images(cli: Cli):
    page_count, url_file_pairs = UrlFilePairs.from_pattern(cli.url_pattern).expect(
        f"{cli.url_pattern} is not valid"
    )
    progress_bar = tqdm(total=page_count)

    async with httpx.AsyncClient(http2=True) as client:
        async with anyio.create_task_group() as tg:
            semaphore = anyio.Semaphore(initial_value=16, max_value=16)
            for url, file in url_file_pairs:
                tg.start_soon(
                    download_with_progress,
                    url,
                    client,
                    cli.directory.joinpath(file),
                    progress_bar,
                    semaphore,
                )


def main():
    try:
        cli = Cli.parse()
        anyio.run(download_images, cli)
        if not cli.no_html:
            import images_to_html

            output = images_to_html.main(directory=cli.directory)
            if not cli.no_html_images_inline:
                from subprocess import run

                run(["html-images-inliner", output], check=True)
                output.with_suffix(".inlined.html").replace(output)
            else:
                return
        else:
            return
    except (KeyboardInterrupt, EOFError):
        print()


if __name__ == "__main__":
    main()
