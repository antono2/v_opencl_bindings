// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
module opencl

#flag linux -lOpenCL

#flag windows -lOpenCL

#flag darwin -framework OpenCL

#flag darwin -I@VMODROOT/include

#include <CL/opencl.h>

pub fn make_version(major u32, minor u32, patch u32) u32 {
	return (major << 22) | (minor << 12) | patch
}

pub fn version_major(version u32) u32 {
	return version >> 22
}

pub fn version_minor(version u32) u32 {
	return (version >> 12) & 0x3ff
}

pub fn version_patch(version u32) u32 {
	return version & 0xfff
}

pub type Char = i8

pub type Uchar = u8

pub type Short = i16

pub type Ushort = u16

pub type Int = i32

pub type Uint = u32

pub type Long = i64

pub type Ulong = u64

pub type Float = f32

pub type Double = f64

pub type PlatformId = voidptr

pub type DeviceId = voidptr

pub type Context = voidptr

pub type CommandQueue = voidptr

pub type Mem = voidptr

pub type Program = voidptr

pub type Kernel = voidptr

pub type Event = voidptr

pub type Sampler = voidptr

pub type Bool = u32

pub type Bitfield = u64

pub type Properties = u64

pub type DeviceType = u64

pub type PlatformInfo = u32

pub type DeviceInfo = u32

pub type DeviceFpConfig = u64

pub type DeviceMemCacheType = u32

pub type DeviceLocalMemType = u32

pub type DeviceExecCapabilities = u64

pub type CommandQueueProperties = u64

pub type ContextProperties = isize

pub type ContextInfo = u32

pub type CommandQueueInfo = u32

pub type ChannelOrder = u32

pub type ChannelType = u32

pub type MemFlags = u64

pub type MemObjectType = u32

pub type MemInfo = u32

pub type ImageInfo = u32

pub type AddressingMode = u32

pub type FilterMode = u32

pub type SamplerInfo = u32

pub type MapFlags = u64

pub type ProgramInfo = u32

pub type ProgramBuildInfo = u32

pub type BuildStatus = i32

pub type KernelInfo = u32

pub type KernelWorkGroupInfo = u32

pub type EventInfo = u32

pub type CommandType = u32

pub type ProfilingInfo = u32

pub type BufferCreateType = u32

pub type DevicePartitionProperty = isize

pub type DeviceAffinityDomain = u64

pub type MemMigrationFlags = u64

pub type ProgramBinaryType = u32

pub type KernelArgInfo = u32

pub type KernelArgAddressQualifier = u32

pub type KernelArgAccessQualifier = u32

pub type KernelArgTypeQualifier = u64

pub type DeviceSvmCapabilities = u64

pub type QueueProperties = u64

pub type SvmMemFlags = u64

pub type PipeProperties = isize

pub type PipeInfo = u32

pub type SamplerProperties = u64

pub type KernelExecInfo = u32

pub type KernelSubGroupInfo = u32

pub type DeviceAtomicCapabilities = u64

pub type DeviceDeviceEnqueueCapabilities = u64

pub type KhronosVendorId = u32

pub type MemProperties = u64

pub type Version = u32

pub type QueuePropertiesKhr = u64

pub type SemaphoreKhr = voidptr

pub type SemaphorePropertiesKhr = u64

pub type SemaphoreInfoKhr = u32

pub type SemaphoreTypeKhr = u32

pub type SemaphorePayloadKhr = u64

pub type ExternalSemaphoreHandleTypeKhr = u32

pub type SemaphoreReimportPropertiesKhr = u64

pub type ExternalMemoryHandleTypeKhr = u32

$if windows {
	@[callconv: stdcall]
	pub type ContextNotifyCallback = fn (errinfo &char, private_info voidptr, cb usize, user_data voidptr)
	@[callconv: stdcall]
	pub type ContextDestructorCallback = fn (context Context, user_data voidptr)
	@[callconv: stdcall]
	pub type MemObjectDestructorCallback = fn (memobj Mem, user_data voidptr)
	@[callconv: stdcall]
	pub type ProgramCallback = fn (program Program, user_data voidptr)
	@[callconv: stdcall]
	pub type EventCallback = fn (event Event, event_command_status i32, user_data voidptr)
	@[callconv: stdcall]
	pub type SvmFreeCallback = fn (queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, user_data voidptr)
	@[callconv: stdcall]
	pub type NativeKernelCallback = fn (args voidptr)
} $else {
	pub type ContextNotifyCallback = fn (errinfo &char, private_info voidptr, cb usize, user_data voidptr)
	pub type ContextDestructorCallback = fn (context Context, user_data voidptr)
	pub type MemObjectDestructorCallback = fn (memobj Mem, user_data voidptr)
	pub type ProgramCallback = fn (program Program, user_data voidptr)
	pub type EventCallback = fn (event Event, event_command_status i32, user_data voidptr)
	pub type SvmFreeCallback = fn (queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, user_data voidptr)
	pub type NativeKernelCallback = fn (args voidptr)
}

pub struct ImageFormat {
pub mut:
	image_channel_order     ChannelOrder
	image_channel_data_type ChannelType
}

pub struct BufferRegion {
pub mut:
	origin usize
	size   usize
}

pub struct ImageDesc {
pub mut:
	image_type        MemObjectType
	image_width       usize
	image_height      usize
	image_depth       usize
	image_array_size  usize
	image_row_pitch   usize
	image_slice_pitch usize
	num_mip_levels    Uint
	num_samples       Uint
	buffer            Mem
}

pub struct NameVersion {
pub mut:
	version Version
	name    [name_version_max_name_size]i8
}

pub type ErrorCode = i32

pub const success = ErrorCode(0)
pub const device_not_found = ErrorCode(-1)
pub const device_not_available = ErrorCode(-2)
pub const compiler_not_available = ErrorCode(-3)
pub const mem_object_allocation_failure = ErrorCode(-4)
pub const out_of_resources = ErrorCode(-5)
pub const out_of_host_memory = ErrorCode(-6)
pub const profiling_info_not_available = ErrorCode(-7)
pub const mem_copy_overlap = ErrorCode(-8)
pub const image_format_mismatch = ErrorCode(-9)
pub const image_format_not_supported = ErrorCode(-10)
pub const build_program_failure = ErrorCode(-11)
pub const map_failure = ErrorCode(-12)
pub const misaligned_sub_buffer_offset = ErrorCode(-13)
pub const exec_status_error_for_events_in_wait_list = ErrorCode(-14)
pub const compile_program_failure = ErrorCode(-15)
pub const linker_not_available = ErrorCode(-16)
pub const link_program_failure = ErrorCode(-17)
pub const device_partition_failed = ErrorCode(-18)
pub const kernel_arg_info_not_available = ErrorCode(-19)
pub const invalid_value = ErrorCode(-30)
pub const invalid_device_type = ErrorCode(-31)
pub const invalid_platform = ErrorCode(-32)
pub const invalid_device = ErrorCode(-33)
pub const invalid_context = ErrorCode(-34)
pub const invalid_queue_properties = ErrorCode(-35)
pub const invalid_command_queue = ErrorCode(-36)
pub const invalid_host_ptr = ErrorCode(-37)
pub const invalid_mem_object = ErrorCode(-38)
pub const invalid_image_format_descriptor = ErrorCode(-39)
pub const invalid_image_size = ErrorCode(-40)
pub const invalid_sampler = ErrorCode(-41)
pub const invalid_binary = ErrorCode(-42)
pub const invalid_build_options = ErrorCode(-43)
pub const invalid_program = ErrorCode(-44)
pub const invalid_program_executable = ErrorCode(-45)
pub const invalid_kernel_name = ErrorCode(-46)
pub const invalid_kernel_definition = ErrorCode(-47)
pub const invalid_kernel = ErrorCode(-48)
pub const invalid_arg_index = ErrorCode(-49)
pub const invalid_arg_value = ErrorCode(-50)
pub const invalid_arg_size = ErrorCode(-51)
pub const invalid_kernel_args = ErrorCode(-52)
pub const invalid_work_dimension = ErrorCode(-53)
pub const invalid_work_group_size = ErrorCode(-54)
pub const invalid_work_item_size = ErrorCode(-55)
pub const invalid_global_offset = ErrorCode(-56)
pub const invalid_event_wait_list = ErrorCode(-57)
pub const invalid_event = ErrorCode(-58)
pub const invalid_operation = ErrorCode(-59)
pub const invalid_gl_object = ErrorCode(-60)
pub const invalid_buffer_size = ErrorCode(-61)
pub const invalid_mip_level = ErrorCode(-62)
pub const invalid_global_work_size = ErrorCode(-63)
pub const invalid_property = ErrorCode(-64)
pub const invalid_image_descriptor = ErrorCode(-65)
pub const invalid_compiler_options = ErrorCode(-66)
pub const invalid_linker_options = ErrorCode(-67)
pub const invalid_device_partition_count = ErrorCode(-68)
pub const invalid_pipe_size = ErrorCode(-69)
pub const invalid_device_queue = ErrorCode(-70)
pub const invalid_spec_id = ErrorCode(-71)
pub const max_size_restriction_exceeded = ErrorCode(-72)
pub const platform_not_found_khr = ErrorCode(-1001)

pub const platform_profile = PlatformInfo(0x0900)
pub const platform_version = PlatformInfo(0x0901)
pub const platform_name = PlatformInfo(0x0902)
pub const platform_vendor = PlatformInfo(0x0903)
pub const platform_extensions = PlatformInfo(0x0904)
pub const platform_host_timer_resolution = PlatformInfo(0x0905)
pub const platform_numeric_version = PlatformInfo(0x0906)
pub const platform_extensions_with_version = PlatformInfo(0x0907)

pub const device_type_default = DeviceType(1 << 0)
pub const device_type_cpu = DeviceType(1 << 1)
pub const device_type_gpu = DeviceType(1 << 2)
pub const device_type_accelerator = DeviceType(1 << 3)
pub const device_type_custom = DeviceType(1 << 4)
pub const device_type_all = DeviceType(0xFFFFFFFF)

pub const device_name = DeviceInfo(0x102B)
pub const device_vendor = DeviceInfo(0x102C)
pub const driver_version = DeviceInfo(0x102D)
pub const device_version = DeviceInfo(0x102F)
pub const device_il_version = DeviceInfo(0x105B)
pub const device_max_num_sub_groups = DeviceInfo(0x105C)
pub const device_sub_group_independent_forward_progress = DeviceInfo(0x105D)
pub const device_numeric_version = DeviceInfo(0x105E)
pub const device_extensions_with_version = DeviceInfo(0x1060)

