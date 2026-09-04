#!/usr/bin/env python3
import json
import shutil
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path


REPOSITORY = Path(__file__).resolve().parents[2]


class StageContentTest(unittest.TestCase):
    def test_portal_javascript_handles_tabs_and_mermaid(self) -> None:
        javascript = (REPOSITORY / "portal/docs/javascripts/open_in_new_tab.js").read_text()
        self.assertIn("a.md-tabs__link[href]", javascript)
        self.assertIn("window.mermaid.run", javascript)
        self.assertIn('typeof document$ !== "undefined"', javascript)

    def test_student_pages_and_archives_use_the_same_safe_files(self) -> None:
        catalog = json.loads((REPOSITORY / "training-content/catalog.json").read_text())
        with tempfile.TemporaryDirectory() as temporary:
            docs = Path(temporary) / "docs"
            shutil.copytree(REPOSITORY / "portal/docs", docs)
            subprocess.run(
                [
                    "python3",
                    str(REPOSITORY / "portal/scripts/stage-content.py"),
                    str(REPOSITORY / "training-content"),
                    str(docs),
                ],
                check=True,
            )

            archives = sorted((docs / "downloads").glob("*.zip"))
            self.assertEqual(len(archives), len(catalog["labs"]))

            for lab in catalog["labs"]:
                archive_path = docs / "downloads" / f"{lab['id']}.zip"
                self.assertTrue(archive_path.is_file())
                with zipfile.ZipFile(archive_path) as archive:
                    names = archive.namelist()
                    self.assertIn(f"{lab['id']}/README.md", names)
                    self.assertFalse(any("/solution/" in name for name in names))
                    self.assertFalse(any("__pycache__" in name or name.endswith(".pyc") for name in names))

                    assets = REPOSITORY / lab["assets"]
                    for area in ("starter", "scripts"):
                        directory = assets / area
                        if not directory.is_dir():
                            continue
                        for source in directory.rglob("*"):
                            if not source.is_file() or source.is_symlink() or "__pycache__" in source.parts or source.suffix == ".pyc":
                                continue
                            relative = source.relative_to(directory).as_posix()
                            name = f"{lab['id']}/{area}/{relative}"
                            self.assertEqual(archive.read(name), source.read_bytes())

                source_name = Path(lab["guide"]).name
                candidates = list(docs.glob(f"day*/{source_name}")) + list(docs.glob(f"env/{source_name}"))
                self.assertEqual(len(candidates), 1)
                page = candidates[0].read_text()
                self.assertNotIn("## Metadata", page)
                self.assertIn(f"/downloads/{lab['id']}.zip", page)
                self.assertNotIn("## Kaynak", page)


    def test_role_based_access_rules(self) -> None:
        import re
        catalog = json.loads((REPOSITORY / "training-content/catalog.json").read_text())
        nginx_conf = (REPOSITORY / "portal/nginx.conf").read_text()
        js_code = (REPOSITORY / "portal/docs/javascripts/open_in_new_tab.js").read_text()

        # Extract map "$portal_course:$uri" $portal_allowed from nginx.conf
        map_match = re.search(r'map\s+"\$portal_course:\$uri"\s+\$portal_allowed\s*\{([^}]+)\}', nginx_conf)
        self.assertIsNotNone(map_match)
        map_body = map_match.group(1)
        nginx_patterns = []
        for line in map_body.splitlines():
            line = line.strip()
            if not line or line.startswith("#") or line.startswith("default"):
                continue
            m = re.match(r'~([^ ]+)\s+([0-9]+);', line)
            if m:
                nginx_patterns.append((m.group(1), int(m.group(2))))

        def check_nginx(role: str, uri: str) -> int:
            key = f"{role}:{uri}"
            for pat, val in nginx_patterns:
                if re.search(pat, key):
                    return val
            return 0

        def normalize_js_path(pathname: str) -> str:
            p = pathname.split("?")[0].split("#")[0]
            p = re.sub(r"/index\.html$", "", p)
            p = re.sub(r"\.html$", "", p)
            if len(p) > 1 and p.endswith("/"):
                p = p[:-1]
            return p

        def can_open_js(pathname: str, access_role: str) -> bool:
            if not pathname:
                return True
            if access_role == "admin":
                return True
            p = normalize_js_path(pathname)
            if p.startswith("/env") or p.startswith("/labs") or p.startswith("/lab-assets") or p == "/devops-labs.zip":
                return False
            if p in ("", "/", "/index.html") or p.startswith("/search") or p.startswith("/reference"):
                return True
            if access_role == "devops":
                if p.startswith("/curriculum") or p.startswith("/setup") or p.startswith("/projects") or p.startswith("/troubleshooting"):
                    return True
                if re.match(r"^/day[1-5]/LAB-[A-Za-z0-9_-]+$", p):
                    return True
                if re.match(r"^/downloads/LAB-[A-Za-z0-9_-]+\.zip$", p):
                    return True
                return False
            if access_role in ("kubernetes", "docker"):
                if p in ("/curriculum/02_2_DAY_DOCKER_KUBERNETES", "/curriculum/02_LAB_CATALOG_INDEX", "/curriculum/06_DEMO_APPLICATION_MAPPING"):
                    return True
                if p in (
                    "/setup",
                    "/setup/docker-engine",
                    "/setup/kind-cluster",
                    "/setup/kubeadm-cluster",
                    "/setup/kubeconfig-management",
                    "/setup/nfs-storageclass",
                    "/setup/docker-kubernetes",
                ):
                    return True
                if re.match(r"^/day[12]/LAB-DOC-[A-Za-z0-9_-]+$", p):
                    return True
                if re.match(r"^/day4/LAB-K8S-[A-Za-z0-9_-]+$", p):
                    return True
                if re.match(r"^/downloads/LAB-(?:DOC|K8S)-[A-Za-z0-9_-]+\.zip$", p):
                    return True
                return False
            return False

        # Verify JS contains dynamic pattern matching and not obsolete hardcoded slug regexes
        self.assertIn(r"/^\/day[1-5]\/LAB-[A-Za-z0-9_-]+$/", js_code)
        self.assertIn(r"/^\/day[12]\/LAB-DOC-[A-Za-z0-9_-]+$/", js_code)
        self.assertIn(r"/^\/day4\/LAB-K8S-[A-Za-z0-9_-]+$/", js_code)
        self.assertNotIn("01-kind-pods-deployments", js_code)
        self.assertNotIn("JNK-01", js_code)

        # Test each lab against both JS logic and Nginx configuration
        for lab in catalog["labs"]:
            lab_id = lab["id"]
            filename = Path(lab["guide"]).name
            slug = filename.replace(".md", "")
            candidates = list((REPOSITORY / "portal/docs").glob(f"day*/{filename}")) + list((REPOSITORY / "portal/docs").glob(f"env/{filename}"))
            self.assertTrue(len(candidates) == 1, f"Missing portal candidate for {lab_id}")
            day_or_env = candidates[0].relative_to(REPOSITORY / "portal/docs").parts[0]
            url = f"/{day_or_env}/{slug}/"
            download_url = f"/downloads/{lab_id}.zip"

            # Admin must access everything
            self.assertTrue(can_open_js(url, "admin"))
            self.assertEqual(check_nginx("admin", url), 1)

            # DevOps role
            if lab_id.startswith("LAB-ENV"):
                self.assertFalse(can_open_js(url, "devops"))
                self.assertEqual(check_nginx("devops", url), 0)
            else:
                self.assertTrue(can_open_js(url, "devops"), f"devops should access {url}")
                self.assertTrue(can_open_js(download_url, "devops"), f"devops should download {download_url}")
                self.assertEqual(check_nginx("devops", url), 1, f"nginx blocked devops on {url}")
                self.assertEqual(check_nginx("devops", download_url), 1, f"nginx blocked devops on {download_url}")

            # Kubernetes role
            if lab_id.startswith("LAB-DOC") or lab_id.startswith("LAB-K8S"):
                self.assertTrue(can_open_js(url, "kubernetes"), f"kubernetes should access {url}")
                self.assertTrue(can_open_js(download_url, "kubernetes"), f"kubernetes should download {download_url}")
                self.assertEqual(check_nginx("kubernetes", url), 1, f"nginx blocked kubernetes on {url}")
                self.assertEqual(check_nginx("kubernetes", download_url), 1, f"nginx blocked kubernetes on {download_url}")
            else:
                self.assertFalse(can_open_js(url, "kubernetes"), f"kubernetes must NOT access {url}")
                self.assertFalse(can_open_js(download_url, "kubernetes"), f"kubernetes must NOT download {download_url}")
                self.assertEqual(check_nginx("kubernetes", url), 0, f"nginx allowed kubernetes on {url}")
                self.assertEqual(check_nginx("kubernetes", download_url), 0, f"nginx allowed kubernetes on {download_url}")


if __name__ == "__main__":
    unittest.main()

