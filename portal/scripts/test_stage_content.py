#!/usr/bin/env python3
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path

REPOSITORY = Path(__file__).resolve().parents[2]


def stage(root: Path) -> Path:
    docs = root / "docs"
    shutil.copytree(REPOSITORY / "portal/docs", docs)
    subprocess.run([
        "python3", str(REPOSITORY / "portal/scripts/stage-content.py"),
        str(REPOSITORY / "training-content"), str(docs),
    ], check=True)
    return docs


def normalized_routes(lab: dict) -> set[str]:
    folder = Path(lab["guide"]).parent.name
    route = f"/{folder}/{lab['slug']}"
    return {route, route + "/", route + ".html", f"/downloads/{lab['id']}.zip"}


class StageContentTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.catalog = json.loads((REPOSITORY / "training-content/catalog.json").read_text())
        cls.temporary = tempfile.TemporaryDirectory()
        cls.docs = stage(Path(cls.temporary.name))

    @classmethod
    def tearDownClass(cls) -> None:
        cls.temporary.cleanup()

    def test_catalog_contract_and_membership_are_consistent(self) -> None:
        required = {"id", "slug", "title", "topic", "difficulty", "estimated_minutes", "prerequisites", "profiles", "ports", "guide", "assets", "validation_mode", "learning_paths", "access_tags"}
        lab_ids = {lab["id"] for lab in self.catalog["labs"]}
        self.assertEqual(len(lab_ids), len(self.catalog["labs"]))
        for lab in self.catalog["labs"]:
            self.assertFalse(required - lab.keys(), f"missing fields for {lab['id']}")
            self.assertTrue((REPOSITORY / lab["guide"]).is_file())
            self.assertTrue((REPOSITORY / lab["assets"]).is_dir())
        for course in self.catalog["courses"]:
            module_ids = [item for module in course["modules"] for item in module["labs"]]
            self.assertEqual(course["lab_ids"], module_ids)
            self.assertTrue(set(course["lab_ids"]) <= lab_ids)
            self.assertEqual(len(course["topic_headings"]), len(course["coverage"]))
            self.assertNotIn("source", course)
            project_ids = set(course["project_ids"])
            for coverage in course["coverage"]:
                self.assertIn(coverage["heading"], course["topic_headings"])
                self.assertIn(coverage["status"], {"covered", "partial", "missing"})
                self.assertTrue(coverage["targets"])
                self.assertTrue(set(coverage["targets"]) <= (set(course["lab_ids"]) | project_ids))

    def test_student_pages_are_plain_and_not_duplicated(self) -> None:
        prohibited = ("[!TIP]", "İnteraktif Alıştırmalar", "Production Notu", "## Challenge", "## Kaynak", "Cheat Sheet", "/solution/")
        for lab in self.catalog["labs"]:
            page = self.docs / Path(lab["guide"]).parent.name / Path(lab["guide"]).name
            content = page.read_text()
            self.assertEqual(content.count("| Seviye | Tahmini Süre | Profil / Araçlar | Açık Portlar |"), 1, lab["id"])
            self.assertEqual(content.count(f"[{lab['id']}.zip]"), 1, lab["id"])
            for phrase in prohibited:
                self.assertNotIn(phrase, content, f"{phrase} leaked into {lab['id']}")

    def test_lab_archives_publish_starter_files_without_solutions(self) -> None:
        lab_archives = sorted((self.docs / "downloads").glob("LAB-*.zip"))
        self.assertEqual(len(lab_archives), len(self.catalog["labs"]))
        for lab in self.catalog["labs"]:
            with zipfile.ZipFile(self.docs / "downloads" / f"{lab['id']}.zip") as archive:
                names = archive.namelist()
                self.assertIn(f"{lab['id']}/README.md", names)
                self.assertFalse(any("/solution/" in name for name in names))
                self.assertFalse(any("__pycache__" in name or name.endswith(".pyc") for name in names))

    def test_course_archives_are_exact_reproducible_and_unbranded(self) -> None:
        second_root = Path(tempfile.mkdtemp(dir=self.temporary.name))
        second_docs = stage(second_root)
        projects = {project["id"]: project for project in self.catalog["projects"]}
        for course in self.catalog["courses"]:
            archive_path = self.docs / "downloads" / f"{course['id']}.zip"
            second_path = second_docs / "downloads" / f"{course['id']}.zip"
            self.assertEqual(hashlib.sha256(archive_path.read_bytes()).digest(), hashlib.sha256(second_path.read_bytes()).digest())
            with zipfile.ZipFile(archive_path) as archive:
                names = archive.namelist()
                root = course["id"]
                self.assertIn(f"{root}/README.md", names)
                self.assertIn(f"{root}/EGITIM_KONULARI.md", names)
                packaged_labs = {match.group(1) for name in names if (match := re.search(r"/labs/\d+-(LAB-[A-Z0-9-]+)/README\.md$", name))}
                self.assertEqual(packaged_labs, set(course["lab_ids"]))
                packaged_projects = {match.group(1) for name in names if (match := re.search(r"/projects/\d+-(PROJECT-[A-Z0-9-]+)/README\.md$", name))}
                self.assertEqual(packaged_projects, set(course["project_ids"]))
                self.assertTrue(set(course["project_ids"]) <= projects.keys())
                self.assertFalse(any("/solution/" in name for name in names))
                text = "\n".join(archive.read(name).decode("utf-8", "ignore") for name in names if name.endswith(".md"))
                self.assertNotIn("bilginc.com", text.lower())
                self.assertNotIn("bilginç", text.lower())

    def test_server_and_browser_share_exact_generated_policy(self) -> None:
        nginx = (REPOSITORY / "portal/nginx.conf").read_text()
        self.assertIn("include /etc/nginx/course-access.map;", nginx)
        policy_js = (self.docs / "javascripts/course_access.js").read_text()
        policy = json.loads(policy_js.removeprefix("window.PORTAL_ACCESS_POLICY = ").removesuffix(";\n"))
        map_text = (self.docs.parent / "course-access.map").read_text()
        labs = {lab["id"]: lab for lab in self.catalog["labs"]}
        for course in self.catalog["courses"]:
            allowed = set(policy["roles"][course["access_role"]]["paths"])
            expected = set().union(*(normalized_routes(labs[lab_id]) for lab_id in course["lab_ids"]))
            self.assertTrue(expected <= allowed)
            for route in expected:
                self.assertIn(f"~^{course['access_role']}:{re.escape(route)}$ 1;", map_text)
        kubernetes_allowed = set(policy["roles"]["kubernetes"]["paths"])
        self.assertNotIn("/docker/LAB-DOC-11-docker-java-spring-boot", kubernetes_allowed)
        self.assertIn("/docker/LAB-DOC-10-docker-runtime-security", kubernetes_allowed)
        self.assertNotIn("/projects/PROJECT-DEVOPS-01-uc-tan-uca-devops", kubernetes_allowed)
        self.assertIn("/projects/PROJECT-DK-01-containerdan-kubernetese", kubernetes_allowed)

    def test_navigation_is_simplified(self) -> None:
        config = (REPOSITORY / "portal/mkdocs.yml").read_text()
        self.assertIn("- IaC:", config)
        self.assertIn("- Monitoring:", config)
        self.assertNotIn("- Capstone:", config)
        self.assertNotIn("- Troubleshooting:", config)
        self.assertNotIn("- Hızlı Referans:", config)
        javascript = (REPOSITORY / "portal/docs/javascripts/open_in_new_tab.js").read_text()
        self.assertIn("window.PORTAL_ACCESS_POLICY", javascript)
        self.assertNotIn("All 20 Docker labs", javascript)
        mermaid = (REPOSITORY / "portal/docs/javascripts/mermaid-init.js").read_text()
        self.assertIn("window.mermaid.run", mermaid)
        self.assertNotIn("navigation.top", config)

    def test_rendered_guides_have_no_unsupported_alert_syntax(self) -> None:
        for page in self.docs.rglob("*.md"):
            content = page.read_text()
            self.assertNotIn("[!NOTE]", content, page)
            self.assertNotIn("[!TIP]", content, page)


if __name__ == "__main__":
    unittest.main()
