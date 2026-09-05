#!/usr/bin/env python3
"""Build learner pages, reproducible downloads, and access policy from the catalog."""

from __future__ import annotations

import json
import re
import shutil
import sys
import zipfile
from pathlib import Path

FIXED_ZIP_TIME = (2026, 1, 1, 0, 0, 0)
SKIPPED_SECTION = re.compile(
    r"^(?:\d+\.\s*)?(?:İnteraktif Alıştırmalar ve Senaryo Soruları|.*Production.*|.*Üretim Not.*|Challenge.*|"
    r"Kaynak(?: ve Referanslar)?|Hızlı Referans|.*Cheat Sheet.*|.*Sorun Giderme.*|"
    r".*Temizlik.*|Codex Implementation Notes)$",
    re.IGNORECASE,
)


def remove_path(path: Path) -> None:
    if path.is_symlink() or path.is_file():
        path.unlink()
    elif path.is_dir():
        shutil.rmtree(path)


def visible_files(assets: Path | None) -> list[tuple[Path, Path]]:
    if assets is None:
        return []
    files: list[tuple[Path, Path]] = []
    for directory_name in ("starter", "scripts"):
        directory = assets / directory_name
        if not directory.is_dir():
            continue
        for asset in sorted(directory.rglob("*")):
            if asset.is_file() and not asset.is_symlink() and "__pycache__" not in asset.parts and asset.suffix != ".pyc":
                files.append((asset, Path(directory_name) / asset.relative_to(directory)))
    return files


def plain_lab_header(lab: dict) -> str:
    difficulty = {100: "Temel", 200: "Orta", 300: "İleri", 400: "Proje"}.get(lab.get("difficulty"), "Orta")
    profiles = ", ".join(lab.get("profiles", [])) or "-"
    ports = ", ".join(str(port) for port in lab.get("ports", [])) or "Küme içi"
    return "\n".join([
        "", "| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |",
        "| --- | --- | --- | --- |",
        f"| {difficulty} | {lab.get('estimated_minutes', 45)} dakika | `{profiles}` | `{ports}` |",
        "", f"[{lab['id']}.zip](/downloads/{lab['id']}.zip)", "",
    ])


def strip_existing_header(content: str) -> str:
    content = re.sub(r"^## Metadata\s*\n.*?(?=^##\s)", "", content, flags=re.M | re.S)
    content = re.sub(
        r"^\|\s*(?:🎯\s*)?Seviye\s*\|.*\n^\|[-: |]+\|\s*\n^\|.*\|\s*\n?",
        "", content, flags=re.M,
    )
    content = re.sub(r"^.*(?:🟢|🟡|🔴|⏱️).*\|.*\n?", "", content, flags=re.M)
    content = re.sub(r"^>\s*\[!TIP\]\s*\n(?:^>.*\n?)+", "", content, flags=re.M)
    content = re.sub(r"^\[LAB-[A-Z0-9-]+\.zip\]\([^\n]+\)\s*$", "", content, flags=re.M)
    content = re.sub(r"^- \*\*(?:Süre|Tahmini Süre):\*\*.*\n", "", content, flags=re.M)
    return content


def normalize_admonitions(content: str) -> str:
    """Convert GitHub alert quotes to plain Markdown supported by MkDocs."""
    alert = re.compile(
        r"^>\s*\[!(?:NOTE|TIP|IMPORTANT|WARNING|CAUTION)\]\s*\n"
        r"((?:^>.*(?:\n|$))*)",
        re.MULTILINE,
    )

    def replace(match: re.Match[str]) -> str:
        body = "\n".join(
            line[1:].lstrip() if line.startswith(">") else line
            for line in match.group(1).splitlines()
        ).strip()
        return f"**Not:** {body}\n\n"

    return alert.sub(replace, content)


