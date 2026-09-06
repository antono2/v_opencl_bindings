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

pub const event_command_execution_status = EventInfo(0x11D3)

pub const complete = i32(0x0)
pub const running = i32(0x1)
pub const submitted = i32(0x2)
pub const queued = i32(0x3)

pub const _false = u32(0)
pub const _true = u32(1)

fn C.clGetPlatformIDs(u32, &PlatformId, &u32) ErrorCode

fn C.clGetPlatformInfo(PlatformId, u32, usize, voidptr, &usize) ErrorCode

fn C.clGetDeviceIDs(PlatformId, u64, u32, &DeviceId, &u32) ErrorCode

fn C.clGetDeviceInfo(DeviceId, u32, usize, voidptr, &usize) ErrorCode

fn C.clCreateContext(&isize, u32, &DeviceId, voidptr, voidptr, &ErrorCode) Context

fn C.clCreateContextFromType(&isize, u64, voidptr, voidptr, &ErrorCode) Context

fn C.clRetainContext(Context) ErrorCode

fn C.clReleaseContext(Context) ErrorCode

fn C.clGetContextInfo(Context, u32, usize, voidptr, &usize) ErrorCode

fn C.clRetainCommandQueue(CommandQueue) ErrorCode

fn C.clReleaseCommandQueue(CommandQueue) ErrorCode

fn C.clGetCommandQueueInfo(CommandQueue, u32, usize, voidptr, &usize) ErrorCode

fn C.clCreateBuffer(Context, u64, usize, voidptr, &ErrorCode) Mem

fn C.clRetainMemObject(Mem) ErrorCode

fn C.clReleaseMemObject(Mem) ErrorCode

fn C.clGetSupportedImageFormats(Context, u64, u32, u32, &ImageFormat, &u32) ErrorCode

fn C.clGetMemObjectInfo(Mem, u32, usize, voidptr, &usize) ErrorCode

fn C.clGetImageInfo(Mem, u32, usize, voidptr, &usize) ErrorCode

fn C.clRetainSampler(Sampler) ErrorCode

fn C.clReleaseSampler(Sampler) ErrorCode

fn C.clGetSamplerInfo(Sampler, u32, usize, voidptr, &usize) ErrorCode

fn C.clCreateProgramWithSource(Context, u32, &&char, &usize, &ErrorCode) Program

fn C.clCreateProgramWithBinary(Context, u32, &DeviceId, &usize, &&u8, &i32, &ErrorCode) Program

fn C.clRetainProgram(Program) ErrorCode

fn C.clReleaseProgram(Program) ErrorCode

fn C.clBuildProgram(Program, u32, &DeviceId, &char, voidptr, voidptr) ErrorCode

fn C.clGetProgramInfo(Program, u32, usize, voidptr, &usize) ErrorCode

fn C.clGetProgramBuildInfo(Program, DeviceId, u32, usize, voidptr, &usize) ErrorCode

fn C.clCreateKernel(Program, &char, &ErrorCode) Kernel

fn C.clCreateKernelsInProgram(Program, u32, &Kernel, &u32) ErrorCode

fn C.clRetainKernel(Kernel) ErrorCode

fn C.clReleaseKernel(Kernel) ErrorCode

fn C.clSetKernelArg(Kernel, u32, usize, voidptr) ErrorCode

fn C.clGetKernelInfo(Kernel, u32, usize, voidptr, &usize) ErrorCode

fn C.clGetKernelWorkGroupInfo(Kernel, DeviceId, u32, usize, voidptr, &usize) ErrorCode

fn C.clWaitForEvents(u32, &Event) ErrorCode

fn C.clGetEventInfo(Event, u32, usize, voidptr, &usize) ErrorCode

fn C.clRetainEvent(Event) ErrorCode

fn C.clReleaseEvent(Event) ErrorCode

fn C.clGetEventProfilingInfo(Event, u32, usize, voidptr, &usize) ErrorCode

fn C.clFlush(CommandQueue) ErrorCode

fn C.clFinish(CommandQueue) ErrorCode

