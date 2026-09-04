#!/usr/bin/env python3
"""Apply the classroom guide format to every canonical catalog lab."""

from __future__ import annotations

import json
import runpy
import sys
from pathlib import Path


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: normalize-lab-guides.py <catalog> <stage-content.py>")
    catalog_path = Path(sys.argv[1]).resolve()
    repository = catalog_path.parents[1]
    helpers = runpy.run_path(str(Path(sys.argv[2]).resolve()))
    studentize_guide = helpers["studentize_guide"]
    plain_lab_header = helpers["plain_lab_header"]
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    for lab in catalog["labs"]:
        guide = repository / lab["guide"]
        content = studentize_guide(guide.read_text(encoding="utf-8"))
        lines = content.splitlines()
        lines.insert(1, plain_lab_header(lab))
        guide.write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
