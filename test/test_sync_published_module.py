#!/usr/bin/env python3

from pathlib import Path
from contextlib import redirect_stdout
import io
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import sync_published_module  # noqa: E402


class SyncPublishedModuleTests(unittest.TestCase):
    def make_target(self, directory: str) -> Path:
        target = Path(directory)
        (target / "v.mod").write_text("Module {\n\tname: 'antono2.opencl'\n}\n")
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


if __name__ == "__main__":
    unittest.main()
