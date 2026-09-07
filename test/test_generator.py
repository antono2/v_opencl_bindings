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

    def test_platform_link_and_header_flags_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("#flag linux -lOpenCL", generated)
        self.assertIn("#flag windows -lOpenCL", generated)
        self.assertIn("#flag darwin -framework OpenCL", generated)
        self.assertIn("#include <CL/opencl.h>", generated)

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
        self.assertEqual(generated.count("pub const "), 503)

    def test_opencl_1_0_types_and_structs_are_emitted(self) -> None:
        generated = self.generate()
        self.assertIn("pub type PlatformId = voidptr", generated)
        self.assertIn("pub type ContextProperties = isize", generated)
        self.assertIn("pub type DeviceType = u64", generated)
        self.assertIn("pub struct ImageFormat", generated)
        self.assertIn("image_channel_data_type ChannelType", generated)
        self.assertIn("pub struct BufferRegion", generated)

    def test_core_callback_types_are_emitted_and_used(self) -> None:
        generated = self.generate()
        self.assertIn("$if windows {", generated)
        self.assertEqual(generated.count("@[callconv: stdcall]"), 21)
        self.assertIn("pub type ContextNotifyCallback = fn (errinfo &char, private_info voidptr, cb usize, user_data voidptr)", generated)
        self.assertIn("pub type EventCallback = fn (event Event, event_command_status i32, user_data voidptr)", generated)
        self.assertIn("pub type SvmFreeCallback = fn (queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, user_data voidptr)", generated)
        self.assertIn("fn C.clCreateContext(&ContextProperties, u32, &DeviceId, ContextNotifyCallback", generated)
        self.assertIn("pub fn set_event_callback(event Event, command_exec_callback_type i32, pfn_notify EventCallback", generated)
        self.assertIn("pub fn enqueue_native_kernel(command_queue CommandQueue, user_func NativeKernelCallback", generated)

    def test_output_is_deterministic(self) -> None:
        self.assertEqual(self.generate(), self.generate())

    def test_opencl_1_0_commands_are_generated_from_xml(self) -> None:
        generated = self.generate()
        self.assertIn("fn C.clCreateContext(&ContextProperties, u32, &DeviceId, ContextNotifyCallback", generated)
        self.assertIn("pub fn get_platform_ids(", generated)
        self.assertIn("pub fn enqueue_nd_range_kernel(", generated)
        self.assertIn("pub fn get_supported_image_formats(", generated)
        self.assertEqual(generated.count("@[inline]\npub fn "), 128)

    def test_command_signatures_preserve_semantic_typedefs(self) -> None:
        generated = self.generate()
        self.assertIn("fn C.clGetDeviceIDs(PlatformId, DeviceType, u32", generated)
        self.assertIn("pub fn get_device_info(device DeviceId, param_name DeviceInfo", generated)
        self.assertIn("pub fn create_buffer(context Context, flags MemFlags", generated)
        self.assertIn("pub fn enqueue_read_buffer(command_queue CommandQueue, buffer Mem, blocking_read Bool", generated)
        self.assertIn("pub fn create_semaphore_with_properties_khr(context Context, sema_props &SemaphorePropertiesKhr", generated)
        self.assertIn("handle_type ExternalSemaphoreHandleTypeKhr", generated)

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

    def test_portable_khr_extension_entry_points_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type QueuePropertiesKhr = u64", generated)
        self.assertIn("pub const device_il_version_khr = DeviceInfo(0x105B)", generated)
        self.assertIn("pub const kernel_max_sub_group_size_for_ndrange_khr = KernelSubGroupInfo(0x2033)", generated)
        self.assertIn("pub fn create_program_with_il_khr(", generated)
        self.assertIn("pub fn create_command_queue_with_properties_khr(", generated)
        self.assertIn("pub fn get_kernel_sub_group_info_khr(", generated)
        self.assertIn("pub fn get_kernel_suggested_local_work_size_khr(", generated)

    def test_extension_commands_are_resolved_at_runtime(self) -> None:
        generated = self.generate()
        self.assertIn("pub type PFN_clGetKernelSubGroupInfoKHR = fn (", generated)
        self.assertIn("PFN_clGetKernelSubGroupInfoKHR(C.clGetExtensionFunctionAddress(c'clGetKernelSubGroupInfoKHR'))", generated)
        self.assertNotIn("fn C.clGetKernelSubGroupInfoKHR(", generated)
        self.assertIn("if isnil(extension_fn) {\n\t\treturn invalid_operation", generated)
        self.assertIn("unsafe { *errcode_ret = invalid_operation }", generated)
        self.assertIn("return Program(unsafe { nil })", generated)

    def test_external_memory_and_semaphore_extensions_are_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub type SemaphoreKhr = voidptr", generated)
        self.assertIn("pub type ExternalSemaphoreHandleTypeKhr = u32", generated)
        self.assertIn("pub type ExternalMemoryHandleTypeKhr = u32", generated)
        self.assertIn("pub const invalid_semaphore_khr = ErrorCode(-1142)", generated)
        self.assertIn("pub const semaphore_handle_opaque_fd_khr = ExternalSemaphoreHandleTypeKhr(0x2055)", generated)
        self.assertIn("pub const semaphore_handle_sync_fd_khr = ExternalSemaphoreHandleTypeKhr(0x2058)", generated)
        self.assertIn("pub const external_memory_handle_dma_buf_khr = ExternalMemoryHandleTypeKhr(0x2067)", generated)
        self.assertIn("pub const external_memory_handle_opaque_fd_khr = ExternalMemoryHandleTypeKhr(0x2060)", generated)
        self.assertIn("pub fn create_semaphore_with_properties_khr(", generated)
        self.assertIn("pub fn get_semaphore_handle_for_type_khr(", generated)
        self.assertIn("pub fn re_import_semaphore_sync_fd_khr(", generated)
        self.assertIn("pub fn enqueue_acquire_external_mem_objects_khr(", generated)
        self.assertIn("pub fn enqueue_release_external_mem_objects_khr(", generated)

    def test_device_uuid_extension_is_generated(self) -> None:
        generated = self.generate()
        self.assertIn("pub const uuid_size_khr = u32(16)", generated)
        self.assertIn("pub const luid_size_khr = u32(8)", generated)
        self.assertIn("pub const device_uuid_khr = DeviceInfo(0x106A)", generated)
        self.assertIn("pub const driver_uuid_khr = DeviceInfo(0x106B)", generated)
        self.assertIn("pub const device_luid_valid_khr = DeviceInfo(0x106C)", generated)
        self.assertIn("pub const device_luid_khr = DeviceInfo(0x106D)", generated)
        self.assertIn("pub const device_node_mask_khr = DeviceInfo(0x106E)", generated)


if __name__ == "__main__":
    unittest.main()