pub const mem_read_only = MemFlags(1 << 2)
pub const mem_write_only = MemFlags(1 << 1)
pub const mem_copy_host_ptr = MemFlags(1 << 5)

pub const program_build_log = ProgramBuildInfo(0x1183)

pub const event_command_execution_status = EventInfo(0x11D3)

pub const complete = i32(0x0)
pub const running = i32(0x1)
pub const submitted = i32(0x2)
pub const queued = i32(0x3)

pub const _false = Bool(0)
pub const _true = Bool(1)

pub const version_major_bits = u32(10)
pub const version_minor_bits = u32(10)
pub const version_patch_bits = u32(12)
pub const name_version_max_name_size = u32(64)

pub const device_type = DeviceInfo(0x1000)
pub const device_vendor_id = DeviceInfo(0x1001)
pub const device_max_compute_units = DeviceInfo(0x1002)
pub const device_max_work_item_dimensions = DeviceInfo(0x1003)
pub const device_max_work_group_size = DeviceInfo(0x1004)
pub const device_preferred_vector_width_char = DeviceInfo(0x1006)
pub const device_preferred_vector_width_short = DeviceInfo(0x1007)
pub const device_preferred_vector_width_int = DeviceInfo(0x1008)
pub const device_preferred_vector_width_long = DeviceInfo(0x1009)
pub const device_preferred_vector_width_float = DeviceInfo(0x100A)
pub const device_preferred_vector_width_double = DeviceInfo(0x100B)
pub const device_max_clock_frequency = DeviceInfo(0x100C)
pub const device_address_bits = DeviceInfo(0x100D)
pub const device_max_read_image_args = DeviceInfo(0x100E)
pub const device_max_write_image_args = DeviceInfo(0x100F)
pub const device_max_mem_alloc_size = DeviceInfo(0x1010)
pub const device_image2d_max_width = DeviceInfo(0x1011)
pub const device_image2d_max_height = DeviceInfo(0x1012)
pub const device_image3d_max_width = DeviceInfo(0x1013)
pub const device_image3d_max_height = DeviceInfo(0x1014)
pub const device_image3d_max_depth = DeviceInfo(0x1015)
pub const device_image_support = DeviceInfo(0x1016)
pub const device_max_parameter_size = DeviceInfo(0x1017)
pub const device_max_samplers = DeviceInfo(0x1018)
pub const device_mem_base_addr_align = DeviceInfo(0x1019)
pub const device_single_fp_config = DeviceInfo(0x101B)
pub const device_global_mem_cache_type = DeviceInfo(0x101C)
pub const device_global_mem_cacheline_size = DeviceInfo(0x101D)
pub const device_global_mem_cache_size = DeviceInfo(0x101E)
pub const device_global_mem_size = DeviceInfo(0x101F)
pub const device_max_constant_buffer_size = DeviceInfo(0x1020)
pub const device_max_constant_args = DeviceInfo(0x1021)
pub const device_local_mem_type = DeviceInfo(0x1022)
pub const device_local_mem_size = DeviceInfo(0x1023)
pub const device_error_correction_support = DeviceInfo(0x1024)
pub const device_profiling_timer_resolution = DeviceInfo(0x1025)
pub const device_endian_little = DeviceInfo(0x1026)
pub const device_available = DeviceInfo(0x1027)
pub const device_compiler_available = DeviceInfo(0x1028)
pub const device_execution_capabilities = DeviceInfo(0x1029)
pub const device_profile = DeviceInfo(0x102E)
pub const device_extensions = DeviceInfo(0x1030)
pub const device_platform = DeviceInfo(0x1031)
pub const fp_denorm = DeviceFpConfig(1 << 0)
pub const fp_inf_nan = DeviceFpConfig(1 << 1)
pub const fp_round_to_nearest = DeviceFpConfig(1 << 2)
pub const fp_round_to_zero = DeviceFpConfig(1 << 3)
pub const fp_round_to_inf = DeviceFpConfig(1 << 4)
pub const fp_fma = DeviceFpConfig(1 << 5)
pub const _none = DeviceMemCacheType(0x0)
pub const read_only_cache = DeviceMemCacheType(0x1)
pub const read_write_cache = DeviceMemCacheType(0x2)
pub const local = DeviceLocalMemType(0x1)
pub const _global = DeviceLocalMemType(0x2)
pub const exec_kernel = DeviceExecCapabilities(1 << 0)
pub const exec_native_kernel = DeviceExecCapabilities(1 << 1)
pub const queue_out_of_order_exec_mode_enable = CommandQueueProperties(1 << 0)
pub const queue_profiling_enable = CommandQueueProperties(1 << 1)
pub const context_reference_count = ContextInfo(0x1080)
pub const context_devices = ContextInfo(0x1081)
pub const context_properties = ContextInfo(0x1082)
pub const context_platform = ContextProperties(0x1084)
pub const queue_context = CommandQueueInfo(0x1090)
pub const queue_device = CommandQueueInfo(0x1091)
pub const queue_reference_count = CommandQueueInfo(0x1092)
pub const queue_properties = CommandQueueInfo(0x1093)
pub const mem_read_write = MemFlags(1 << 0)
pub const mem_use_host_ptr = MemFlags(1 << 3)
pub const mem_alloc_host_ptr = MemFlags(1 << 4)
pub const profiling_command_queued = ProfilingInfo(0x1280)
pub const profiling_command_submit = ProfilingInfo(0x1281)
pub const profiling_command_start = ProfilingInfo(0x1282)
pub const profiling_command_end = ProfilingInfo(0x1283)
pub const r = ChannelOrder(0x10B0)
pub const a = ChannelOrder(0x10B1)
pub const rg = ChannelOrder(0x10B2)
pub const ra = ChannelOrder(0x10B3)
pub const rgb = ChannelOrder(0x10B4)
pub const rgba = ChannelOrder(0x10B5)
pub const bgra = ChannelOrder(0x10B6)
pub const argb = ChannelOrder(0x10B7)
pub const intensity = ChannelOrder(0x10B8)
pub const luminance = ChannelOrder(0x10B9)
pub const snorm_int8 = ChannelType(0x10D0)
pub const snorm_int16 = ChannelType(0x10D1)
pub const unorm_int8 = ChannelType(0x10D2)
pub const unorm_int16 = ChannelType(0x10D3)
pub const unorm_short_565 = ChannelType(0x10D4)
pub const unorm_short_555 = ChannelType(0x10D5)
pub const unorm_int_101010 = ChannelType(0x10D6)
pub const signed_int8 = ChannelType(0x10D7)
pub const signed_int16 = ChannelType(0x10D8)
pub const signed_int32 = ChannelType(0x10D9)
pub const unsigned_int8 = ChannelType(0x10DA)
pub const unsigned_int16 = ChannelType(0x10DB)
pub const unsigned_int32 = ChannelType(0x10DC)
pub const half_float = ChannelType(0x10DD)
pub const float = ChannelType(0x10DE)
pub const mem_object_buffer = MemObjectType(0x10F0)
pub const mem_object_image2d = MemObjectType(0x10F1)
pub const mem_object_image3d = MemObjectType(0x10F2)
pub const mem_type = MemInfo(0x1100)
pub const mem_flags = MemInfo(0x1101)
pub const mem_size = MemInfo(0x1102)
pub const mem_host_ptr = MemInfo(0x1103)
pub const mem_map_count = MemInfo(0x1104)
pub const mem_reference_count = MemInfo(0x1105)
pub const mem_context = MemInfo(0x1106)
pub const image_format = ImageInfo(0x1110)
pub const image_element_size = ImageInfo(0x1111)
pub const image_row_pitch = ImageInfo(0x1112)
pub const image_slice_pitch = ImageInfo(0x1113)
pub const image_width = ImageInfo(0x1114)
pub const image_height = ImageInfo(0x1115)
pub const image_depth = ImageInfo(0x1116)
pub const address_none = AddressingMode(0x1130)
pub const address_clamp_to_edge = AddressingMode(0x1131)
pub const address_clamp = AddressingMode(0x1132)
pub const address_repeat = AddressingMode(0x1133)
pub const filter_nearest = FilterMode(0x1140)
pub const filter_linear = FilterMode(0x1141)
pub const sampler_reference_count = SamplerInfo(0x1150)
pub const sampler_context = SamplerInfo(0x1151)
pub const sampler_normalized_coords = SamplerInfo(0x1152)
pub const sampler_addressing_mode = SamplerInfo(0x1153)
pub const sampler_filter_mode = SamplerInfo(0x1154)
pub const map_read = MapFlags(1 << 0)
pub const map_write = MapFlags(1 << 1)
pub const program_reference_count = ProgramInfo(0x1160)
pub const program_context = ProgramInfo(0x1161)
pub const program_num_devices = ProgramInfo(0x1162)
pub const program_devices = ProgramInfo(0x1163)
pub const program_source = ProgramInfo(0x1164)
pub const program_binary_sizes = ProgramInfo(0x1165)
pub const program_binaries = ProgramInfo(0x1166)
pub const program_build_status = ProgramBuildInfo(0x1181)
pub const program_build_options = ProgramBuildInfo(0x1182)
pub const build_success = BuildStatus(0)
pub const build_none = BuildStatus(-1)
pub const build_error = BuildStatus(-2)
pub const build_in_progress = BuildStatus(-3)
pub const kernel_function_name = KernelInfo(0x1190)
pub const kernel_num_args = KernelInfo(0x1191)
pub const kernel_reference_count = KernelInfo(0x1192)
pub const kernel_context = KernelInfo(0x1193)
pub const kernel_program = KernelInfo(0x1194)
pub const kernel_work_group_size = KernelWorkGroupInfo(0x11B0)
pub const kernel_compile_work_group_size = KernelWorkGroupInfo(0x11B1)
pub const kernel_local_mem_size = KernelWorkGroupInfo(0x11B2)
pub const kernel_preferred_work_group_size_multiple = KernelWorkGroupInfo(0x11B3)
pub const kernel_private_mem_size = KernelWorkGroupInfo(0x11B4)
pub const event_command_queue = EventInfo(0x11D0)
pub const event_command_type = EventInfo(0x11D1)
pub const event_reference_count = EventInfo(0x11D2)
pub const command_ndrange_kernel = CommandType(0x11F0)
pub const command_task = CommandType(0x11F1)
pub const command_native_kernel = CommandType(0x11F2)
pub const command_read_buffer = CommandType(0x11F3)
pub const command_write_buffer = CommandType(0x11F4)
pub const command_copy_buffer = CommandType(0x11F5)
pub const command_read_image = CommandType(0x11F6)
pub const command_write_image = CommandType(0x11F7)
pub const command_copy_image = CommandType(0x11F8)
pub const command_copy_image_to_buffer = CommandType(0x11F9)
pub const command_copy_buffer_to_image = CommandType(0x11FA)
pub const command_map_buffer = CommandType(0x11FB)
pub const command_map_image = CommandType(0x11FC)
pub const command_unmap_mem_object = CommandType(0x11FD)
pub const command_marker = CommandType(0x11FE)
pub const command_acquire_gl_objects = CommandType(0x11FF)
pub const command_release_gl_objects = CommandType(0x1200)
pub const khronos_vendor_id_codeplay = KhronosVendorId(0x10004)
pub const khronos_vendor_id_pocl = KhronosVendorId(0x10006)
pub const device_min_data_type_align_size = DeviceInfo(0x101A)
pub const device_queue_properties = DeviceInfo(0x102A)
pub const device_max_work_item_sizes = DeviceInfo(0x1005)
pub const device_host_unified_memory = DeviceInfo(0x1035)
pub const device_preferred_vector_width_half = DeviceInfo(0x1034)
pub const device_native_vector_width_char = DeviceInfo(0x1036)
pub const device_native_vector_width_short = DeviceInfo(0x1037)
pub const device_native_vector_width_int = DeviceInfo(0x1038)
pub const device_native_vector_width_long = DeviceInfo(0x1039)
pub const device_native_vector_width_float = DeviceInfo(0x103A)
pub const device_native_vector_width_double = DeviceInfo(0x103B)
pub const device_native_vector_width_half = DeviceInfo(0x103C)
pub const fp_soft_float = DeviceFpConfig(1 << 6)
pub const context_num_devices = ContextInfo(0x1083)
pub const rx = ChannelOrder(0x10BA)
pub const rgx = ChannelOrder(0x10BB)
pub const rgbx = ChannelOrder(0x10BC)
pub const mem_associated_memobject = MemInfo(0x1107)
pub const mem_offset = MemInfo(0x1108)
pub const address_mirrored_repeat = AddressingMode(0x1134)
pub const event_context = EventInfo(0x11D4)
pub const command_read_buffer_rect = CommandType(0x1201)
pub const command_write_buffer_rect = CommandType(0x1202)
pub const command_copy_buffer_rect = CommandType(0x1203)
pub const command_user = CommandType(0x1204)
pub const buffer_create_type_region = BufferCreateType(0x1220)
pub const device_opencl_c_version = DeviceInfo(0x103D)
pub const command_barrier = CommandType(0x1205)
pub const command_migrate_mem_objects = CommandType(0x1206)
pub const command_fill_buffer = CommandType(0x1207)
pub const command_fill_image = CommandType(0x1208)
pub const blocking = Bool(_true)
pub const non_blocking = Bool(_false)
pub const device_double_fp_config = DeviceInfo(0x1032)
pub const device_linker_available = DeviceInfo(0x103E)
pub const device_built_in_kernels = DeviceInfo(0x103F)
pub const device_image_max_buffer_size = DeviceInfo(0x1040)
pub const device_image_max_array_size = DeviceInfo(0x1041)
pub const device_parent_device = DeviceInfo(0x1042)
pub const device_partition_max_sub_devices = DeviceInfo(0x1043)
pub const device_partition_properties = DeviceInfo(0x1044)
pub const device_partition_affinity_domain = DeviceInfo(0x1045)
pub const device_partition_type = DeviceInfo(0x1046)
pub const device_reference_count = DeviceInfo(0x1047)
pub const device_preferred_interop_user_sync = DeviceInfo(0x1048)
pub const device_printf_buffer_size = DeviceInfo(0x1049)
pub const fp_correctly_rounded_divide_sqrt = DeviceFpConfig(1 << 7)
pub const context_interop_user_sync = ContextProperties(0x1085)
pub const device_partition_equally = DevicePartitionProperty(0x1086)
pub const device_partition_by_counts = DevicePartitionProperty(0x1087)
pub const device_partition_by_counts_list_end = DevicePartitionProperty(0x0)
pub const device_partition_by_affinity_domain = DevicePartitionProperty(0x1088)
pub const device_affinity_domain_numa = DeviceAffinityDomain(1 << 0)
pub const device_affinity_domain_l4_cache = DeviceAffinityDomain(1 << 1)
pub const device_affinity_domain_l3_cache = DeviceAffinityDomain(1 << 2)
pub const device_affinity_domain_l2_cache = DeviceAffinityDomain(1 << 3)
pub const device_affinity_domain_l1_cache = DeviceAffinityDomain(1 << 4)
pub const device_affinity_domain_next_partitionable = DeviceAffinityDomain(1 << 5)
pub const mem_host_write_only = MemFlags(1 << 7)
pub const mem_host_read_only = MemFlags(1 << 8)
pub const mem_host_no_access = MemFlags(1 << 9)
pub const migrate_mem_object_host = MemMigrationFlags(1 << 0)
pub const migrate_mem_object_content_undefined = MemMigrationFlags(1 << 1)
pub const mem_object_image2d_array = MemObjectType(0x10F3)
pub const mem_object_image1d = MemObjectType(0x10F4)
pub const mem_object_image1d_array = MemObjectType(0x10F5)
pub const mem_object_image1d_buffer = MemObjectType(0x10F6)
pub const image_array_size = ImageInfo(0x1117)
pub const image_num_mip_levels = ImageInfo(0x1119)
pub const image_num_samples = ImageInfo(0x111A)
pub const map_write_invalidate_region = MapFlags(1 << 2)
pub const program_num_kernels = ProgramInfo(0x1167)
pub const program_kernel_names = ProgramInfo(0x1168)
pub const program_binary_type = ProgramBuildInfo(0x1184)
pub const program_binary_type_none = ProgramBinaryType(0x0)
pub const program_binary_type_compiled_object = ProgramBinaryType(0x1)
pub const program_binary_type_library = ProgramBinaryType(0x2)
pub const program_binary_type_executable = ProgramBinaryType(0x4)
pub const kernel_attributes = KernelInfo(0x1195)
pub const kernel_arg_address_qualifier = KernelArgInfo(0x1196)
pub const kernel_arg_access_qualifier = KernelArgInfo(0x1197)
pub const kernel_arg_type_name = KernelArgInfo(0x1198)
pub const kernel_arg_type_qualifier = KernelArgInfo(0x1199)
pub const kernel_arg_name = KernelArgInfo(0x119A)
pub const kernel_arg_address_global = KernelArgAddressQualifier(0x119B)
pub const kernel_arg_address_local = KernelArgAddressQualifier(0x119C)
pub const kernel_arg_address_constant = KernelArgAddressQualifier(0x119D)
pub const kernel_arg_address_private = KernelArgAddressQualifier(0x119E)
pub const kernel_arg_access_read_only = KernelArgAccessQualifier(0x11A0)
pub const kernel_arg_access_write_only = KernelArgAccessQualifier(0x11A1)
pub const kernel_arg_access_read_write = KernelArgAccessQualifier(0x11A2)
pub const kernel_arg_access_none = KernelArgAccessQualifier(0x11A3)
pub const kernel_arg_type_none = KernelArgTypeQualifier(0)
pub const kernel_arg_type_const = KernelArgTypeQualifier(1 << 0)
pub const kernel_arg_type_restrict = KernelArgTypeQualifier(1 << 1)
pub const kernel_arg_type_volatile = KernelArgTypeQualifier(1 << 2)
pub const kernel_global_work_size = KernelWorkGroupInfo(0x11B5)
pub const image_buffer = ImageInfo(0x1118)
pub const device_queue_on_host_properties = DeviceInfo(0x102A)
pub const device_image_pitch_alignment = DeviceInfo(0x104A)
pub const device_image_base_address_alignment = DeviceInfo(0x104B)
pub const device_max_read_write_image_args = DeviceInfo(0x104C)
pub const device_max_global_variable_size = DeviceInfo(0x104D)
pub const device_queue_on_device_properties = DeviceInfo(0x104E)
pub const device_queue_on_device_preferred_size = DeviceInfo(0x104F)
pub const device_queue_on_device_max_size = DeviceInfo(0x1050)
pub const device_max_on_device_queues = DeviceInfo(0x1051)
pub const device_max_on_device_events = DeviceInfo(0x1052)
pub const device_svm_capabilities = DeviceInfo(0x1053)
pub const device_global_variable_preferred_total_size = DeviceInfo(0x1054)
pub const device_max_pipe_args = DeviceInfo(0x1055)
pub const device_pipe_max_active_reservations = DeviceInfo(0x1056)
pub const device_pipe_max_packet_size = DeviceInfo(0x1057)
pub const device_preferred_platform_atomic_alignment = DeviceInfo(0x1058)
pub const device_preferred_global_atomic_alignment = DeviceInfo(0x1059)
pub const device_preferred_local_atomic_alignment = DeviceInfo(0x105A)
pub const queue_on_device = CommandQueueProperties(1 << 2)
pub const queue_on_device_default = CommandQueueProperties(1 << 3)
pub const device_svm_coarse_grain_buffer = DeviceSvmCapabilities(1 << 0)
pub const device_svm_fine_grain_buffer = DeviceSvmCapabilities(1 << 1)
pub const device_svm_fine_grain_system = DeviceSvmCapabilities(1 << 2)
pub const device_svm_atomics = DeviceSvmCapabilities(1 << 3)
pub const queue_size = CommandQueueInfo(0x1094)
pub const mem_svm_fine_grain_buffer = MemFlags(1 << 10)
pub const mem_svm_atomics = MemFlags(1 << 11)
pub const mem_kernel_read_and_write = MemFlags(1 << 12)
pub const depth = ChannelOrder(0x10BD)
pub const srgb = ChannelOrder(0x10BF)
pub const srgbx = ChannelOrder(0x10C0)
pub const srgba = ChannelOrder(0x10C1)
pub const sbgra = ChannelOrder(0x10C2)
pub const abgr = ChannelOrder(0x10C3)
pub const mem_object_pipe = MemObjectType(0x10F7)
pub const mem_uses_svm_pointer = MemInfo(0x1109)
pub const pipe_packet_size = PipeInfo(0x1120)
pub const pipe_max_packets = PipeInfo(0x1121)
pub const sampler_mip_filter_mode = SamplerInfo(0x1155)
pub const sampler_lod_min = SamplerInfo(0x1156)
pub const sampler_lod_max = SamplerInfo(0x1157)
pub const program_build_global_variable_total_size = ProgramBuildInfo(0x1185)
pub const kernel_arg_type_pipe = KernelArgTypeQualifier(1 << 3)
pub const kernel_exec_info_svm_ptrs = KernelExecInfo(0x11B6)
pub const kernel_exec_info_svm_fine_grain_system = KernelExecInfo(0x11B7)
pub const command_svm_free = CommandType(0x1209)
pub const command_svm_memcpy = CommandType(0x120A)
pub const command_svm_memfill = CommandType(0x120B)
pub const command_svm_map = CommandType(0x120C)
pub const command_svm_unmap = CommandType(0x120D)
pub const profiling_command_complete = ProfilingInfo(0x1284)
pub const queue_device_default = CommandQueueInfo(0x1095)
pub const unorm_int_101010_2 = ChannelType(0x10E0)
pub const program_il = ProgramInfo(0x1169)
pub const kernel_max_num_sub_groups = KernelSubGroupInfo(0x11B9)
pub const kernel_compile_num_sub_groups = KernelSubGroupInfo(0x11BA)
pub const kernel_max_sub_group_size_for_ndrange = KernelSubGroupInfo(0x2033)
pub const kernel_sub_group_count_for_ndrange = KernelSubGroupInfo(0x2034)
pub const kernel_local_size_for_sub_group_count = KernelSubGroupInfo(0x11B8)
pub const program_scope_global_ctors_present = ProgramInfo(0x116A)
pub const program_scope_global_dtors_present = ProgramInfo(0x116B)
pub const device_atomic_order_relaxed = DeviceAtomicCapabilities(1 << 0)
pub const device_atomic_order_acq_rel = DeviceAtomicCapabilities(1 << 1)
pub const device_atomic_order_seq_cst = DeviceAtomicCapabilities(1 << 2)
pub const device_atomic_scope_work_item = DeviceAtomicCapabilities(1 << 3)
pub const device_atomic_scope_work_group = DeviceAtomicCapabilities(1 << 4)
pub const device_atomic_scope_device = DeviceAtomicCapabilities(1 << 5)
pub const device_atomic_scope_all_devices = DeviceAtomicCapabilities(1 << 6)
pub const device_queue_supported = DeviceDeviceEnqueueCapabilities(1 << 0)
pub const device_queue_replaceable_default = DeviceDeviceEnqueueCapabilities(1 << 1)
pub const device_atomic_memory_capabilities = DeviceInfo(0x1063)
pub const device_atomic_fence_capabilities = DeviceInfo(0x1064)
pub const device_non_uniform_work_group_support = DeviceInfo(0x1065)
pub const device_opencl_c_all_versions = DeviceInfo(0x1066)
pub const device_work_group_collective_functions_support = DeviceInfo(0x1068)
pub const device_generic_address_space_support = DeviceInfo(0x1069)
pub const device_opencl_c_features = DeviceInfo(0x106F)
pub const device_device_enqueue_capabilities = DeviceInfo(0x1070)
pub const device_pipe_support = DeviceInfo(0x1071)
pub const device_ils_with_version = DeviceInfo(0x1061)
pub const device_built_in_kernels_with_version = DeviceInfo(0x1062)
pub const device_preferred_work_group_size_multiple = DeviceInfo(0x1067)
pub const device_latest_conformance_version_passed = DeviceInfo(0x1072)
pub const pipe_properties = PipeInfo(0x1122)
pub const sampler_properties = SamplerInfo(0x1158)
pub const queue_properties_array = CommandQueueInfo(0x1098)
pub const mem_properties = MemInfo(0x110A)
pub const command_svm_migrate_mem = CommandType(0x120E)
pub const device_il_version_khr = DeviceInfo(0x105B)
pub const program_il_khr = ProgramInfo(0x1169)
pub const kernel_max_sub_group_size_for_ndrange_khr = KernelSubGroupInfo(0x2033)
pub const kernel_sub_group_count_for_ndrange_khr = KernelSubGroupInfo(0x2034)
pub const semaphore_type_binary_khr = SemaphoreTypeKhr(1)
pub const platform_semaphore_types_khr = PlatformInfo(0x2036)
pub const device_semaphore_types_khr = DeviceInfo(0x204C)
pub const semaphore_context_khr = SemaphoreInfoKhr(0x2039)
pub const semaphore_reference_count_khr = SemaphoreInfoKhr(0x203A)
pub const semaphore_properties_khr = SemaphoreInfoKhr(0x203B)
pub const semaphore_payload_khr = SemaphoreInfoKhr(0x203C)
pub const semaphore_type_khr = SemaphoreInfoKhr(0x203D)
pub const semaphore_device_handle_list_khr = SemaphoreInfoKhr(0x2053)
pub const semaphore_device_handle_list_end_khr = SemaphoreInfoKhr(0)
pub const command_semaphore_wait_khr = CommandType(0x2042)
pub const command_semaphore_signal_khr = CommandType(0x2043)
pub const invalid_semaphore_khr = ErrorCode(-1142)
pub const platform_semaphore_import_handle_types_khr = PlatformInfo(0x2037)
pub const platform_semaphore_export_handle_types_khr = PlatformInfo(0x2038)
pub const device_semaphore_import_handle_types_khr = DeviceInfo(0x204D)
pub const device_semaphore_export_handle_types_khr = DeviceInfo(0x204E)
pub const semaphore_export_handle_types_khr = SemaphorePropertiesKhr(0x203F)
pub const semaphore_export_handle_types_list_end_khr = SemaphorePropertiesKhr(0)
pub const semaphore_exportable_khr = SemaphoreInfoKhr(0x2054)
pub const semaphore_handle_opaque_fd_khr = ExternalSemaphoreHandleTypeKhr(0x2055)
pub const semaphore_handle_sync_fd_khr = ExternalSemaphoreHandleTypeKhr(0x2058)
pub const platform_external_memory_import_handle_types_khr = PlatformInfo(0x2044)
pub const device_external_memory_import_handle_types_khr = DeviceInfo(0x204F)
pub const device_external_memory_import_assume_linear_images_handle_types_khr = DeviceInfo(0x2052)
pub const mem_device_handle_list_khr = MemProperties(0x2051)
pub const mem_device_handle_list_end_khr = MemProperties(0)
pub const command_acquire_external_mem_objects_khr = CommandType(0x2047)
pub const command_release_external_mem_objects_khr = CommandType(0x2048)
pub const external_memory_handle_dma_buf_khr = ExternalMemoryHandleTypeKhr(0x2067)
pub const external_memory_handle_opaque_fd_khr = ExternalMemoryHandleTypeKhr(0x2060)
pub const uuid_size_khr = u32(16)
pub const luid_size_khr = u32(8)
pub const device_uuid_khr = DeviceInfo(0x106A)
pub const driver_uuid_khr = DeviceInfo(0x106B)
pub const device_luid_valid_khr = DeviceInfo(0x106C)
pub const device_luid_khr = DeviceInfo(0x106D)
pub const device_node_mask_khr = DeviceInfo(0x106E)