fn C.clEnqueueReadBuffer(CommandQueue, Mem, u32, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueWriteBuffer(CommandQueue, Mem, u32, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyBuffer(CommandQueue, Mem, Mem, usize, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueReadImage(CommandQueue, Mem, u32, &usize, &usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueWriteImage(CommandQueue, Mem, u32, &usize, &usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyImage(CommandQueue, Mem, Mem, &usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyImageToBuffer(CommandQueue, Mem, Mem, &usize, &usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyBufferToImage(CommandQueue, Mem, Mem, usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueMapBuffer(CommandQueue, Mem, u32, u64, usize, usize, u32, &Event, &Event, &ErrorCode) voidptr

fn C.clEnqueueMapImage(CommandQueue, Mem, u32, u64, &usize, &usize, &usize, &usize, u32, &Event, &Event, &ErrorCode) voidptr

fn C.clEnqueueUnmapMemObject(CommandQueue, Mem, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueNDRangeKernel(CommandQueue, Kernel, u32, &usize, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueNativeKernel(CommandQueue, voidptr, voidptr, usize, u32, &Mem, &voidptr, u32, &Event, &Event) ErrorCode

fn C.clSetCommandQueueProperty(CommandQueue, u64, u32, &u64) ErrorCode

fn C.clCreateImage2D(Context, u64, &ImageFormat, usize, usize, usize, voidptr, &ErrorCode) Mem

fn C.clCreateImage3D(Context, u64, &ImageFormat, usize, usize, usize, usize, usize, voidptr, &ErrorCode) Mem

fn C.clEnqueueMarker(CommandQueue, &Event) ErrorCode

fn C.clEnqueueWaitForEvents(CommandQueue, u32, &Event) ErrorCode

fn C.clEnqueueBarrier(CommandQueue) ErrorCode

fn C.clUnloadCompiler() ErrorCode

fn C.clGetExtensionFunctionAddress(&char) voidptr

fn C.clCreateCommandQueue(Context, DeviceId, u64, &ErrorCode) CommandQueue

fn C.clCreateSampler(Context, u32, u32, u32, &ErrorCode) Sampler

fn C.clEnqueueTask(CommandQueue, Kernel, u32, &Event, &Event) ErrorCode

fn C.clCreateSubBuffer(Mem, u64, u32, voidptr, &ErrorCode) Mem

fn C.clSetMemObjectDestructorCallback(Mem, voidptr, voidptr) ErrorCode

fn C.clCreateUserEvent(Context, &ErrorCode) Event

fn C.clSetUserEventStatus(Event, i32) ErrorCode

fn C.clSetEventCallback(Event, i32, voidptr, voidptr) ErrorCode

fn C.clEnqueueReadBufferRect(CommandQueue, Mem, u32, &usize, &usize, &usize, usize, usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueWriteBufferRect(CommandQueue, Mem, u32, &usize, &usize, &usize, usize, usize, usize, usize, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueCopyBufferRect(CommandQueue, Mem, Mem, &usize, &usize, &usize, usize, usize, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clCreateSubDevices(DeviceId, &isize, u32, &DeviceId, &u32) ErrorCode

fn C.clRetainDevice(DeviceId) ErrorCode

fn C.clReleaseDevice(DeviceId) ErrorCode

fn C.clCreateImage(Context, u64, &ImageFormat, &ImageDesc, voidptr, &ErrorCode) Mem

fn C.clCreateProgramWithBuiltInKernels(Context, u32, &DeviceId, &char, &ErrorCode) Program

fn C.clCompileProgram(Program, u32, &DeviceId, &char, u32, &Program, &&char, voidptr, voidptr) ErrorCode

fn C.clLinkProgram(Context, u32, &DeviceId, &char, u32, &Program, voidptr, voidptr, &ErrorCode) Program

fn C.clUnloadPlatformCompiler(PlatformId) ErrorCode

fn C.clGetKernelArgInfo(Kernel, u32, u32, usize, voidptr, &usize) ErrorCode

fn C.clEnqueueFillBuffer(CommandQueue, Mem, voidptr, usize, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueFillImage(CommandQueue, Mem, voidptr, &usize, &usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueMigrateMemObjects(CommandQueue, u32, &Mem, u64, u32, &Event, &Event) ErrorCode

fn C.clEnqueueMarkerWithWaitList(CommandQueue, u32, &Event, &Event) ErrorCode

fn C.clEnqueueBarrierWithWaitList(CommandQueue, u32, &Event, &Event) ErrorCode

fn C.clGetExtensionFunctionAddressForPlatform(PlatformId, &char) voidptr

fn C.clCreateCommandQueueWithProperties(Context, DeviceId, &u64, &ErrorCode) CommandQueue

fn C.clCreatePipe(Context, u64, u32, u32, &isize, &ErrorCode) Mem

fn C.clGetPipeInfo(Mem, u32, usize, voidptr, &usize) ErrorCode

fn C.clSVMAlloc(Context, u64, usize, u32) voidptr

fn C.clSVMFree(Context, voidptr)

fn C.clCreateSamplerWithProperties(Context, &u64, &ErrorCode) Sampler

fn C.clSetKernelArgSVMPointer(Kernel, u32, voidptr) ErrorCode

fn C.clSetKernelExecInfo(Kernel, u32, usize, voidptr) ErrorCode

fn C.clEnqueueSVMFree(CommandQueue, u32, &voidptr, voidptr, voidptr, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMMemcpy(CommandQueue, u32, voidptr, voidptr, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMMemFill(CommandQueue, voidptr, voidptr, usize, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMMap(CommandQueue, u32, u64, voidptr, usize, u32, &Event, &Event) ErrorCode

fn C.clEnqueueSVMUnmap(CommandQueue, voidptr, u32, &Event, &Event) ErrorCode

@[inline]
pub fn get_platform_ids(num_entries u32, platforms &PlatformId, num_platforms &u32) ErrorCode {
	return C.clGetPlatformIDs(num_entries, platforms, num_platforms)
}

@[inline]
pub fn get_platform_info(platform PlatformId, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetPlatformInfo(platform, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_device_ids(platform PlatformId, device_type u64, num_entries u32, devices &DeviceId, num_devices &u32) ErrorCode {
	return C.clGetDeviceIDs(platform, device_type, num_entries, devices, num_devices)
}

@[inline]
pub fn get_device_info(device DeviceId, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetDeviceInfo(device, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn create_context(properties &isize, num_devices u32, devices &DeviceId, pfn_notify voidptr, user_data voidptr, errcode_ret &ErrorCode) Context {
	return C.clCreateContext(properties, num_devices, devices, pfn_notify, user_data, errcode_ret)
}

@[inline]
pub fn create_context_from_type(properties &isize, device_type u64, pfn_notify voidptr, user_data voidptr, errcode_ret &ErrorCode) Context {
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
pub fn get_context_info(context Context, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn get_command_queue_info(command_queue CommandQueue, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetCommandQueueInfo(command_queue, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn create_buffer(context Context, flags u64, size usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
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
pub fn get_supported_image_formats(context Context, flags u64, image_type u32, num_entries u32, image_formats &ImageFormat, num_image_formats &u32) ErrorCode {
	return C.clGetSupportedImageFormats(context, flags, image_type, num_entries, image_formats, num_image_formats)
}

@[inline]
pub fn get_mem_object_info(memobj Mem, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetMemObjectInfo(memobj, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_image_info(image Mem, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn get_sampler_info(sampler Sampler, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn build_program(program Program, num_devices u32, device_list &DeviceId, options &char, pfn_notify voidptr, user_data voidptr) ErrorCode {
	return C.clBuildProgram(program, num_devices, device_list, options, pfn_notify, user_data)
}

@[inline]
pub fn get_program_info(program Program, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetProgramInfo(program, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_program_build_info(program Program, device DeviceId, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn get_kernel_info(kernel Kernel, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetKernelInfo(kernel, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn get_kernel_work_group_info(kernel Kernel, device DeviceId, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetKernelWorkGroupInfo(kernel, device, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn wait_for_events(num_events u32, event_list &Event) ErrorCode {
	return C.clWaitForEvents(num_events, event_list)
}

@[inline]
pub fn get_event_info(event Event, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn get_event_profiling_info(event Event, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn enqueue_read_buffer(command_queue CommandQueue, buffer Mem, blocking_read u32, offset usize, size usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadBuffer(command_queue, buffer, blocking_read, offset, size, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_write_buffer(command_queue CommandQueue, buffer Mem, blocking_write u32, offset usize, size usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueWriteBuffer(command_queue, buffer, blocking_write, offset, size, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_buffer(command_queue CommandQueue, src_buffer Mem, dst_buffer Mem, src_offset usize, dst_offset usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyBuffer(command_queue, src_buffer, dst_buffer, src_offset, dst_offset, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_read_image(command_queue CommandQueue, image Mem, blocking_read u32, origin &usize, region &usize, row_pitch usize, slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadImage(command_queue, image, blocking_read, origin, region, row_pitch, slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_write_image(command_queue CommandQueue, image Mem, blocking_write u32, origin &usize, region &usize, input_row_pitch usize, input_slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
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
pub fn enqueue_map_buffer(command_queue CommandQueue, buffer Mem, blocking_map u32, map_flags u64, offset usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event, errcode_ret &ErrorCode) voidptr {
	return C.clEnqueueMapBuffer(command_queue, buffer, blocking_map, map_flags, offset, size, num_events_in_wait_list, event_wait_list, event, errcode_ret)
}

@[inline]
pub fn enqueue_map_image(command_queue CommandQueue, image Mem, blocking_map u32, map_flags u64, origin &usize, region &usize, image_row_pitch &usize, image_slice_pitch &usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event, errcode_ret &ErrorCode) voidptr {
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
pub fn enqueue_native_kernel(command_queue CommandQueue, user_func voidptr, args voidptr, cb_args usize, num_mem_objects u32, mem_list &Mem, args_mem_loc &voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueNativeKernel(command_queue, user_func, args, cb_args, num_mem_objects, mem_list, args_mem_loc, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn set_command_queue_property(command_queue CommandQueue, properties u64, enable u32, old_properties &u64) ErrorCode {
	return C.clSetCommandQueueProperty(command_queue, properties, enable, old_properties)
}

@[inline]
pub fn create_image2d(context Context, flags u64, image_format &ImageFormat, image_width usize, image_height usize, image_row_pitch usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateImage2D(context, flags, image_format, image_width, image_height, image_row_pitch, host_ptr, errcode_ret)
}

@[inline]
pub fn create_image3d(context Context, flags u64, image_format &ImageFormat, image_width usize, image_height usize, image_depth usize, image_row_pitch usize, image_slice_pitch usize, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
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
pub fn create_command_queue(context Context, device DeviceId, properties u64, errcode_ret &ErrorCode) CommandQueue {
	return C.clCreateCommandQueue(context, device, properties, errcode_ret)
}

@[inline]
pub fn create_sampler(context Context, normalized_coords u32, addressing_mode u32, filter_mode u32, errcode_ret &ErrorCode) Sampler {
	return C.clCreateSampler(context, normalized_coords, addressing_mode, filter_mode, errcode_ret)
}

@[inline]
pub fn enqueue_task(command_queue CommandQueue, kernel Kernel, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueTask(command_queue, kernel, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn create_sub_buffer(buffer Mem, flags u64, buffer_create_type u32, buffer_create_info voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateSubBuffer(buffer, flags, buffer_create_type, buffer_create_info, errcode_ret)
}

@[inline]
pub fn set_mem_object_destructor_callback(memobj Mem, pfn_notify voidptr, user_data voidptr) ErrorCode {
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
pub fn set_event_callback(event Event, command_exec_callback_type i32, pfn_notify voidptr, user_data voidptr) ErrorCode {
	return C.clSetEventCallback(event, command_exec_callback_type, pfn_notify, user_data)
}

@[inline]
pub fn enqueue_read_buffer_rect(command_queue CommandQueue, buffer Mem, blocking_read u32, buffer_origin &usize, host_origin &usize, region &usize, buffer_row_pitch usize, buffer_slice_pitch usize, host_row_pitch usize, host_slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadBufferRect(command_queue, buffer, blocking_read, buffer_origin, host_origin, region, buffer_row_pitch, buffer_slice_pitch, host_row_pitch, host_slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_write_buffer_rect(command_queue CommandQueue, buffer Mem, blocking_write u32, buffer_origin &usize, host_origin &usize, region &usize, buffer_row_pitch usize, buffer_slice_pitch usize, host_row_pitch usize, host_slice_pitch usize, ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueWriteBufferRect(command_queue, buffer, blocking_write, buffer_origin, host_origin, region, buffer_row_pitch, buffer_slice_pitch, host_row_pitch, host_slice_pitch, ptr, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_copy_buffer_rect(command_queue CommandQueue, src_buffer Mem, dst_buffer Mem, src_origin &usize, dst_origin &usize, region &usize, src_row_pitch usize, src_slice_pitch usize, dst_row_pitch usize, dst_slice_pitch usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueCopyBufferRect(command_queue, src_buffer, dst_buffer, src_origin, dst_origin, region, src_row_pitch, src_slice_pitch, dst_row_pitch, dst_slice_pitch, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn create_sub_devices(in_device DeviceId, properties &isize, num_devices u32, out_devices &DeviceId, num_devices_ret &u32) ErrorCode {
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
pub fn create_image(context Context, flags u64, image_format &ImageFormat, image_desc &ImageDesc, host_ptr voidptr, errcode_ret &ErrorCode) Mem {
	return C.clCreateImage(context, flags, image_format, image_desc, host_ptr, errcode_ret)
}

@[inline]
pub fn create_program_with_built_in_kernels(context Context, num_devices u32, device_list &DeviceId, kernel_names &char, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithBuiltInKernels(context, num_devices, device_list, kernel_names, errcode_ret)
}

@[inline]
pub fn compile_program(program Program, num_devices u32, device_list &DeviceId, options &char, num_input_headers u32, input_headers &Program, header_include_names &&char, pfn_notify voidptr, user_data voidptr) ErrorCode {
	return C.clCompileProgram(program, num_devices, device_list, options, num_input_headers, input_headers, header_include_names, pfn_notify, user_data)
}

@[inline]
pub fn link_program(context Context, num_devices u32, device_list &DeviceId, options &char, num_input_programs u32, input_programs &Program, pfn_notify voidptr, user_data voidptr, errcode_ret &ErrorCode) Program {
	return C.clLinkProgram(context, num_devices, device_list, options, num_input_programs, input_programs, pfn_notify, user_data, errcode_ret)
}

@[inline]
pub fn unload_platform_compiler(platform PlatformId) ErrorCode {
	return C.clUnloadPlatformCompiler(platform)
}

@[inline]
pub fn get_kernel_arg_info(kernel Kernel, arg_index u32, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
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
pub fn enqueue_migrate_mem_objects(command_queue CommandQueue, num_mem_objects u32, mem_objects &Mem, flags u64, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
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
pub fn create_command_queue_with_properties(context Context, device DeviceId, properties &u64, errcode_ret &ErrorCode) CommandQueue {
	return C.clCreateCommandQueueWithProperties(context, device, properties, errcode_ret)
}

@[inline]
pub fn create_pipe(context Context, flags u64, pipe_packet_size u32, pipe_max_packets u32, properties &isize, errcode_ret &ErrorCode) Mem {
	return C.clCreatePipe(context, flags, pipe_packet_size, pipe_max_packets, properties, errcode_ret)
}

@[inline]
pub fn get_pipe_info(pipe Mem, param_name u32, param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetPipeInfo(pipe, param_name, param_value_size, param_value, param_value_size_ret)
}

@[inline]
pub fn svm_alloc(context Context, flags u64, size usize, alignment u32) voidptr {
	return C.clSVMAlloc(context, flags, size, alignment)
}

@[inline]
pub fn svm_free(context Context, svm_pointer voidptr) {
	C.clSVMFree(context, svm_pointer)
}

@[inline]
pub fn create_sampler_with_properties(context Context, sampler_properties &u64, errcode_ret &ErrorCode) Sampler {
	return C.clCreateSamplerWithProperties(context, sampler_properties, errcode_ret)
}

@[inline]
pub fn set_kernel_arg_svm_pointer(kernel Kernel, arg_index u32, arg_value voidptr) ErrorCode {
	return C.clSetKernelArgSVMPointer(kernel, arg_index, arg_value)
}

@[inline]
pub fn set_kernel_exec_info(kernel Kernel, param_name u32, param_value_size usize, param_value voidptr) ErrorCode {
	return C.clSetKernelExecInfo(kernel, param_name, param_value_size, param_value)
}

@[inline]
pub fn enqueue_svm_free(command_queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, pfn_free_func voidptr, user_data voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMFree(command_queue, num_svm_pointers, svm_pointers, pfn_free_func, user_data, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_memcpy(command_queue CommandQueue, blocking_copy u32, dst_ptr voidptr, src_ptr voidptr, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMemcpy(command_queue, blocking_copy, dst_ptr, src_ptr, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_mem_fill(command_queue CommandQueue, svm_ptr voidptr, pattern voidptr, pattern_size usize, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMemFill(command_queue, svm_ptr, pattern, pattern_size, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_map(command_queue CommandQueue, blocking_map u32, flags u64, svm_ptr voidptr, size usize, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMMap(command_queue, blocking_map, flags, svm_ptr, size, num_events_in_wait_list, event_wait_list, event)
}

@[inline]
pub fn enqueue_svm_unmap(command_queue CommandQueue, svm_ptr voidptr, num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueSVMUnmap(command_queue, svm_ptr, num_events_in_wait_list, event_wait_list, event)
}
