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


if __name__ == "__main__":
    unittest.main()
