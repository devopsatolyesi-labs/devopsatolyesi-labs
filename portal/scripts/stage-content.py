#!/usr/bin/env python3
"""Stage the portal from canonical content without publishing solutions."""

from __future__ import annotations

import json
import re
import shlex
import shutil
import sys
import zipfile
from pathlib import Path


LANGUAGES = {
    ".conf": "nginx",
    ".dockerfile": "dockerfile",
    ".html": "html",
    ".ini": "ini",
    ".java": "java",
    ".js": "javascript",
    ".json": "json",
    ".md": "markdown",
    ".py": "python",
    ".sh": "bash",
    ".tf": "hcl",
    ".toml": "toml",
    ".xml": "xml",
    ".yaml": "yaml",
    ".yml": "yaml",
}


def display_language(path: Path) -> str:
    if path.name.startswith("Dockerfile"):
        return "dockerfile"
    return LANGUAGES.get(path.suffix.lower(), "text")


def visible_lab_files(assets: Path) -> list[tuple[Path, Path]]:
    files: list[tuple[Path, Path]] = []
    for directory_name in ("starter", "scripts"):
        directory = assets / directory_name
        if not directory.is_dir():
            continue
        for asset in sorted(directory.rglob("*")):
            if (
                asset.is_file()
                and not asset.is_symlink()
                and "__pycache__" not in asset.parts
                and asset.suffix != ".pyc"
            ):
                files.append((asset, Path(directory_name) / asset.relative_to(directory)))
    return files


def render_visible_lab_files(assets: Path, lab_id: str) -> str:
    files = visible_lab_files(assets)
    if not files:
        return ""
    output = ["", "## ZIP İndirmeden Dosyaları Oluşturma", ""]
    output.extend(
        [
            "Aşağıdaki bloklar ZIP paketiyle birebir aynı dosyaları oluşturur.",
            "",
            "```bash",
            f"mkdir -p ~/labs/{lab_id}",
            f"cd ~/labs/{lab_id}",
            "```",
        ]
    )
    for index, (source, relative) in enumerate(files, start=1):
        content = source.read_text(encoding="utf-8")
        delimiter = f"LAB_FILE_EOF_{index}"
        while delimiter in content.splitlines():
            delimiter += "_X"
        target = shlex.quote(relative.as_posix())
        output.extend(
            [
                "",
                f"### `{relative.as_posix()}`",
                "",
                "```bash",
                f"mkdir -p \"$(dirname -- {target})\"",
                f"cat > {target} <<'{delimiter}'",
                content.rstrip(),
                delimiter,
            ]
        )
        if relative.parts[0] == "scripts":
            output.append(f"chmod +x {target}")
        output.append("```")
    if any(relative.parts[0] == "starter" for _, relative in files):
        output.extend(
            [
                "",
                "Başlangıç dosyalarını çalışma dizinine alın:",
                "",
                "```bash",
                "cp -a starter/. .",
                "```",
            ]
        )
    return "\n".join(output) + "\n"


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def studentize_guide(content: str) -> str:
    content = re.sub(
        r"^## Metadata\s*\n.*?(?=^##\s)", "", content, flags=re.MULTILINE | re.DOTALL
    )
    return re.sub(
        r"^- \*\*(?:Süre|Tahmini Süre):\*\*.*\n", "", content, flags=re.MULTILINE
    )


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
    for unsafe in (docs / "labs", docs / "lab-assets", docs / "downloads"):
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
        canonical_guide = source.read_text(encoding="utf-8")
        package_guide = studentize_guide(canonical_guide)
        guide = package_guide.replace("../../lab-assets/", "../lab-assets/")
        guide_lines = guide.splitlines()
        guide_lines.insert(
            1,
            f"\n> [Bu labın başlangıç dosyalarını indir (ZIP)](/downloads/{lab['id']}.zip)"
            " — paket README, starter ve doğrulama scriptlerini içerir; çözüm içermez.\n",
        )
        assets = training.parent / lab["assets"]
        guide_lines.insert(
            2,
            f"\nİndirdikten sonra terminalde: `unzip {lab['id']}.zip && cd {lab['id']}`\n"
            + render_visible_lab_files(assets, lab["id"]),
        )
        guide = "\n".join(guide_lines) + "\n"
        candidates[0].write_text(guide, encoding="utf-8")

        download = docs / "downloads" / f"{lab['id']}.zip"
        download.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(download, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr(f"{lab['id']}/README.md", package_guide)
            for asset, relative in visible_lab_files(assets):
                archive.write(asset, f"{lab['id']}/{relative.as_posix()}")
            images = assets / "images"
            if images.is_dir():
                for asset in sorted(images.rglob("*")):
                    if asset.is_file() and not asset.is_symlink():
                        archive.write(asset, f"{lab['id']}/images/{asset.relative_to(images)}")

        # Only presentation images are directly browsable. Starter files and
        # scripts are distributed through the authorized ZIP; solutions stay out.
        images = training.parent / lab["assets"] / "images"
        if images.is_dir():
            destination = docs / "lab-assets" / lab["id"] / "images"
            shutil.copytree(images, destination)

    # Student-facing pages do not promise completion times. Timing remains in
    # the admin curriculum/catalog for lesson planning.
    for student_guide in docs.glob("day*/LAB-*.md"):
        content = student_guide.read_text(encoding="utf-8")
        content = studentize_guide(content)
        student_guide.write_text(content, encoding="utf-8")


if __name__ == "__main__":
    main()