def studentize_guide(content: str) -> str:
    content = normalize_admonitions(content)
    content = strip_existing_header(content)
    content = re.sub(r"^.*(?:lab-assets/.*/solution/|/solution/).*$\n?", "", content, flags=re.M)
    lines = content.splitlines()
    kept: list[str] = []
    skip_level: int | None = None
    for line in lines:
        heading = re.match(r"^(#{2,6})\s+(.*)$", line)
        if heading:
            level = len(heading.group(1))
            title = re.sub(r"^[^\wÇĞİÖŞÜçğıöşü]+\s*", "", heading.group(2)).strip()
            expected_with_troubleshooting = bool(re.fullmatch(r"(?:\d+\.\s*)?Beklenen Sonuç\s*&\s*Sorun Giderme", title, flags=re.I))
            if skip_level is not None and level <= skip_level:
                skip_level = None
            if skip_level is None and not expected_with_troubleshooting and SKIPPED_SECTION.fullmatch(title):
                skip_level = level
                continue
            if skip_level is None:
                if expected_with_troubleshooting or re.fullmatch(r"(?:\d+\.\s*)?(?:Doğrulama|Beklenen Sonuç)", title, flags=re.I):
                    title = "Doğal Doğrulama ve Beklenen Sonuç"
                line = f"{heading.group(1)} {title}"
        if skip_level is None:
            kept.append(line)
    return re.sub(r"\n{3,}", "\n\n", "\n".join(kept)).strip() + "\n"


def zip_write_bytes(archive: zipfile.ZipFile, name: str, data: bytes) -> None:
    info = zipfile.ZipInfo(name, FIXED_ZIP_TIME)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    archive.writestr(info, data)


def zip_write_file(archive: zipfile.ZipFile, name: str, source: Path) -> None:
    zip_write_bytes(archive, name, source.read_bytes())


def lab_route(lab: dict) -> str:
    return f"/{Path(lab['guide']).parent.name}/{lab['slug']}"


def project_route(project: dict) -> str:
    return f"/projects/{project['slug']}"


def render_course_page(course: dict, labs_by_id: dict, projects_by_id: dict) -> str:
    lines = [f"# {course['title']}", "", f"[Eğitim Paketini İndir](/downloads/{course['id']}.zip){{ .md-button .md-button--primary }}", "", "## Eğitim Konuları", ""]
    lines.extend(f"- {heading}" for heading in course["topic_headings"])
    lines.extend(["", "## Lablar", ""])
    for lab_id in course["lab_ids"]:
        lab = labs_by_id[lab_id]
        lines.append(f"- [{lab_id} — {lab['title']}]({lab_route(lab)}/)")
    if course["project_ids"]:
        lines.extend(["", "## Projeler", ""])
        for project_id in course["project_ids"]:
            project = projects_by_id[project_id]
            lines.append(f"- [{project_id} — {project['title']}]({project_route(project)}/)")
    return "\n".join(lines) + "\n"


def add_path(paths: set[str], path: str) -> None:
    path = "/" + path.strip("/")
    paths.update({path, path + "/", path + ".html"})


def documentation_route(source: str) -> str:
    path = Path(source).with_suffix("")
    if path.name == "index":
        path = path.parent
    return path.as_posix()