fn C.clGetPlatformIDs(u32, &PlatformId, &u32) ErrorCode

fn C.clGetPlatformInfo(PlatformId, PlatformInfo, usize, voidptr, &usize) ErrorCode

fn C.clGetDeviceIDs(PlatformId, DeviceType, u32, &DeviceId, &u32) ErrorCode

fn C.clGetDeviceInfo(DeviceId, DeviceInfo, usize, voidptr, &usize) ErrorCode

fn C.clCreateContext(&ContextProperties, u32, &DeviceId, ContextNotifyCallback, voidptr, &ErrorCode) Context

fn C.clCreateContextFromType(&ContextProperties, DeviceType, ContextNotifyCallback, voidptr, &ErrorCode) Context

fn C.clRetainContext(Context) ErrorCode

fn C.clReleaseContext(Context) ErrorCode

fn C.clGetContextInfo(Context, ContextInfo, usize, voidptr, &usize) ErrorCode

fn C.clRetainCommandQueue(CommandQueue) ErrorCode

fn C.clReleaseCommandQueue(CommandQueue) ErrorCode

fn C.clGetCommandQueueInfo(CommandQueue, CommandQueueInfo, usize, voidptr, &usize) ErrorCode

fn C.clCreateBuffer(Context, MemFlags, usize, voidptr, &ErrorCode) Mem

