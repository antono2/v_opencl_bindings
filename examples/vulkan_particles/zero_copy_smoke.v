module main

import antono2.opencl as cl
import vulkan as vk

fn C.volkLoadDevice(vk.Device)

type ExternalMemoryCommand = fn (cl.CommandQueue, u32, &cl.Mem, u32, &cl.Event, &cl.Event) cl.ErrorCode

type CreateBufferWithPropertiesCommand = fn (cl.Context, &u64, u64, usize, voidptr, &cl.ErrorCode) cl.Mem

type CreateSemaphoreCommand = fn (cl.Context, &u64, &cl.ErrorCode) cl.SemaphoreKhr

type EnqueueSemaphoreCommand = fn (cl.CommandQueue, u32, &cl.SemaphoreKhr, &u64, u32, &cl.Event, &cl.Event) cl.ErrorCode

type ReleaseSemaphoreCommand = fn (cl.SemaphoreKhr) cl.ErrorCode

// Exercises the external allocation before the window and render loop are involved.
// This function is intentionally hardware-gated by probe_interop.
fn zero_copy_memory_smoke(compute &Compute) ! {
	cl_extensions := cl_info_string(compute.device, cl.device_extensions)
	cl_uuid, has_uuid := opencl_uuid(compute.device, cl_extensions)
	if !has_uuid {
		return error('OpenCL UUID unavailable')
	}
	if C.particles_volk_initialize() != vk.Result.success {
		return error('initialize Vulkan loader')
	}
	mut instance := vk.Instance(unsafe { nil })
	app_info := vk.ApplicationInfo{
		pApplicationName: c'V OpenCL zero-copy smoke'
		apiVersion: vk.api_version_1_1
	}
	instance_info := vk.InstanceCreateInfo{ pApplicationInfo: &app_info }
	vk_check(vk.create_instance(&instance_info, unsafe { nil }, &instance), 'create instance')!
	defer { vk.destroy_instance(instance, unsafe { nil }) }
	C.volkLoadInstance(instance)

	physical := find_vulkan_device_by_uuid(instance, cl_uuid)!
	queue_family := first_queue_family(physical)!
	priority := f32(1)
	queue_info := vk.DeviceQueueCreateInfo{
		queueFamilyIndex: queue_family
		queueCount: 1
		pQueuePriorities: &priority
	}
	extensions := [vk.khr_external_memory_extension_name, vk.khr_external_memory_fd_extension_name,
		vk.khr_external_semaphore_extension_name, vk.khr_external_semaphore_fd_extension_name]
	device_info := vk.DeviceCreateInfo{
		queueCreateInfoCount: 1
		pQueueCreateInfos: &queue_info
		enabledExtensionCount: u32(extensions.len)
		ppEnabledExtensionNames: extensions.data
	}
	mut device := vk.Device(unsafe { nil })
	vk_check(vk.create_device(physical, &device_info, unsafe { nil }, &device), 'create device')!
	defer { vk.destroy_device(device, unsafe { nil }) }
	C.volkLoadDevice(device)
	mut queue := vk.Queue(unsafe { nil })
	vk.get_device_queue(device, queue_family, 0, &queue)

	external_info := vk.ExternalMemoryBufferCreateInfo{
		handleTypes: u32(vk.ExternalMemoryHandleTypeFlagBits.opaque_fd)
	}
	buffer_info := vk.BufferCreateInfo{
		pNext: &external_info
		size: compute.count * particle_stride
		usage: u32(vk.BufferUsageFlagBits.vertex_buffer) | u32(vk.BufferUsageFlagBits.storage_buffer)
		sharingMode: .exclusive
	}
	mut buffer := vk.Buffer(unsafe { nil })
	vk_check(vk.create_buffer(device, &buffer_info, unsafe { nil }, &buffer), 'create exportable buffer')!
	defer { vk.destroy_buffer(device, buffer, unsafe { nil }) }
	mut requirements := vk.MemoryRequirements{}
	vk.get_buffer_memory_requirements(device, buffer, mut requirements)
	memory_type := find_memory_type(physical, requirements.memoryTypeBits)!
	export_info := vk.ExportMemoryAllocateInfo{
		handleTypes: u32(vk.ExternalMemoryHandleTypeFlagBits.opaque_fd)
	}
	allocation_info := vk.MemoryAllocateInfo{
		pNext: &export_info
		allocationSize: requirements.size
		memoryTypeIndex: memory_type
	}
	mut memory := vk.DeviceMemory(unsafe { nil })
	vk_check(vk.allocate_memory(device, &allocation_info, unsafe { nil }, &memory), 'allocate exportable memory')!
	defer { vk.free_memory(device, memory, unsafe { nil }) }
	vk_check(vk.bind_buffer_memory(device, buffer, memory, 0), 'bind exportable buffer')!
	fd_info := vk.MemoryGetFdInfoKHR{
		memory: memory
		handleType: .opaque_fd
	}
	mut fd := -1
	vk_check(vk.get_memory_fd_khr(device, &fd_info, &fd), 'export memory FD')!

	properties := [u64(cl.external_memory_handle_opaque_fd_khr), u64(fd), u64(0)]
	mut code := cl.success
	create_buffer := load_create_buffer_with_properties_command(compute.platform)!
	imported_buffer := create_buffer(compute.context, properties.data, cl.mem_read_write, compute.count * particle_stride, unsafe { nil }, &code)
	cl_check(code, 'import Vulkan memory into OpenCL')!
	defer { cl.release_mem_object(imported_buffer) }
	acquire := load_external_memory_command(compute.platform, c'clEnqueueAcquireExternalMemObjectsKHR')!
	release := load_external_memory_command(compute.platform, c'clEnqueueReleaseExternalMemObjectsKHR')!
	cl_check(acquire(compute.queue, 1, &imported_buffer, 0, unsafe { nil }, unsafe { nil }), 'acquire external particle buffer')!
	seed := u32(7)
	cl_check(cl.set_kernel_arg(compute.reset, 0, sizeof(cl.Mem), &imported_buffer), 'set shared particle buffer')!
	cl_check(cl.set_kernel_arg(compute.reset, 1, sizeof(u32), &seed), 'set shared reset seed')!
	cl_check(cl.enqueue_nd_range_kernel(compute.queue, compute.reset, 1, unsafe { nil }, &compute.count, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'write shared particle buffer')!
	mut sample := []f32{len: 8}
	cl_check(cl.enqueue_read_buffer(compute.queue, imported_buffer, cl._true, 0, particle_stride, sample.data, 0, unsafe { nil }, unsafe { nil }), 'verify shared particle buffer')!
	cl_check(release(compute.queue, 1, &imported_buffer, 0, unsafe { nil }, unsafe { nil }), 'release external particle buffer')!
	cl_check(cl.finish(compute.queue), 'finish zero-copy smoke')!
	println('Zero-copy memory smoke: first particle = (${sample[0]:.3f}, ${sample[1]:.3f})')
	zero_copy_semaphore_smoke(compute, device, queue)!
}

fn zero_copy_semaphore_smoke(compute &Compute, device vk.Device, queue vk.Queue) ! {
	export_info := vk.ExportSemaphoreCreateInfo{
		handleTypes: u32(vk.ExternalSemaphoreHandleTypeFlagBits.opaque_fd)
	}
	semaphore_info := vk.SemaphoreCreateInfo{ pNext: &export_info }
	mut vk_to_cl := vk.Semaphore(unsafe { nil })
	mut cl_to_vk := vk.Semaphore(unsafe { nil })
	vk_check(vk.create_semaphore(device, &semaphore_info, unsafe { nil }, &vk_to_cl), 'create Vulkan-to-OpenCL semaphore')!
	defer { vk.destroy_semaphore(device, vk_to_cl, unsafe { nil }) }
	vk_check(vk.create_semaphore(device, &semaphore_info, unsafe { nil }, &cl_to_vk), 'create OpenCL-to-Vulkan semaphore')!
	defer { vk.destroy_semaphore(device, cl_to_vk, unsafe { nil }) }

	mut vk_to_cl_fd := -1
	mut cl_to_vk_fd := -1
	vk_to_cl_fd_info := vk.SemaphoreGetFdInfoKHR{
		semaphore: vk_to_cl
		handleType: .opaque_fd
	}
	cl_to_vk_fd_info := vk.SemaphoreGetFdInfoKHR{
		semaphore: cl_to_vk
		handleType: .opaque_fd
	}
	vk_check(vk.get_semaphore_fd_khr(device, &vk_to_cl_fd_info, &vk_to_cl_fd), 'export Vulkan-to-OpenCL semaphore FD')!
	vk_check(vk.get_semaphore_fd_khr(device, &cl_to_vk_fd_info, &cl_to_vk_fd), 'export OpenCL-to-Vulkan semaphore FD')!

	create := load_create_semaphore_command(compute.platform)!
	wait := load_enqueue_semaphore_command(compute.platform, c'clEnqueueWaitSemaphoresKHR')!
	signal := load_enqueue_semaphore_command(compute.platform, c'clEnqueueSignalSemaphoresKHR')!
	release := load_release_semaphore_command(compute.platform)!
	vk_to_cl_properties := [u64(cl.semaphore_type_khr), u64(cl.semaphore_type_binary_khr),
		u64(cl.semaphore_handle_opaque_fd_khr), u64(vk_to_cl_fd), u64(0)]
	cl_to_vk_properties := [u64(cl.semaphore_type_khr), u64(cl.semaphore_type_binary_khr),
		u64(cl.semaphore_handle_opaque_fd_khr), u64(cl_to_vk_fd), u64(0)]
	mut code := cl.success
	cl_wait := create(compute.context, vk_to_cl_properties.data, &code)
	cl_check(code, 'import Vulkan-to-OpenCL semaphore')!
	defer { release(cl_wait) }
	cl_signal := create(compute.context, cl_to_vk_properties.data, &code)
	cl_check(code, 'import OpenCL-to-Vulkan semaphore')!
	defer { release(cl_signal) }

	vk_signal_submit := vk.SubmitInfo{
		signalSemaphoreCount: 1
		pSignalSemaphores: &vk_to_cl
	}
	vk_check(vk.queue_submit(queue, 1, &vk_signal_submit, unsafe { nil }), 'signal Vulkan-to-OpenCL semaphore')!
	cl_check(wait(compute.queue, 1, &cl_wait, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'wait for Vulkan in OpenCL')!
	cl_check(signal(compute.queue, 1, &cl_signal, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'signal OpenCL-to-Vulkan semaphore')!

	stage := vk.PipelineStageFlags(vk.PipelineStageFlagBits.all_commands)
	vk_wait_submit := vk.SubmitInfo{
		waitSemaphoreCount: 1
		pWaitSemaphores: &cl_to_vk
		pWaitDstStageMask: &stage
	}
	mut fence := vk.Fence(unsafe { nil })
	fence_info := vk.FenceCreateInfo{}
	vk_check(vk.create_fence(device, &fence_info, unsafe { nil }, &fence), 'create handshake fence')!
	defer { vk.destroy_fence(device, fence, unsafe { nil }) }
	vk_check(vk.queue_submit(queue, 1, &vk_wait_submit, fence), 'wait for OpenCL in Vulkan')!
	vk_check(vk.wait_for_fences(device, 1, &fence, vk._true, max_u64), 'finish external semaphore handshake')!
	println('Zero-copy semaphore smoke: Vulkan -> OpenCL -> Vulkan handshake passed')
}

fn load_external_memory_command(platform cl.PlatformId, name &char) !ExternalMemoryCommand {
	address := cl.get_extension_function_address_for_platform(platform, name)
	if isnil(address) {
		return error('OpenCL extension command ${unsafe { name.vstring() }} is unavailable')
	}
	return ExternalMemoryCommand(address)
}

fn load_create_buffer_with_properties_command(platform cl.PlatformId) !CreateBufferWithPropertiesCommand {
	address := cl.get_extension_function_address_for_platform(platform, c'clCreateBufferWithProperties')
	if isnil(address) {
		return error('clCreateBufferWithProperties is unavailable')
	}
	return CreateBufferWithPropertiesCommand(address)
}

fn load_create_semaphore_command(platform cl.PlatformId) !CreateSemaphoreCommand {
	address := cl.get_extension_function_address_for_platform(platform, c'clCreateSemaphoreWithPropertiesKHR')
	if isnil(address) {
		return error('clCreateSemaphoreWithPropertiesKHR is unavailable')
	}
	return CreateSemaphoreCommand(address)
}

fn load_enqueue_semaphore_command(platform cl.PlatformId, name &char) !EnqueueSemaphoreCommand {
	address := cl.get_extension_function_address_for_platform(platform, name)
	if isnil(address) {
		return error('${unsafe { name.vstring() }} is unavailable')
	}
	return EnqueueSemaphoreCommand(address)
}

fn load_release_semaphore_command(platform cl.PlatformId) !ReleaseSemaphoreCommand {
	address := cl.get_extension_function_address_for_platform(platform, c'clReleaseSemaphoreKHR')
	if isnil(address) {
		return error('clReleaseSemaphoreKHR is unavailable')
	}
	return ReleaseSemaphoreCommand(address)
}

fn find_vulkan_device_by_uuid(instance vk.Instance, wanted [16]u8) !vk.PhysicalDevice {
	mut count := u32(0)
	vk_check(vk.enumerate_physical_devices(instance, &count, unsafe { nil }), 'count devices')!
	mut devices := unsafe { []vk.PhysicalDevice{len: int(count)} }
	vk_check(vk.enumerate_physical_devices(instance, &count, devices.data), 'enumerate devices')!
	for device in devices {
		mut id := vk.PhysicalDeviceIDProperties{}
		mut properties := vk.PhysicalDeviceProperties2{ pNext: &id }
		vk.get_physical_device_properties2(device, mut properties)
		if uuid_equal(wanted, &id.deviceUUID[0]) {
			return device
		}
	}
	return error('no UUID-matched Vulkan device')
}

fn first_queue_family(device vk.PhysicalDevice) !u32 {
	mut count := u32(0)
	mut queue_family_properties := unsafe { nil }
	vk.get_physical_device_queue_family_properties(device, &count, mut queue_family_properties)
	if count == 0 {
		return error('device has no queue families')
	}
	return 0
}

fn find_memory_type(device vk.PhysicalDevice, allowed u32) !u32 {
	mut properties := vk.PhysicalDeviceMemoryProperties{}
	vk.get_physical_device_memory_properties(device, mut properties)
	for index in 0 .. properties.memoryTypeCount {
		if allowed & (u32(1) << index) != 0 {
			return index
		}
	}
	return error('no compatible Vulkan memory type')
}

fn vk_check(result vk.Result, operation string) ! {
	if result != .success {
		return error('${operation} failed with Vulkan result ${result}')
	}
}
