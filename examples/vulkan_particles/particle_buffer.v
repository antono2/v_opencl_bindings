module main

import antono2.opencl as cl
import antono2.vulkan as vk

struct ParticleBuffer {
	handle    vk.Buffer
	memory    vk.DeviceMemory
	size      usize
	cl_buffer cl.Mem
	zero_copy bool
}

fn create_staged_particle_buffer(physical vk.PhysicalDevice, device vk.Device, particles []f32) !ParticleBuffer {
	size := usize(particles.len) * sizeof(f32)
	info := vk.BufferCreateInfo{ size: size, usage: u32(vk.BufferUsageFlagBits.vertex_buffer), sharingMode: .exclusive }
	mut buffer := vk.Buffer(unsafe { nil })
	vk_check(vk.create_buffer(device, &info, unsafe { nil }, &buffer), 'create particle vertex buffer')!
	mut requirements := vk.MemoryRequirements{}
	vk.get_buffer_memory_requirements(device, buffer, mut requirements)
	wanted := u32(vk.MemoryPropertyFlagBits.host_visible) | u32(vk.MemoryPropertyFlagBits.host_coherent)
	memory_type := find_memory_type_with_flags(physical, requirements.memoryTypeBits, wanted)!
	allocate := vk.MemoryAllocateInfo{ allocationSize: requirements.size, memoryTypeIndex: memory_type }
	mut memory := vk.DeviceMemory(unsafe { nil })
	vk_check(vk.allocate_memory(device, &allocate, unsafe { nil }, &memory), 'allocate particle vertex memory')!
	vk_check(vk.bind_buffer_memory(device, buffer, memory, 0), 'bind particle vertex memory')!
	mut mapped := voidptr(unsafe { nil })
	vk_check(vk.map_memory(device, memory, 0, size, 0, &mapped), 'map particle vertex memory')!
	unsafe { vmemcpy(mapped, particles.data, size) }
	vk.unmap_memory(device, memory)
	return ParticleBuffer{
		handle: buffer
		memory: memory
		size: size
	}
}

fn create_zero_copy_particle_buffer(compute &Compute, physical vk.PhysicalDevice, device vk.Device) !ParticleBuffer {
	size := compute.count * particle_stride
	external_info := vk.ExternalMemoryBufferCreateInfo{
		handleTypes: u32(vk.ExternalMemoryHandleTypeFlagBits.opaque_fd)
	}
	info := vk.BufferCreateInfo{
		pNext: &external_info
		size: size
		usage: u32(vk.BufferUsageFlagBits.vertex_buffer) | u32(vk.BufferUsageFlagBits.storage_buffer)
		sharingMode: .exclusive
	}
	mut buffer := vk.Buffer(unsafe { nil })
	vk_check(vk.create_buffer(device, &info, unsafe { nil }, &buffer), 'create shared particle buffer')!
	mut requirements := vk.MemoryRequirements{}
	vk.get_buffer_memory_requirements(device, buffer, mut requirements)
	memory_type := find_memory_type(physical, requirements.memoryTypeBits) or {
		vk.destroy_buffer(device, buffer, unsafe { nil })
		return err
	}
	export_info := vk.ExportMemoryAllocateInfo{
		handleTypes: u32(vk.ExternalMemoryHandleTypeFlagBits.opaque_fd)
	}
	allocate := vk.MemoryAllocateInfo{
		pNext: &export_info
		allocationSize: requirements.size
		memoryTypeIndex: memory_type
	}
	mut memory := vk.DeviceMemory(unsafe { nil })
	vk_check(vk.allocate_memory(device, &allocate, unsafe { nil }, &memory), 'allocate shared particle memory') or {
		vk.destroy_buffer(device, buffer, unsafe { nil })
		return err
	}
	vk_check(vk.bind_buffer_memory(device, buffer, memory, 0), 'bind shared particle memory') or {
		vk.free_memory(device, memory, unsafe { nil })
		vk.destroy_buffer(device, buffer, unsafe { nil })
		return err
	}
	fd_info := vk.MemoryGetFdInfoKHR{
		memory: memory
		handleType: .opaque_fd
	}
	mut fd := -1
	vk_check(vk.get_memory_fd_khr(device, &fd_info, &fd), 'export shared particle memory') or {
		vk.free_memory(device, memory, unsafe { nil })
		vk.destroy_buffer(device, buffer, unsafe { nil })
		return err
	}
	properties := [cl.MemProperties(cl.external_memory_handle_opaque_fd_khr), cl.MemProperties(fd),
		cl.MemProperties(0)]
	mut code := cl.success
	cl_buffer := cl.create_buffer_with_properties(compute.context, properties.data, cl.mem_read_write, size, unsafe { nil }, &code)
	cl_check(code, 'import live particle buffer into OpenCL') or {
		vk.free_memory(device, memory, unsafe { nil })
		vk.destroy_buffer(device, buffer, unsafe { nil })
		return err
	}
	return ParticleBuffer{
		handle: buffer
		memory: memory
		size: size
		cl_buffer: cl_buffer
		zero_copy: true
	}
}

fn (buffer &ParticleBuffer) upload(device vk.Device, particles []f32) ! {
	byte_count := usize(particles.len) * sizeof(f32)
	if byte_count > buffer.size {
		return error('particle upload exceeds vertex buffer')
	}
	mut mapped := voidptr(unsafe { nil })
	vk_check(vk.map_memory(device, buffer.memory, 0, byte_count, 0, &mapped), 'map particle upload')!
	unsafe { vmemcpy(mapped, particles.data, byte_count) }
	vk.unmap_memory(device, buffer.memory)
}

fn find_memory_type_with_flags(device vk.PhysicalDevice, allowed u32, wanted u32) !u32 {
	mut properties := vk.PhysicalDeviceMemoryProperties{}
	vk.get_physical_device_memory_properties(device, mut properties)
	for index in 0 .. properties.memoryTypeCount {
		if allowed & (u32(1) << index) != 0 && properties.memoryTypes[index].propertyFlags & wanted == wanted {
			return index
		}
	}
	return error('no host-visible coherent Vulkan memory type')
}

fn (buffer &ParticleBuffer) destroy(device vk.Device) {
	if buffer.zero_copy {
		cl.release_mem_object(buffer.cl_buffer)
	}
	vk.destroy_buffer(device, buffer.handle, unsafe { nil })
	vk.free_memory(device, buffer.memory, unsafe { nil })
}
