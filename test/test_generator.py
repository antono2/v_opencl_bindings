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

    def test_complete_core_api_constants_are_emitted(self) -> None:
        generated = self.generate()
        self.assertIn("pub const device_max_compute_units = DeviceInfo(0x1002)", generated)
        self.assertIn("pub const mem_read_write = MemFlags(1 << 0)", generated)
        self.assertIn("pub const rgba = ChannelOrder(0x10B5)", generated)
        self.assertIn("pub const command_svm_migrate_mem = CommandType(0x120E)", generated)
        self.assertIn("pub const blocking = Bool(_true)", generated)
        self.assertIn("pub const non_blocking = Bool(_false)", generated)
        self.assertIn("pub const _global = DeviceLocalMemType(0x2)", generated)
        self.assertIn("pub const _none = DeviceMemCacheType(0x0)", generated)
        self.assertEqual(generated.count("pub const "), 461)

    def test_opencl_1_0_types_and_structs_are_emitted(self) -> None:
        generated = self.generate()
        self.assertIn("pub type PlatformId = voidptr", generated)
        self.assertIn("pub type ContextProperties = isize", generated)
        self.assertIn("pub type DeviceType = u64", generated)
        self.assertIn("pub struct ImageFormat", generated)
        self.assertIn("image_channel_data_type ChannelType", generated)
        self.assertIn("pub struct BufferRegion", generated)

    def test_output_is_deterministic(self) -> None:
        self.assertEqual(self.generate(), self.generate())

    def test_opencl_1_0_commands_are_generated_from_xml(self) -> None:
        generated = self.generate()
        self.assertIn("fn C.clCreateContext(&isize, u32, &DeviceId, voidptr", generated)
        self.assertIn("pub fn get_platform_ids(", generated)
        self.assertIn("pub fn enqueue_nd_range_kernel(", generated)
        self.assertIn("pub fn get_supported_image_formats(", generated)
        self.assertEqual(generated.count("@[inline]\npub fn "), 114)

    def test_opencl_1_1_types_constants_and_commands_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type BufferCreateType = u32", generated)
        self.assertIn("pub const complete = i32(0x0)", generated)
        self.assertIn("pub fn create_user_event(", generated)
        self.assertIn("pub fn enqueue_copy_buffer_rect(", generated)

    def test_opencl_1_2_types_structs_and_commands_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type DevicePartitionProperty = isize", generated)
        self.assertIn("pub type MemMigrationFlags = u64", generated)
        self.assertIn("pub struct ImageDesc", generated)
        self.assertIn("buffer Mem", generated)
        self.assertIn("pub fn create_sub_devices(", generated)
        self.assertIn("pub fn enqueue_marker_with_wait_list(", generated)

    def test_opencl_2_0_types_and_commands_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type DeviceSvmCapabilities = u64", generated)
        self.assertIn("pub type QueueProperties = u64", generated)
        self.assertIn("pub fn create_command_queue_with_properties(", generated)
        self.assertIn("pub fn svm_alloc(", generated)
        self.assertIn("pub fn enqueue_svm_memcpy(", generated)
        self.assertIn("svm_pointers &voidptr", generated)

    def test_opencl_2_1_types_constants_and_commands_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type KernelSubGroupInfo = u32", generated)
        self.assertIn("pub const platform_host_timer_resolution = PlatformInfo(0x0905)", generated)
        self.assertIn("pub fn get_device_and_host_timer(", generated)
        self.assertIn("pub fn create_program_with_il(", generated)
        self.assertIn("pub fn enqueue_svm_migrate_mem(", generated)

    def test_opencl_2_2_commands_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub fn set_program_specialization_constant(", generated)
        self.assertIn("pub fn set_program_release_callback(", generated)

    def test_opencl_3_0_types_constants_and_commands_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type Version = u32", generated)
        self.assertIn("pub struct NameVersion", generated)
        self.assertIn("name [name_version_max_name_size]i8", generated)
        self.assertIn("pub const platform_numeric_version = PlatformInfo(0x0906)", generated)
        self.assertIn("pub fn set_context_destructor_callback(", generated)
        self.assertIn("pub fn create_buffer_with_properties(", generated)


if __name__ == "__main__":
    unittest.main()