fn C.clRetainMemObject(Mem) ErrorCode

fn C.clReleaseMemObject(Mem) ErrorCode

fn C.clGetSupportedImageFormats(Context, MemFlags, MemObjectType, u32, &ImageFormat, &u32) ErrorCode

fn C.clGetMemObjectInfo(Mem, MemInfo, usize, voidptr, &usize) ErrorCode

fn C.clGetImageInfo(Mem, ImageInfo, usize, voidptr, &usize) ErrorCode

fn C.clRetainSampler(Sampler) ErrorCode

fn C.clReleaseSampler(Sampler) ErrorCode

fn C.clGetSamplerInfo(Sampler, SamplerInfo, usize, voidptr, &usize) ErrorCode

fn C.clCreateProgramWithSource(Context, u32, &&char, &usize, &ErrorCode) Program

fn C.clCreateProgramWithBinary(Context, u32, &DeviceId, &usize, &&u8, &i32, &ErrorCode) Program

fn C.clRetainProgram(Program) ErrorCode

fn C.clReleaseProgram(Program) ErrorCode

fn C.clBuildProgram(Program, u32, &DeviceId, &char, ProgramCallback, voidptr) ErrorCode

fn C.clGetProgramInfo(Program, ProgramInfo, usize, voidptr, &usize) ErrorCode

fn C.clGetProgramBuildInfo(Program, DeviceId, ProgramBuildInfo, usize, voidptr, &usize) ErrorCode

fn C.clCreateKernel(Program, &char, &ErrorCode) Kernel

