#!/usr/bin/env python3
"""Stage the portal from canonical content without publishing solutions."""

from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: stage-content.py <training-content> <portal-docs>")

    training = Path(sys.argv[1]).resolve()
    docs = Path(sys.argv[2]).resolve()
    catalog = json.loads((training / "catalog.json").read_text(encoding="utf-8"))

    # Never carry source symlinks or the old all-content ZIP into the public image.
    # Docker must receive an explicit, auditable set of regular files.
    for path in sorted(docs.rglob("*"), reverse=True):
        if path.is_symlink():
            path.unlink()
    for unsafe in (docs / "labs", docs / "lab-assets"):
        remove_path(unsafe)
    remove_path(docs / "devops-labs.zip")

    # Admin curriculum links use /labs. Publish guides only; lab assets and
    # solutions are intentionally staged separately below.
    shutil.copytree(training / "labs", docs / "labs")

    for course in catalog["courses"]:
        source = training.parent / course["curriculum"]
        shutil.copyfile(source, docs / "curriculum" / source.name)

    for lab in catalog["labs"]:
        source = training.parent / lab["guide"]
        candidates = list(docs.glob(f"day*/{source.name}")) + list(docs.glob(f"env/{source.name}"))
        if len(candidates) != 1:
            raise SystemExit(f"expected one portal target for {lab['id']}, found {len(candidates)}")
        guide = source.read_text(encoding="utf-8").replace("../../lab-assets/", "../lab-assets/")
        candidates[0].write_text(guide, encoding="utf-8")

        # Only presentation images are published. starter/scripts/solution stay out
        # of the web image and are distributed through authorized course ZIPs.
        images = training.parent / lab["assets"] / "images"
        if images.is_dir():
            destination = docs / "lab-assets" / lab["id"] / "images"
            shutil.copytree(images, destination)


if __name__ == "__main__":
    main()
