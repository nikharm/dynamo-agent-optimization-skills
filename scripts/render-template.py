#!/usr/bin/env python3
"""Render @@NAME@@ placeholders from environment variables."""

import argparse
import os
import re
from pathlib import Path

PATTERN = re.compile(r"@@([A-Z][A-Z0-9_]*)@@")


def render(text: str) -> str:
    missing: set[str] = set()

    def replace(match: re.Match[str]) -> str:
        name = match.group(1)
        value = os.environ.get(name)
        if value is None:
            missing.add(name)
            return match.group(0)
        return value

    output = PATTERN.sub(replace, text)
    if missing:
        raise SystemExit("missing template variables: " + ", ".join(sorted(missing)))
    unresolved = sorted(set(PATTERN.findall(output)))
    if unresolved:
        raise SystemExit("unresolved template variables: " + ", ".join(unresolved))
    return output


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("template", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(render(args.template.read_text()))


if __name__ == "__main__":
    main()
