// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
module opencl

#flag linux -lOpenCL

#flag windows -lOpenCL

#include <CL/opencl.h>

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

pub const mem_read_only = MemFlags(1 << 2)
pub const mem_write_only = MemFlags(1 << 1)
pub const mem_copy_host_ptr = MemFlags(1 << 5)

pub const program_build_log = ProgramBuildInfo(0x1183)

pub const _false = u32(0)
pub const _true = u32(1)

fn C.clGetPlatformIDs(u32, &PlatformId, &u32) ErrorCode

fn C.clGetPlatformInfo(PlatformId, PlatformInfo, usize, voidptr, &usize) ErrorCode

fn C.clGetDeviceIDs(PlatformId, DeviceType, u32, &DeviceId, &u32) ErrorCode

fn C.clGetDeviceInfo(DeviceId, DeviceInfo, usize, voidptr, &usize) ErrorCode

fn C.clCreateContext(&isize, u32, &DeviceId, voidptr, voidptr, &ErrorCode) Context

fn C.clReleaseContext(Context) ErrorCode

fn C.clCreateCommandQueue(Context, DeviceId, CommandQueueProperties, &ErrorCode) CommandQueue

fn C.clReleaseCommandQueue(CommandQueue) ErrorCode

fn C.clCreateBuffer(Context, MemFlags, usize, voidptr, &ErrorCode) Mem

fn C.clReleaseMemObject(Mem) ErrorCode

fn C.clCreateProgramWithSource(Context, u32, &&char, &usize, &ErrorCode) Program

fn C.clBuildProgram(Program, u32, &DeviceId, &char, voidptr, voidptr) ErrorCode

fn C.clGetProgramBuildInfo(Program, DeviceId, ProgramBuildInfo, usize, voidptr, &usize) ErrorCode

fn C.clReleaseProgram(Program) ErrorCode

fn C.clCreateKernel(Program, &char, &ErrorCode) Kernel

fn C.clSetKernelArg(Kernel, u32, usize, voidptr) ErrorCode

fn C.clReleaseKernel(Kernel) ErrorCode

fn C.clEnqueueNDRangeKernel(CommandQueue, Kernel, u32, &usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueReadBuffer(CommandQueue, Mem, u32, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clFinish(CommandQueue) ErrorCode

pub fn get_platform_ids(num_entries u32, platforms &PlatformId, num_platforms &u32) ErrorCode {
	return C.clGetPlatformIDs(num_entries, platforms, num_platforms)
}

pub fn get_platform_info(platform PlatformId, param_name PlatformInfo, param_value_size usize,
	param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetPlatformInfo(platform, param_name, param_value_size, param_value, param_value_size_ret)
}

pub fn get_device_ids(platform PlatformId, device_type DeviceType, num_entries u32,
	devices &DeviceId, num_devices &u32) ErrorCode {
	return C.clGetDeviceIDs(platform, device_type, num_entries, devices, num_devices)
}

pub fn get_device_info(device DeviceId, param_name DeviceInfo, param_value_size usize,
	param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetDeviceInfo(device, param_name, param_value_size, param_value, param_value_size_ret)
}

pub fn create_context(properties &isize, num_devices u32, devices &DeviceId,
	pfn_notify voidptr, user_data voidptr, errcode_ret &ErrorCode) Context {
	return C.clCreateContext(properties, num_devices, devices, pfn_notify, user_data, errcode_ret)
}

pub fn release_context(context Context) ErrorCode {
	return C.clReleaseContext(context)
}

pub fn create_command_queue(context Context, device DeviceId,
	properties CommandQueueProperties, errcode_ret &ErrorCode) CommandQueue {
	return C.clCreateCommandQueue(context, device, properties, errcode_ret)
}

pub fn release_command_queue(command_queue CommandQueue) ErrorCode {
	return C.clReleaseCommandQueue(command_queue)
}

pub fn create_buffer(context Context, flags MemFlags, size usize, host_ptr voidptr,
	errcode_ret &ErrorCode) Mem {
	return C.clCreateBuffer(context, flags, size, host_ptr, errcode_ret)
}

pub fn release_mem_object(memobj Mem) ErrorCode {
	return C.clReleaseMemObject(memobj)
}

pub fn create_program_with_source(context Context, count u32, strings &&char,
	lengths &usize, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithSource(context, count, strings, lengths, errcode_ret)
}

pub fn build_program(program Program, num_devices u32, device_list &DeviceId,
	options &char, pfn_notify voidptr, user_data voidptr) ErrorCode {
	return C.clBuildProgram(program, num_devices, device_list, options, pfn_notify, user_data)
}

pub fn get_program_build_info(program Program, device DeviceId, param_name ProgramBuildInfo,
	param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetProgramBuildInfo(program, device, param_name, param_value_size, param_value, param_value_size_ret)
}

pub fn release_program(program Program) ErrorCode {
	return C.clReleaseProgram(program)
}

pub fn create_kernel(program Program, kernel_name &char, errcode_ret &ErrorCode) Kernel {
	return C.clCreateKernel(program, kernel_name, errcode_ret)
}

pub fn set_kernel_arg(kernel Kernel, arg_index u32, arg_size usize, arg_value voidptr) ErrorCode {
	return C.clSetKernelArg(kernel, arg_index, arg_size, arg_value)
}

pub fn release_kernel(kernel Kernel) ErrorCode {
	return C.clReleaseKernel(kernel)
}

pub fn enqueue_nd_range_kernel(command_queue CommandQueue, kernel Kernel, work_dim u32,
	global_work_offset &usize, global_work_size &usize, local_work_size &usize,
	num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueNDRangeKernel(command_queue, kernel, work_dim, global_work_offset, global_work_size, local_work_size, num_events_in_wait_list, event_wait_list, event)
}

pub fn enqueue_read_buffer(command_queue CommandQueue, buffer Mem, blocking_read u32,
	offset usize, size usize, ptr voidptr, num_events_in_wait_list u32,
	event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadBuffer(command_queue, buffer, blocking_read, offset, size, ptr, num_events_in_wait_list, event_wait_list, event)
}

pub fn finish(command_queue CommandQueue) ErrorCode {
	return C.clFinish(command_queue)
}