fn C.clCreateKernelsInProgram(Program, u32, &Kernel, &u32) ErrorCode

fn C.clRetainKernel(Kernel) ErrorCode

fn C.clReleaseKernel(Kernel) ErrorCode

fn C.clSetKernelArg(Kernel, u32, usize, voidptr) ErrorCode

fn C.clGetKernelInfo(Kernel, KernelInfo, usize, voidptr, &usize) ErrorCode

fn C.clGetKernelWorkGroupInfo(Kernel, DeviceId, KernelWorkGroupInfo, usize, voidptr, &usize) ErrorCode

fn C.clWaitForEvents(u32, &Event) ErrorCode

fn C.clGetEventInfo(Event, EventInfo, usize, voidptr, &usize) ErrorCode

fn C.clRetainEvent(Event) ErrorCode

fn C.clReleaseEvent(Event) ErrorCode

fn C.clGetEventProfilingInfo(Event, ProfilingInfo, usize, voidptr, &usize) ErrorCode

fn C.clFlush(CommandQueue) ErrorCode

fn C.clFinish(CommandQueue) ErrorCode

fn C.clEnqueueReadBuffer(CommandQueue, Mem, Bool, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueWriteBuffer(CommandQueue, Mem, Bool, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyBuffer(CommandQueue, Mem, Mem, usize, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueReadImage(CommandQueue, Mem, Bool, &usize, &usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueWriteImage(CommandQueue, Mem, Bool, &usize, &usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyImage(CommandQueue, Mem, Mem, &usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyImageToBuffer(CommandQueue, Mem, Mem, &usize, &usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyBufferToImage(CommandQueue, Mem, Mem, usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueMapBuffer(CommandQueue, Mem, Bool, MapFlags, usize, usize, u32, &Event, &Event, &ErrorCode) voidptr

fn C.clEnqueueMapImage(CommandQueue, Mem, Bool, MapFlags, &usize, &usize, &usize, &usize, u32, &Event, &Event, &ErrorCode) voidptr

fn C.clEnqueueUnmapMemObject(CommandQueue, Mem, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueNDRangeKernel(CommandQueue, Kernel, u32, &usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueNativeKernel(CommandQueue, NativeKernelCallback, voidptr, usize, u32, &Mem, &voidptr, u32, &Event, &Event) ErrorCode

fn C.clSetCommandQueueProperty(CommandQueue, CommandQueueProperties, Bool, &CommandQueueProperties) ErrorCode

fn C.clCreateImage2D(Context, MemFlags, &ImageFormat, usize, usize, usize, voidptr, &ErrorCode) Mem

fn C.clCreateImage3D(Context, MemFlags, &ImageFormat, usize, usize, usize, usize, usize, voidptr, &ErrorCode) Mem

fn C.clEnqueueMarker(CommandQueue, &Event) ErrorCode

fn C.clEnqueueWaitForEvents(CommandQueue, u32, &Event) ErrorCode

fn C.clEnqueueBarrier(CommandQueue) ErrorCode

fn C.clUnloadCompiler() ErrorCode

fn C.clGetExtensionFunctionAddress(&char) voidptr

fn C.clCreateCommandQueue(Context, DeviceId, CommandQueueProperties, &ErrorCode) CommandQueue

fn C.clCreateSampler(Context, Bool, AddressingMode, FilterMode, &ErrorCode) Sampler

fn C.clEnqueueTask(CommandQueue, Kernel, u32, &Event, &Event) ErrorCode

fn C.clCreateSubBuffer(Mem, MemFlags, BufferCreateType, voidptr, &ErrorCode) Mem

fn C.clSetMemObjectDestructorCallback(Mem, MemObjectDestructorCallback, voidptr) ErrorCode

fn C.clCreateUserEvent(Context, &ErrorCode) Event

fn C.clSetUserEventStatus(Event, i32) ErrorCode

fn C.clSetEventCallback(Event, i32, EventCallback, voidptr) ErrorCode

fn C.clEnqueueReadBufferRect(CommandQueue, Mem, Bool, &usize, &usize, &usize, usize, usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueWriteBufferRect(CommandQueue, Mem, Bool, &usize, &usize, &usize, usize, usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyBufferRect(CommandQueue, Mem, Mem, &usize, &usize, &usize, usize, usize, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clCreateSubDevices(DeviceId, &DevicePartitionProperty, u32, &DeviceId, &u32) ErrorCode

fn C.clRetainDevice(DeviceId) ErrorCode

fn C.clReleaseDevice(DeviceId) ErrorCode

fn C.clCreateImage(Context, MemFlags, &ImageFormat, &ImageDesc, voidptr, &ErrorCode) Mem

fn C.clCreateProgramWithBuiltInKernels(Context, u32, &DeviceId, &char, &ErrorCode) Program

fn C.clCompileProgram(Program, u32, &DeviceId, &char, u32, &Program, &&char, ProgramCallback, voidptr) ErrorCode

fn C.clLinkProgram(Context, u32, &DeviceId, &char, u32, &Program, ProgramCallback, voidptr, &ErrorCode) Program

fn C.clUnloadPlatformCompiler(PlatformId) ErrorCode

fn C.clGetKernelArgInfo(Kernel, u32, KernelArgInfo, usize, voidptr, &usize) ErrorCode

fn C.clEnqueueFillBuffer(CommandQueue, Mem, voidptr, usize, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueFillImage(CommandQueue, Mem, voidptr, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueMigrateMemObjects(CommandQueue, u32, &Mem, MemMigrationFlags, u32, &Event, &Event) ErrorCode

fn C.clEnqueueMarkerWithWaitList(CommandQueue, u32, &Event, &Event) ErrorCode

fn C.clEnqueueBarrierWithWaitList(CommandQueue, u32, &Event, &Event) ErrorCode

fn C.clGetExtensionFunctionAddressForPlatform(PlatformId, &char) voidptr

fn C.clCreateCommandQueueWithProperties(Context, DeviceId, &QueueProperties, &ErrorCode) CommandQueue

fn C.clCreatePipe(Context, MemFlags, u32, u32, &PipeProperties, &ErrorCode) Mem

fn C.clGetPipeInfo(Mem, PipeInfo, usize, voidptr, &usize) ErrorCode

fn C.clSVMAlloc(Context, SvmMemFlags, usize, u32) voidptr

fn C.clSVMFree(Context, voidptr)

fn C.clCreateSamplerWithProperties(Context, &SamplerProperties, &ErrorCode) Sampler

fn C.clSetKernelArgSVMPointer(Kernel, u32, voidptr) ErrorCode

fn C.clSetKernelExecInfo(Kernel, KernelExecInfo, usize, voidptr) ErrorCode

fn C.clEnqueueSVMFree(CommandQueue, u32, &voidptr, SvmFreeCallback, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMMemcpy(CommandQueue, Bool, voidptr, voidptr, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMMemFill(CommandQueue, voidptr, voidptr, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMMap(CommandQueue, Bool, MapFlags, voidptr, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMUnmap(CommandQueue, voidptr, u32, &Event, &Event) ErrorCode

fn C.clSetDefaultDeviceCommandQueue(Context, DeviceId, CommandQueue) ErrorCode

fn C.clGetDeviceAndHostTimer(DeviceId, &u64, &u64) ErrorCode

fn C.clGetHostTimer(DeviceId, &u64) ErrorCode

fn C.clCreateProgramWithIL(Context, voidptr, usize, &ErrorCode) Program

fn C.clCloneKernel(Kernel, &ErrorCode) Kernel

fn C.clGetKernelSubGroupInfo(Kernel, DeviceId, KernelSubGroupInfo, usize, voidptr, usize, voidptr, &usize) ErrorCode

fn C.clEnqueueSVMMigrateMem(CommandQueue, u32, &voidptr, &usize, MemMigrationFlags, u32, &Event, &Event) ErrorCode

fn C.clSetProgramSpecializationConstant(Program, u32, usize, voidptr) ErrorCode

fn C.clSetProgramReleaseCallback(Program, ProgramCallback, voidptr) ErrorCode

fn C.clSetContextDestructorCallback(Context, ContextDestructorCallback, voidptr) ErrorCode

fn C.clCreateBufferWithProperties(Context, &MemProperties, MemFlags, usize, voidptr, &ErrorCode) Mem

fn C.clCreateImageWithProperties(Context, &MemProperties, MemFlags, &ImageFormat, &ImageDesc, voidptr, &ErrorCode) Mem

$if windows {
	@[callconv: stdcall]
	pub type PFN_clCreateProgramWithILKHR = fn (Context, voidptr, usize, &ErrorCode) Program
	@[callconv: stdcall]
	pub type PFN_clCreateCommandQueueWithPropertiesKHR = fn (Context, DeviceId, &QueuePropertiesKhr, &ErrorCode) CommandQueue
	@[callconv: stdcall]
	pub type PFN_clGetKernelSubGroupInfoKHR = fn (Kernel, DeviceId, KernelSubGroupInfo, usize, voidptr, usize, voidptr, &usize) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clGetKernelSuggestedLocalWorkSizeKHR = fn (CommandQueue, Kernel, u32, &usize, &usize, &usize) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clCreateSemaphoreWithPropertiesKHR = fn (Context, &SemaphorePropertiesKhr, &ErrorCode) SemaphoreKhr
	@[callconv: stdcall]
	pub type PFN_clEnqueueWaitSemaphoresKHR = fn (CommandQueue, u32, &SemaphoreKhr, &SemaphorePayloadKhr, u32, &Event, &Event) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clEnqueueSignalSemaphoresKHR = fn (CommandQueue, u32, &SemaphoreKhr, &SemaphorePayloadKhr, u32, &Event, &Event) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clGetSemaphoreInfoKHR = fn (SemaphoreKhr, SemaphoreInfoKhr, usize, voidptr, &usize) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clReleaseSemaphoreKHR = fn (SemaphoreKhr) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clRetainSemaphoreKHR = fn (SemaphoreKhr) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clGetSemaphoreHandleForTypeKHR = fn (SemaphoreKhr, DeviceId, ExternalSemaphoreHandleTypeKhr, usize, voidptr, &usize) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clReImportSemaphoreSyncFdKHR = fn (SemaphoreKhr, &SemaphoreReimportPropertiesKhr, int) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clEnqueueAcquireExternalMemObjectsKHR = fn (CommandQueue, u32, &Mem, u32, &Event, &Event) ErrorCode
	@[callconv: stdcall]
	pub type PFN_clEnqueueReleaseExternalMemObjectsKHR = fn (CommandQueue, u32, &Mem, u32, &Event, &Event) ErrorCode
} $else {
	pub type PFN_clCreateProgramWithILKHR = fn (Context, voidptr, usize, &ErrorCode) Program
	pub type PFN_clCreateCommandQueueWithPropertiesKHR = fn (Context, DeviceId, &QueuePropertiesKhr, &ErrorCode) CommandQueue
	pub type PFN_clGetKernelSubGroupInfoKHR = fn (Kernel, DeviceId, KernelSubGroupInfo, usize, voidptr, usize, voidptr, &usize) ErrorCode
	pub type PFN_clGetKernelSuggestedLocalWorkSizeKHR = fn (CommandQueue, Kernel, u32, &usize, &usize, &usize) ErrorCode
	pub type PFN_clCreateSemaphoreWithPropertiesKHR = fn (Context, &SemaphorePropertiesKhr, &ErrorCode) SemaphoreKhr
	pub type PFN_clEnqueueWaitSemaphoresKHR = fn (CommandQueue, u32, &SemaphoreKhr, &SemaphorePayloadKhr, u32, &Event, &Event) ErrorCode
	pub type PFN_clEnqueueSignalSemaphoresKHR = fn (CommandQueue, u32, &SemaphoreKhr, &SemaphorePayloadKhr, u32, &Event, &Event) ErrorCode
	pub type PFN_clGetSemaphoreInfoKHR = fn (SemaphoreKhr, SemaphoreInfoKhr, usize, voidptr, &usize) ErrorCode
	pub type PFN_clReleaseSemaphoreKHR = fn (SemaphoreKhr) ErrorCode
	pub type PFN_clRetainSemaphoreKHR = fn (SemaphoreKhr) ErrorCode
	pub type PFN_clGetSemaphoreHandleForTypeKHR = fn (SemaphoreKhr, DeviceId, ExternalSemaphoreHandleTypeKhr, usize, voidptr, &usize) ErrorCode
	pub type PFN_clReImportSemaphoreSyncFdKHR = fn (SemaphoreKhr, &SemaphoreReimportPropertiesKhr, int) ErrorCode
	pub type PFN_clEnqueueAcquireExternalMemObjectsKHR = fn (CommandQueue, u32, &Mem, u32, &Event, &Event) ErrorCode
	pub type PFN_clEnqueueReleaseExternalMemObjectsKHR = fn (CommandQueue, u32, &Mem, u32, &Event, &Event) ErrorCode
}

@[inline]
pub fn get_platform_ids(num_entries u32, platforms &PlatformId, num_platforms &u32) ErrorCode {
	return C.clGetPlatformIDs(num_entries, platforms, num_platforms)
}

@[inline]
pub fn get_platform_info(platform PlatformId, param_name PlatformInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetPlatformInfo(platform, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_device_ids(platform PlatformId, device_type DeviceType, num_entries u32, devices &DeviceId, num_devices &u32) ErrorCode {
	return C.clGetDeviceIDs(platform, device_type, num_entries, devices, num_devices)
}

@[inline]
pub fn get_device_info(device DeviceId, param_name DeviceInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetDeviceInfo(device, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn create_context(properties &ContextProperties, num_devices u32, devices &DeviceId, pfn_notify ContextNotifyCallback, user_data voidptr, errcode_ret &ErrorCode) Context {
	return C.clCreateContext(properties, num_devices, devices, pfn_notify, user_data, errcode_ret)
}

@[inline]
pub fn create_context_from_type(properties &ContextProperties, device_type DeviceType, pfn_notify ContextNotifyCallback, user_data voidptr, errcode_ret &ErrorCode) Context {
	return C.clCreateContextFromType(properties, device_type, pfn_notify, user_data, errcode_ret)
}

@[inline]
pub fn retain_context(context Context) ErrorCode {
	return C.clRetainContext(context)
}

@[inline]
pub fn release_context(context Context) ErrorCode {
	return C.clReleaseContext(context)
}

@[inline]
pub fn get_context_info(context Context, param_name ContextInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetContextInfo(context, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn retain_command_queue(command_queue CommandQueue) ErrorCode {
	return C.clRetainCommandQueue(command_queue)
}

@[inline]
pub fn release_command_queue(command_queue CommandQueue) ErrorCode {
	return C.clReleaseCommandQueue(command_queue)
}

@[inline]
pub fn get_command_queue_info(command_queue CommandQueue, param_name CommandQueueInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetCommandQueueInfo(command_queue, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn create_buffer(context Context, flags MemFlags, size usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateBuffer(context, flags, size, host_ptr, errcode_ret)
}

@[inline]
pub fn retain_mem_object(memobj Mem) ErrorCode {
	return C.clRetainMemObject(memobj)
}

@[inline]
pub fn release_mem_object(memobj Mem) ErrorCode {
	return C.clReleaseMemObject(memobj)
}

@[inline]
pub fn get_supported_image_formats(context Context, flags MemFlags, image_type MemObjectType, num_entries u32, image_formats &ImageFormat, num_image_formats &u32) ErrorCode {
	return C.clGetSupportedImageFormats(context, flags, image_type, num_entries, image_formats, num_image_formats)
}

@[inline]
pub fn get_mem_object_info(memobj Mem, param_name MemInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetMemObjectInfo(memobj, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_image_info(image Mem, param_name ImageInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetImageInfo(image, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn retain_sampler(sampler Sampler) ErrorCode {
	return C.clRetainSampler(sampler)
}

@[inline]
pub fn release_sampler(sampler Sampler) ErrorCode {
	return C.clReleaseSampler(sampler)
}

@[inline]
pub fn get_sampler_info(sampler Sampler, param_name SamplerInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetSamplerInfo(sampler, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn create_program_with_source(context Context, count u32, strings &&char, lengths &usize, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithSource(context, count, strings, lengths, errcode_ret)
}

@[inline]
pub fn create_program_with_binary(context Context, num_devices u32, device_list &DeviceId, lengths &usize, binaries &&u8, binary_status &i32, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithBinary(context, num_devices, device_list, lengths, binaries, binary_status, errcode_ret)
}

@[inline]
pub fn retain_program(program Program) ErrorCode {
	return C.clRetainProgram(program)
}

@[inline]
pub fn release_program(program Program) ErrorCode {
	return C.clReleaseProgram(program)
}

@[inline]
pub fn build_program(program Program, num_devices u32, device_list &DeviceId, options &char, pfn_notify ProgramCallback, user_data voidptr) ErrorCode {
	return C.clBuildProgram(program, num_devices, device_list, options, pfn_notify, user_data)
}

@[inline]
pub fn get_program_info(program Program, param_name ProgramInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetProgramInfo(program, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_program_build_info(program Program, device DeviceId, param_name ProgramBuildInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetProgramBuildInfo(program, device, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn create_kernel(program Program, kernel_name &char, errcode_ret &ErrorCode) Kernel {
	return C.clCreateKernel(program, kernel_name, errcode_ret)
}

@[inline]
pub fn create_kernels_in_program(program Program, num_kernels u32, kernels &Kernel, num_kernels_ret &u32) ErrorCode {
	return C.clCreateKernelsInProgram(program, num_kernels, kernels, num_kernels_ret)
}

@[inline]
pub fn retain_kernel(kernel Kernel) ErrorCode {
	return C.clRetainKernel(kernel)
}

@[inline]
pub fn release_kernel(kernel Kernel) ErrorCode {
	return C.clReleaseKernel(kernel)
}

@[inline]
pub fn set_kernel_arg(kernel Kernel, arg_index u32, arg_size usize, arg_value voidptr) ErrorCode {
	return C.clSetKernelArg(kernel, arg_index, arg_size, arg_value)
}

@[inline]
pub fn get_kernel_info(kernel Kernel, param_name KernelInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetKernelInfo(kernel, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_kernel_work_group_info(kernel Kernel, device DeviceId, param_name KernelWorkGroupInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetKernelWorkGroupInfo(kernel, device, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn wait_for_events(num_events u32, event_list &Event) ErrorCode {
	return C.clWaitForEvents(num_events, event_list)
}

@[inline]
pub fn get_event_info(event Event, param_name EventInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetEventInfo(event, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn retain_event(event Event) ErrorCode {
	return C.clRetainEvent(event)
}

@[inline]
pub fn release_event(event Event) ErrorCode {
	return C.clReleaseEvent(event)
}

@[inline]
pub fn get_event_profiling_info(event Event, param_name ProfilingInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetEventProfilingInfo(event, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn flush(command_queue CommandQueue) ErrorCode {
	return C.clFlush(command_queue)
}

@[inline]
pub fn finish(command_queue CommandQueue) ErrorCode {
	return C.clFinish(command_queue)
}

@[inline]
pub fn enqueue_read_buffer(command_queue CommandQueue, buffer Mem, blocking_read Bool, offset usize, size usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadBuffer(command_queue, buffer, blocking_read, offset, size, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_write_buffer(command_queue CommandQueue, buffer Mem, blocking_write Bool, offset usize, size usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueWriteBuffer(command_queue, buffer, blocking_write, offset, size, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_buffer(command_queue CommandQueue, src_buffer Mem, dst_buffer Mem, src_offset usize, dst_offset usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyBuffer(command_queue, src_buffer, dst_buffer, src_offset, dst_offset, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_read_image(command_queue CommandQueue, image Mem, blocking_read Bool, origin &usize, region &usize, row_pitch usize, slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadImage(command_queue, image, blocking_read, origin, region, row_pitch, slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_write_image(command_queue CommandQueue, image Mem, blocking_write Bool, origin &usize, region &usize, input_row_pitch usize, input_slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueWriteImage(command_queue, image, blocking_write, origin, region, input_row_pitch, input_slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_image(command_queue CommandQueue, src_image Mem, dst_image Mem, src_origin &usize, dst_origin &usize, region &usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyImage(command_queue, src_image, dst_image, src_origin, dst_origin, region, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_image_to_buffer(command_queue CommandQueue, src_image Mem, dst_buffer Mem, src_origin &usize, region &usize, dst_offset usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyImageToBuffer(command_queue, src_image, dst_buffer, src_origin, region, dst_offset, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_buffer_to_image(command_queue CommandQueue, src_buffer Mem, dst_image Mem, src_offset usize, dst_origin &usize, region &usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyBufferToImage(command_queue, src_buffer, dst_image, src_offset, dst_origin, region, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_map_buffer(command_queue CommandQueue, buffer Mem, blocking_map Bool, map_flags MapFlags, offset usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event, errcode_ret &ErrorCode) voidptr {
	return C.clEnqueueMapBuffer(command_queue, buffer, blocking_map, map_flags, offset, size, num_events_in_wait_list, event_wait_list, event, errcode_ret)
}

@[inline]
pub fn enqueue_map_image(command_queue CommandQueue, image Mem, blocking_map Bool, map_flags MapFlags, origin &usize, region &usize, image_row_pitch &usize, image_slice_pitch &usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event, errcode_ret &ErrorCode) voidptr {
	return C.clEnqueueMapImage(command_queue, image, blocking_map, map_flags, origin, region, image_row_pitch, image_slice_pitch, num_events_in_wait_list, event_wait_list, event, errcode_ret)
}

@[inline]
pub fn enqueue_unmap_mem_object(command_queue CommandQueue, memobj Mem, mapped_ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueUnmapMemObject(command_queue, memobj, mapped_ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_nd_range_kernel(command_queue CommandQueue, kernel Kernel, work_dim u32, global_work_offset &usize, global_work_size &usize, local_work_size &usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueNDRangeKernel(command_queue, kernel, work_dim, global_work_offset, global_work_size, local_work_size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_native_kernel(command_queue CommandQueue, user_func NativeKernelCallback, args voidptr, cb_args usize, num_mem_objects u32, mem_list &Mem, args_mem_loc &voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueNativeKernel(command_queue, user_func, args, cb_args, num_mem_objects, mem_list, args_mem_loc, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn set_command_queue_property(command_queue CommandQueue, properties CommandQueueProperties, enable Bool, old_properties &CommandQueueProperties) ErrorCode {
	return C.clSetCommandQueueProperty(command_queue, properties, enable, old_properties)
}

@[inline]
pub fn create_image2d(context Context, flags MemFlags, image_format &ImageFormat, image_width usize, image_height usize, image_row_pitch usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateImage2D(context, flags, image_format, image_width, image_height, image_row_pitch, host_ptr, errcode_ret)
}

@[inline]
pub fn create_image3d(context Context, flags MemFlags, image_format &ImageFormat, image_width usize, image_height usize, image_depth usize, image_row_pitch usize, image_slice_pitch usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateImage3D(context, flags, image_format, image_width, image_height, image_depth, image_row_pitch, image_slice_pitch, host_ptr, errcode_ret)
}

@[inline]
pub fn enqueue_marker(command_queue CommandQueue, event &Event) ErrorCode {
	return C.clEnqueueMarker(command_queue, event)
}

@[inline]
pub fn enqueue_wait_for_events(command_queue CommandQueue, num_events u32, event_list &Event) ErrorCode {
	return C.clEnqueueWaitForEvents(command_queue, num_events, event_list)
}

@[inline]
pub fn enqueue_barrier(command_queue CommandQueue) ErrorCode {
	return C.clEnqueueBarrier(command_queue)
}

@[inline]
pub fn unload_compiler() ErrorCode {
	return C.clUnloadCompiler()
}

@[inline]
pub fn get_extension_function_address(func_name &char) voidptr {
	return C.clGetExtensionFunctionAddress(func_name)
}

@[inline]
pub fn create_command_queue(context Context, device DeviceId, properties CommandQueueProperties, errcode_ret &ErrorCode) CommandQueue {
	return C.clCreateCommandQueue(context, device, properties, errcode_ret)
}

@[inline]
pub fn create_sampler(context Context, normalized_coords Bool, addressing_mode AddressingMode, filter_mode FilterMode, errcode_ret &ErrorCode) Sampler {
	return C.clCreateSampler(context, normalized_coords, addressing_mode, filter_mode, errcode_ret)
}

@[inline]
pub fn enqueue_task(command_queue CommandQueue, kernel Kernel, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueTask(command_queue, kernel, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn create_sub_buffer(buffer Mem, flags MemFlags, buffer_create_type BufferCreateType, buffer_create_info voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateSubBuffer(buffer, flags, buffer_create_type, buffer_create_info, errcode_ret)
}

@[inline]
pub fn set_mem_object_destructor_callback(memobj Mem, pfn_notify MemObjectDestructorCallback, user_data voidptr) ErrorCode {
	return C.clSetMemObjectDestructorCallback(memobj, pfn_notify, user_data)
}

@[inline]
pub fn create_user_event(context Context, errcode_ret &ErrorCode) Event {
	return C.clCreateUserEvent(context, errcode_ret)
}

@[inline]
pub fn set_user_event_status(event Event, execution_status i32) ErrorCode {
	return C.clSetUserEventStatus(event, execution_status)
}

@[inline]
pub fn set_event_callback(event Event, command_exec_callback_type i32, pfn_notify EventCallback, user_data voidptr) ErrorCode {
	return C.clSetEventCallback(event, command_exec_callback_type, pfn_notify, user_data)
}

@[inline]
pub fn enqueue_read_buffer_rect(command_queue CommandQueue, buffer Mem, blocking_read Bool, buffer_origin &usize, host_origin &usize, region &usize, buffer_row_pitch usize, buffer_slice_pitch usize, host_row_pitch usize, host_slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadBufferRect(command_queue, buffer, blocking_read, buffer_origin, host_origin, region, buffer_row_pitch, buffer_slice_pitch, host_row_pitch, host_slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_write_buffer_rect(command_queue CommandQueue, buffer Mem, blocking_write Bool, buffer_origin &usize, host_origin &usize, region &usize, buffer_row_pitch usize, buffer_slice_pitch usize, host_row_pitch usize, host_slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueWriteBufferRect(command_queue, buffer, blocking_write, buffer_origin, host_origin, region, buffer_row_pitch, buffer_slice_pitch, host_row_pitch, host_slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_buffer_rect(command_queue CommandQueue, src_buffer Mem, dst_buffer Mem, src_origin &usize, dst_origin &usize, region &usize, src_row_pitch usize, src_slice_pitch usize, dst_row_pitch usize, dst_slice_pitch usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyBufferRect(command_queue, src_buffer, dst_buffer, src_origin, dst_origin, region, src_row_pitch, src_slice_pitch, dst_row_pitch, dst_slice_pitch, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn create_sub_devices(in_device DeviceId, properties &DevicePartitionProperty, num_devices u32, out_devices &DeviceId, num_devices_ret &u32) ErrorCode {
	return C.clCreateSubDevices(in_device, properties, num_devices, out_devices, num_devices_ret)
}

@[inline]
pub fn retain_device(device DeviceId) ErrorCode {
	return C.clRetainDevice(device)
}

@[inline]
pub fn release_device(device DeviceId) ErrorCode {
	return C.clReleaseDevice(device)
}

@[inline]
pub fn create_image(context Context, flags MemFlags, image_format &ImageFormat, image_desc &ImageDesc, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateImage(context, flags, image_format, image_desc, host_ptr, errcode_ret)
}

@[inline]
pub fn create_program_with_built_in_kernels(context Context, num_devices u32, device_list &DeviceId, kernel_names &char, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithBuiltInKernels(context, num_devices, device_list, kernel_names, errcode_ret)
}

@[inline]
pub fn compile_program(program Program, num_devices u32, device_list &DeviceId, options &char, num_input_headers u32, input_headers &Program, header_include_names &&char, pfn_notify ProgramCallback, user_data voidptr) ErrorCode {
	return C.clCompileProgram(program, num_devices, device_list, options, num_input_headers, input_headers, header_include_names, pfn_notify, user_data)
}

@[inline]
pub fn link_program(context Context, num_devices u32, device_list &DeviceId, options &char, num_input_programs u32, input_programs &Program, pfn_notify ProgramCallback, user_data voidptr, errcode_ret &ErrorCode) Program {
	return C.clLinkProgram(context, num_devices, device_list, options, num_input_programs, input_programs, pfn_notify, user_data, errcode_ret)
}

@[inline]
pub fn unload_platform_compiler(platform PlatformId) ErrorCode {
	return C.clUnloadPlatformCompiler(platform)
}

@[inline]
pub fn get_kernel_arg_info(kernel Kernel, arg_index u32, param_name KernelArgInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetKernelArgInfo(kernel, arg_index, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn enqueue_fill_buffer(command_queue CommandQueue, buffer Mem, pattern voidptr, pattern_size usize, offset usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueFillBuffer(command_queue, buffer, pattern, pattern_size, offset, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_fill_image(command_queue CommandQueue, image Mem, fill_color voidptr, origin &usize, region &usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueFillImage(command_queue, image, fill_color, origin, region, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_migrate_mem_objects(command_queue CommandQueue, num_mem_objects u32, mem_objects &Mem, flags MemMigrationFlags, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueMigrateMemObjects(command_queue, num_mem_objects, mem_objects, flags, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_marker_with_wait_list(command_queue CommandQueue, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueMarkerWithWaitList(command_queue, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_barrier_with_wait_list(command_queue CommandQueue, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueBarrierWithWaitList(command_queue, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn get_extension_function_address_for_platform(platform PlatformId, func_name &char) voidptr {
	return C.clGetExtensionFunctionAddressForPlatform(platform, func_name)
}

@[inline]
pub fn create_command_queue_with_properties(context Context, device DeviceId, properties &QueueProperties, errcode_ret &ErrorCode) CommandQueue {
	return C.clCreateCommandQueueWithProperties(context, device, properties, errcode_ret)
}

@[inline]
pub fn create_pipe(context Context, flags MemFlags, pipe_packet_size u32, pipe_max_packets u32, properties &PipeProperties, errcode_ret &ErrorCode) Mem {
	return C.clCreatePipe(context, flags, pipe_packet_size, pipe_max_packets, properties, errcode_ret)
}

@[inline]
pub fn get_pipe_info(pipe Mem, param_name PipeInfo, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetPipeInfo(pipe, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn svm_alloc(context Context, flags SvmMemFlags, size usize, alignment u32) voidptr {
	return C.clSVMAlloc(context, flags, size, alignment)
}

@[inline]
pub fn svm_free(context Context, svm_pointer voidptr) {
	C.clSVMFree(context, svm_pointer)
}

@[inline]
pub fn create_sampler_with_properties(context Context, sampler_properties &SamplerProperties, errcode_ret &ErrorCode) Sampler {
	return C.clCreateSamplerWithProperties(context, sampler_properties, errcode_ret)
}

@[inline]
pub fn set_kernel_arg_svm_pointer(kernel Kernel, arg_index u32, arg_value voidptr) ErrorCode {
	return C.clSetKernelArgSVMPointer(kernel, arg_index, arg_value)
}

@[inline]
pub fn set_kernel_exec_info(kernel Kernel, param_name KernelExecInfo, param_value_size usize, param_value voidptr) ErrorCode {
	return C.clSetKernelExecInfo(kernel, param_name, param_value_size, param_value)
}

@[inline]
pub fn enqueue_svm_free(command_queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, pfn_free_func SvmFreeCallback, user_data voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMFree(command_queue, num_svm_pointers, svm_pointers, pfn_free_func, user_data, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_memcpy(command_queue CommandQueue, blocking_copy Bool, dst_ptr voidptr, src_ptr voidptr, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMemcpy(command_queue, blocking_copy, dst_ptr, src_ptr, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_mem_fill(command_queue CommandQueue, svm_ptr voidptr, pattern voidptr, pattern_size usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMemFill(command_queue, svm_ptr, pattern, pattern_size, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_map(command_queue CommandQueue, blocking_map Bool, flags MapFlags, svm_ptr voidptr, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMap(command_queue, blocking_map, flags, svm_ptr, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_unmap(command_queue CommandQueue, svm_ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMUnmap(command_queue, svm_ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn set_default_device_command_queue(context Context, device DeviceId, command_queue CommandQueue) ErrorCode {
	return C.clSetDefaultDeviceCommandQueue(context, device, command_queue)
}

@[inline]
pub fn get_device_and_host_timer(device DeviceId, device_timestamp &u64, host_timestamp &u64) ErrorCode {
	return C.clGetDeviceAndHostTimer(device, device_timestamp, host_timestamp)
}

@[inline]
pub fn get_host_timer(device DeviceId, host_timestamp &u64) ErrorCode {
	return C.clGetHostTimer(device, host_timestamp)
}

@[inline]
pub fn create_program_with_il(context Context, il voidptr, length usize, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithIL(context, il, length, errcode_ret)
}

@[inline]
pub fn clone_kernel(source_kernel Kernel, errcode_ret &ErrorCode) Kernel {
	return C.clCloneKernel(source_kernel, errcode_ret)
}

@[inline]
pub fn get_kernel_sub_group_info(kernel Kernel, device DeviceId, param_name KernelSubGroupInfo, input_value_size usize, input_value voidptr, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetKernelSubGroupInfo(kernel, device, param_name, input_value_size, input_value, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn enqueue_svm_migrate_mem(command_queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, sizes &usize, flags MemMigrationFlags, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMigrateMem(command_queue, num_svm_pointers, svm_pointers, sizes, flags, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn set_program_specialization_constant(program Program, spec_id u32, spec_size usize, spec_value voidptr) ErrorCode {
	return C.clSetProgramSpecializationConstant(program, spec_id, spec_size, spec_value)
}

@[inline]
pub fn set_program_release_callback(program Program, pfn_notify ProgramCallback, user_data voidptr) ErrorCode {
	return C.clSetProgramReleaseCallback(program, pfn_notify, user_data)
}

@[inline]
pub fn set_context_destructor_callback(context Context, pfn_notify ContextDestructorCallback, user_data voidptr) ErrorCode {
	return C.clSetContextDestructorCallback(context, pfn_notify, user_data)
}

@[inline]
pub fn create_buffer_with_properties(context Context, properties &MemProperties, flags MemFlags, size usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateBufferWithProperties(context, properties, flags, size, host_ptr, errcode_ret)
}

@[inline]
pub fn create_image_with_properties(context Context, properties &MemProperties, flags MemFlags, image_format &ImageFormat, image_desc &ImageDesc, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateImageWithProperties(context, properties, flags, image_format, image_desc, host_ptr, errcode_ret)
}

@[inline]
pub fn create_program_with_il_khr(context Context, il voidptr, length usize, errcode_ret &ErrorCode) Program {
	extension_fn := unsafe { PFN_clCreateProgramWithILKHR(C.clGetExtensionFunctionAddress(c'clCreateProgramWithILKHR')) }
	if isnil(extension_fn) {
		if !isnil(errcode_ret) {
			unsafe { *errcode_ret = invalid_operation }
		}
		return Program(unsafe { nil })
	}
	return extension_fn(context, il, length, errcode_ret)
}

@[inline]
pub fn create_command_queue_with_properties_khr(context Context, device DeviceId, properties &QueuePropertiesKhr, errcode_ret &ErrorCode) CommandQueue {
	extension_fn := unsafe { PFN_clCreateCommandQueueWithPropertiesKHR(C.clGetExtensionFunctionAddress(c'clCreateCommandQueueWithPropertiesKHR')) }
	if isnil(extension_fn) {
		if !isnil(errcode_ret) {
			unsafe { *errcode_ret = invalid_operation }
		}
		return CommandQueue(unsafe { nil })
	}
	return extension_fn(context, device, properties, errcode_ret)
}

@[inline]
pub fn get_kernel_sub_group_info_khr(in_kernel Kernel, in_device DeviceId, param_name KernelSubGroupInfo, input_value_size usize, input_value voidptr, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	extension_fn := unsafe { PFN_clGetKernelSubGroupInfoKHR(C.clGetExtensionFunctionAddress(c'clGetKernelSubGroupInfoKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(in_kernel, in_device, param_name, input_value_size, input_value, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_kernel_suggested_local_work_size_khr(command_queue CommandQueue, kernel Kernel, work_dim u32, global_work_offset &usize, global_work_size &usize, suggested_local_work_size &usize) ErrorCode {
	extension_fn := unsafe { PFN_clGetKernelSuggestedLocalWorkSizeKHR(C.clGetExtensionFunctionAddress(c'clGetKernelSuggestedLocalWorkSizeKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(command_queue, kernel, work_dim, global_work_offset, global_work_size, suggested_local_work_size)
}

@[inline]
pub fn create_semaphore_with_properties_khr(context Context, sema_props &SemaphorePropertiesKhr, errcode_ret &ErrorCode) SemaphoreKhr {
	extension_fn := unsafe { PFN_clCreateSemaphoreWithPropertiesKHR(C.clGetExtensionFunctionAddress(c'clCreateSemaphoreWithPropertiesKHR')) }
	if isnil(extension_fn) {
		if !isnil(errcode_ret) {
			unsafe { *errcode_ret = invalid_operation }
		}
		return SemaphoreKhr(unsafe { nil })
	}
	return extension_fn(context, sema_props, errcode_ret)
}

@[inline]
pub fn enqueue_wait_semaphores_khr(command_queue CommandQueue, num_sema_objects u32, sema_objects &SemaphoreKhr, sema_payload_list &SemaphorePayloadKhr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	extension_fn := unsafe { PFN_clEnqueueWaitSemaphoresKHR(C.clGetExtensionFunctionAddress(c'clEnqueueWaitSemaphoresKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(command_queue, num_sema_objects, sema_objects, sema_payload_list, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_signal_semaphores_khr(command_queue CommandQueue, num_sema_objects u32, sema_objects &SemaphoreKhr, sema_payload_list &SemaphorePayloadKhr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	extension_fn := unsafe { PFN_clEnqueueSignalSemaphoresKHR(C.clGetExtensionFunctionAddress(c'clEnqueueSignalSemaphoresKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(command_queue, num_sema_objects, sema_objects, sema_payload_list, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn get_semaphore_info_khr(sema_object SemaphoreKhr, param_name SemaphoreInfoKhr, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	extension_fn := unsafe { PFN_clGetSemaphoreInfoKHR(C.clGetExtensionFunctionAddress(c'clGetSemaphoreInfoKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(sema_object, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn release_semaphore_khr(sema_object SemaphoreKhr) ErrorCode {
	extension_fn := unsafe { PFN_clReleaseSemaphoreKHR(C.clGetExtensionFunctionAddress(c'clReleaseSemaphoreKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(sema_object)
}

@[inline]
pub fn retain_semaphore_khr(sema_object SemaphoreKhr) ErrorCode {
	extension_fn := unsafe { PFN_clRetainSemaphoreKHR(C.clGetExtensionFunctionAddress(c'clRetainSemaphoreKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(sema_object)
}

@[inline]
pub fn get_semaphore_handle_for_type_khr(sema_object SemaphoreKhr, device DeviceId, handle_type ExternalSemaphoreHandleTypeKhr, handle_size usize, handle_ptr voidptr, handle_size_ret &usize) ErrorCode {
	extension_fn := unsafe { PFN_clGetSemaphoreHandleForTypeKHR(C.clGetExtensionFunctionAddress(c'clGetSemaphoreHandleForTypeKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(sema_object, device, handle_type, handle_size, handle_ptr, handle_size_ret)
}

@[inline]
pub fn re_import_semaphore_sync_fd_khr(sema_object SemaphoreKhr, reimport_props &SemaphoreReimportPropertiesKhr, fd int) ErrorCode {
	extension_fn := unsafe { PFN_clReImportSemaphoreSyncFdKHR(C.clGetExtensionFunctionAddress(c'clReImportSemaphoreSyncFdKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(sema_object, reimport_props, fd)
}

@[inline]
pub fn enqueue_acquire_external_mem_objects_khr(command_queue CommandQueue, num_mem_objects u32, mem_objects &Mem, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	extension_fn := unsafe { PFN_clEnqueueAcquireExternalMemObjectsKHR(C.clGetExtensionFunctionAddress(c'clEnqueueAcquireExternalMemObjectsKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(command_queue, num_mem_objects, mem_objects, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_release_external_mem_objects_khr(command_queue CommandQueue, num_mem_objects u32, mem_objects &Mem, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	extension_fn := unsafe { PFN_clEnqueueReleaseExternalMemObjectsKHR(C.clGetExtensionFunctionAddress(c'clEnqueueReleaseExternalMemObjectsKHR')) }
	if isnil(extension_fn) {
		return invalid_operation
	}
	return extension_fn(command_queue, num_mem_objects, mem_objects, num_events_in_wait_list, event_wait_list, event)
}
