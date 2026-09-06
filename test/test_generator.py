#!/usr/bin/env python3

from pathlib import Path
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "src"))

from opencl_generator import OpenCLGenerator  # noqa: E402


class OpenCLGeneratorTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.registry = ROOT / "opencldocs" / "xml" / "cl.xml"
        if not cls.registry.is_file():
            raise unittest.SkipTest("clone KhronosGroup/OpenCL-Docs into opencldocs")

    def generate(self) -> str:
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "opencl.v"
            OpenCLGenerator(self.registry).write(output)
            return output.read_text(encoding="utf-8")

    def test_values_are_read_from_registry(self) -> None:
        generated = self.generate()
        self.assertIn("pub const invalid_value = ErrorCode(-30)", generated)
        self.assertIn("pub const device_type_gpu = DeviceType(1 << 2)", generated)
        self.assertIn("pub const platform_name = PlatformInfo(0x0902)", generated)

    def test_complete_core_error_range_is_emitted(self) -> None:
        generated = self.generate()
        self.assertIn("pub const success = ErrorCode(0)", generated)
        self.assertIn("pub const max_size_restriction_exceeded = ErrorCode(-72)", generated)
        self.assertIn("pub const platform_not_found_khr = ErrorCode(-1001)", generated)

    def test_output_is_deterministic(self) -> None:
        self.assertEqual(self.generate(), self.generate())


if __name__ == "__main__":
    unittest.main()

