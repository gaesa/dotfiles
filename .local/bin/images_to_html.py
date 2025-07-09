#!/usr/bin/env python3
from dataclasses import dataclass
from pathlib import Path
from typing import Self, final

from jinja2 import Environment, Template
from my_utils.iters import natsort
from my_utils.stream import Stream


@final
@dataclass(frozen=True, kw_only=True, slots=True)
class Cli:
    directory: Path

    @classmethod
    def parse(cls) -> Self:
        from argparse import ArgumentParser

        parser = ArgumentParser(description="Create an HTML file with images.")
        parser.add_argument(
            "directory", type=Path, help="The directory containing the images."
        )
        args = parser.parse_args()
        return cls(directory=args.directory)


def get_template() -> Template:
    env = Environment()

    template_string = """
    <!DOCTYPE html>
    <html>
    <body>
        {% for image_file in image_files %}
        <div style="display: flex; justify-content: center;">
            <img src="{{ image_file }}" style="max-width: 1000px;">
        </div>
        {% endfor %}
    </body>
    </html>
    """.strip()

    template = env.from_string(template_string)
    return template


def create_html(directory: Path, output: Path):
    image_files = (
        Stream(directory.iterdir())
        .map(str)
        .sorted(key=natsort)
        .map(Path)
        .map(Path.resolve)
    )
    html = get_template().render(image_files=image_files)
    with open(directory.joinpath(output), "w") as f:
        f.write(html)


def main(directory: Path | None = None) -> Path:
    directory = (
        directory.resolve()
        if directory is not None
        else Cli.parse().directory.resolve()
    )
    output = Path(directory, f"{directory.name}.html")
    create_html(directory, output)
    return output


if __name__ == "__main__":
    main()