def write_access_policy(docs: Path, courses: list[dict], labs_by_id: dict, projects_by_id: dict) -> None:
    policy: dict[str, dict[str, list[str]]] = {"roles": {}}
    map_lines = [
        "# Generated from training-content/catalog.json; do not edit by hand.",
        "~^admin: 1;",
        r"~^(?:devops|kubernetes):/(?:$|index\.html$|404\.html$|assets/|javascripts/|stylesheets/|favicon|search/|sitemap|robots\.txt) 1;",
    ]
    for course in courses:
        role = course["access_role"]
        paths: set[str] = set()
        add_path(paths, f"courses/{course['id']}")
        paths.add(f"/downloads/{course['id']}.zip")
        for setup in course.get("setup_pages", []):
            add_path(paths, documentation_route(setup))
        for lab_id in course["lab_ids"]:
            lab = labs_by_id[lab_id]
            add_path(paths, lab_route(lab))
            paths.add(f"/downloads/{lab_id}.zip")
            images = docs / "lab-assets" / lab_id / "images"
            if images.is_dir():
                for image in images.rglob("*"):
                    if image.is_file():
                        paths.add("/" + image.relative_to(docs).as_posix())
        for project_id in course["project_ids"]:
            add_path(paths, project_route(projects_by_id[project_id]))
        policy["roles"][role] = {"paths": sorted(paths)}
        map_lines.extend(f"~^{role}:{re.escape(path)}$ 1;" for path in sorted(paths))
    (docs / "javascripts").mkdir(parents=True, exist_ok=True)
    payload = "window.PORTAL_ACCESS_POLICY = " + json.dumps(policy, ensure_ascii=False, separators=(",", ":")) + ";\n"
    (docs / "javascripts/course_access.js").write_text(payload, encoding="utf-8")
    (docs.parent / "course-access.map").write_text("\n".join(map_lines) + "\n", encoding="utf-8")


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: stage-content.py <training-content> <portal-docs>")
    training = Path(sys.argv[1]).resolve()
    docs = Path(sys.argv[2]).resolve()
    repository = training.parent
    catalog = json.loads((training / "catalog.json").read_text(encoding="utf-8"))
    labs_by_id = {lab["id"]: lab for lab in catalog["labs"]}
    projects_by_id = {project["id"]: project for project in catalog.get("projects", [])}

    for path in sorted(docs.rglob("*"), reverse=True):
        if path.is_symlink():
            path.unlink()
    for unsafe in (
        docs / "labs", docs / "lab-assets", docs / "downloads", docs / "courses",
        docs / "curriculum", docs / "projects", docs / "troubleshooting", docs / "reference",
    ):
        remove_path(unsafe)
    for folder in {Path(lab["guide"]).parent.name for lab in catalog["labs"]}:
        remove_path(docs / folder)
    remove_path(docs / "devops-labs.zip")
    remove_path(docs / "setup/nfs-storageclass.md")
    (docs / "curriculum").mkdir(parents=True, exist_ok=True)
    for course in catalog["courses"]:
        source = repository / course["curriculum"]
        shutil.copyfile(source, docs / "curriculum" / source.name)

    for lab in catalog["labs"]:
        source = repository / lab["guide"]
        target = docs / source.parent.name / source.name
        target.parent.mkdir(parents=True, exist_ok=True)
        package_guide = studentize_guide(source.read_text(encoding="utf-8"))
        portal_guide = package_guide.replace("../../lab-assets/", "../lab-assets/")
        guide_lines = portal_guide.splitlines()
        guide_lines.insert(1, plain_lab_header(lab))
        target.write_text("\n".join(guide_lines) + "\n", encoding="utf-8")
        assets = repository / lab["assets"]
        download = docs / "downloads" / f"{lab['id']}.zip"
        download.parent.mkdir(parents=True, exist_ok=True)
        with zipfile.ZipFile(download, "w") as archive:
            zip_write_bytes(archive, f"{lab['id']}/README.md", package_guide.encode())
            for asset, relative in visible_files(assets):
                zip_write_file(archive, f"{lab['id']}/{relative.as_posix()}", asset)
        images = assets / "images"
        if images.is_dir():
            shutil.copytree(images, docs / "lab-assets" / lab["id"] / "images")

    for project in catalog.get("projects", []):
        source = repository / project["guide"]
        target = docs / "projects" / f"{project['slug']}.md"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(studentize_guide(source.read_text(encoding="utf-8")), encoding="utf-8")

    courses_dir = docs / "courses"
    courses_dir.mkdir(parents=True, exist_ok=True)
    for course in catalog["courses"]:
        (courses_dir / f"{course['id']}.md").write_text(render_course_page(course, labs_by_id, projects_by_id), encoding="utf-8")
        with zipfile.ZipFile(docs / "downloads" / f"{course['id']}.zip", "w") as archive:
            root = course["id"]
            zip_write_bytes(archive, f"{root}/README.md", (f"# {course['title']} Eğitim Paketi\n\nLabları numara sırasıyla ilerletin. Paket çözüm dosyası içermez.\n").encode())
            topics_text = "# Eğitim Konuları\n\n" + "\n".join(f"- {heading}" for heading in course["topic_headings"]) + "\n"
            zip_write_bytes(archive, f"{root}/EGITIM_KONULARI.md", topics_text.encode())
            for index, lab_id in enumerate(course["lab_ids"], 1):
                lab = labs_by_id[lab_id]
                guide = studentize_guide((repository / lab["guide"]).read_text(encoding="utf-8"))
                lab_root = f"{root}/labs/{index:02d}-{lab_id}"
                zip_write_bytes(archive, f"{lab_root}/README.md", guide.encode())
                for asset, relative in visible_files(repository / lab["assets"]):
                    zip_write_file(archive, f"{lab_root}/{relative.as_posix()}", asset)
            for index, project_id in enumerate(course["project_ids"], 1):
                project = projects_by_id[project_id]
                guide = studentize_guide((repository / project["guide"]).read_text(encoding="utf-8"))
                project_root = f"{root}/projects/{index:02d}-{project_id}"
                zip_write_bytes(archive, f"{project_root}/README.md", guide.encode())
                assets_path = repository / project["assets"] if project.get("assets") else None
                for asset, relative in visible_files(assets_path):
                    zip_write_file(archive, f"{project_root}/{relative.as_posix()}", asset)

    write_access_policy(docs, catalog["courses"], labs_by_id, projects_by_id)


if __name__ == "__main__":
    main()
