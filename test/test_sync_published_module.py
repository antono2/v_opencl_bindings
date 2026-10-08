#!/usr/bin/env python3
# Checks publication manifests, metadata and synchronization into the distribution repository.

from pathlib import Path
from contextlib import redirect_stdout
import io
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import sync_published_module  # noqa: E402


class SyncPublishedModuleTests(unittest.TestCase):
    def make_target(self, directory: str) -> Path:
        target = Path(directory)
        (target / "v.mod").write_text(
            "Module {\n"
            "\tname: 'antono2.opencl'\n"
            "\tversion: '0.0.0'\n"
            "}\n"
        )
        return target

    def test_sync_records_and_checks_generator_commit(self) -> None:
        generator_commit = "a" * 40
        with tempfile.TemporaryDirectory() as directory:
            target = self.make_target(directory)

            with redirect_stdout(io.StringIO()):
                sync_result = sync_published_module.sync(
                    target, check=False, generator_commit=generator_commit
                )
            self.assertEqual(sync_result, 0)
            self.assertEqual(
                (target / "GENERATOR_COMMIT").read_text(), generator_commit + "\n"
            )
            version = (ROOT / "VERSION").read_text().strip()
            module_file = (target / "v.mod").read_text()
            self.assertIn("name: 'antono2.opencl'", module_file)
            self.assertIn(f"version: '{version}'", module_file)
            self.assertEqual((target / "VERSION").read_text().strip(), version)
            manifest = (target / sync_published_module.MANIFEST_FILE).read_text()
            self.assertIn(".gitignore\n", manifest)
            self.assertIn("README.md\n", manifest)
            self.assertIn(
                "```sh\nv install antono2.opencl\n```",
                (target / "README.md").read_text(),
            )
            self.assertIn(
                f"This checkout's package version is `{version}`",
                (target / "README.md").read_text(),
            )
            self.assertNotIn("v install antono2.opencl@", (target / "README.md").read_text())
            self.assertIn("examples/vulkan_particles/README.md\n", manifest)
            self.assertEqual(
                (target / ".gitignore").read_bytes(), (ROOT / ".gitignore").read_bytes()
            )
            self.assertEqual(
                (target / "image.v").read_bytes(), (ROOT / "src/image.v").read_bytes()
            )
            self.assertEqual(
                (target / "svm.v").read_bytes(), (ROOT / "src/svm.v").read_bytes()
            )
            with redirect_stdout(io.StringIO()):
                check_result = sync_published_module.sync(
                    target, check=True, generator_commit=generator_commit
                )
                drift_result = sync_published_module.sync(
                    target, check=True, generator_commit="b" * 40
                )
            self.assertEqual(check_result, 0)
            self.assertEqual(drift_result, 1)

    def test_generator_commit_must_be_a_full_sha(self) -> None:
        with self.assertRaisesRegex(ValueError, "full 40-character Git SHA"):
            sync_published_module.resolve_generator_commit("abc123")

    def test_check_detects_published_version_drift(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = self.make_target(directory)
            with redirect_stdout(io.StringIO()):
                sync_published_module.sync(
                    target, check=False, generator_commit="a" * 40
                )
            module_file = (target / "v.mod").read_text()
            version = (ROOT / "VERSION").read_text().strip()
            (target / "v.mod").write_text(
                module_file.replace(f"version: '{version}'", "version: '9.9.9'")
            )

            with redirect_stdout(io.StringIO()):
                result = sync_published_module.sync(
                    target, check=True, generator_commit="a" * 40
                )
            self.assertEqual(result, 1)

    def test_readme_tracks_package_metadata_without_pinning_installation(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = self.make_target(directory)
            with patch.object(
                sync_published_module, "resolve_distribution_version", return_value="2.3.4"
            ):
                with redirect_stdout(io.StringIO()):
                    sync_published_module.sync(
                        target, check=False, generator_commit="a" * 40
                    )
            readme = (target / "README.md").read_text()
            self.assertIn("```sh\nv install antono2.opencl\n```", readme)
            self.assertIn("This checkout's package version is `2.3.4`", readme)
            self.assertNotIn("v install antono2.opencl@", readme)
            self.assertNotIn("releases/tag/v2.3.4", readme)
            self.assertIn("append `@<tag>`", readme)
            self.assertNotIn("@VERSION@", readme)

    def test_check_detects_and_sync_repairs_readme_drift(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = self.make_target(directory)
            with redirect_stdout(io.StringIO()):
                sync_published_module.sync(
                    target, check=False, generator_commit="a" * 40
                )
            expected = (target / "README.md").read_bytes()
            (target / "README.md").write_text("Stale installation instructions\n")
            with redirect_stdout(io.StringIO()):
                result = sync_published_module.sync(
                    target, check=True, generator_commit="a" * 40
                )
            self.assertEqual(result, 1)
            self.assertEqual(
                (target / "README.md").read_text(), "Stale installation instructions\n"
            )
            with redirect_stdout(io.StringIO()):
                sync_published_module.sync(
                    target, check=False, generator_commit="a" * 40
                )
                result = sync_published_module.sync(
                    target, check=True, generator_commit="a" * 40
                )
            self.assertEqual(result, 0)
            self.assertEqual((target / "README.md").read_bytes(), expected)

    def test_readme_rejects_missing_and_unknown_placeholders(self) -> None:
        with patch.object(Path, "read_text", return_value="No release placeholder"):
            with self.assertRaisesRegex(ValueError, "must contain @VERSION@"):
                sync_published_module.published_readme("2.3.4")
        with patch.object(Path, "read_text", return_value="@VERSION@ @UNKNOWN@"):
            with self.assertRaisesRegex(ValueError, "unknown published README placeholders"):
                sync_published_module.published_readme("2.3.4")

    def test_sync_removes_files_from_the_previous_distribution_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = self.make_target(directory)
            generator_commit = "a" * 40
            with redirect_stdout(io.StringIO()):
                sync_published_module.sync(
                    target, check=False, generator_commit=generator_commit
                )

            stale = target / "examples/obsolete.txt"
            stale.parent.mkdir(parents=True, exist_ok=True)
            stale.write_text("obsolete\n")
            manifest = target / sync_published_module.MANIFEST_FILE
            manifest.write_text(manifest.read_text() + "examples/obsolete.txt\n")

            output = io.StringIO()
            with redirect_stdout(output):
                check_result = sync_published_module.sync(
                    target, check=True, generator_commit=generator_commit
                )
            self.assertEqual(check_result, 1)
            self.assertIn("examples/obsolete.txt (remove)", output.getvalue())
            self.assertTrue(stale.is_file())

            with redirect_stdout(io.StringIO()):
                sync_result = sync_published_module.sync(
                    target, check=False, generator_commit=generator_commit
                )
                clean_result = sync_published_module.sync(
                    target, check=True, generator_commit=generator_commit
                )
            self.assertEqual(sync_result, 0)
            self.assertEqual(clean_result, 0)
            self.assertFalse(stale.exists())

    def test_sync_rejects_unsafe_manifest_paths(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            target = self.make_target(directory)
            (target / sync_published_module.MANIFEST_FILE).write_text(
                "# managed paths\n../outside.txt\n"
            )
            with self.assertRaisesRegex(ValueError, "unsafe path"):
                sync_published_module.sync(
                    target, check=False, generator_commit="a" * 40
                )


if __name__ == "__main__":
    unittest.main()
