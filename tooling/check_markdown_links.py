"""Fail when a relative Markdown file link points to a missing file."""

import re
import sys
from pathlib import Path

MARKDOWN_FILE_LINK = re.compile(r"\[[^]]*]\(([^)#]+\.md)(?:#[^)]*)?\)")
IGNORED_PARTS = {".dart_tool", ".git", ".venv", "build"}


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    failures: list[str] = []
    for document in root.rglob("*.md"):
        if any(part in IGNORED_PARTS for part in document.parts):
            continue
        for link in MARKDOWN_FILE_LINK.findall(document.read_text(encoding="utf-8")):
            if "://" in link:
                continue
            if not (document.parent / link).resolve().is_file():
                failures.append(f"{document.relative_to(root)} -> {link}")
    if failures:
        print("Missing Markdown file links:", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Markdown file links are valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
