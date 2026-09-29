module main

import antono2.vulkan as vk

// Vulkan registry revisions have described POSIX file descriptors as both
// C int and int32_t. These pointer types have the same ABI but distinct V
// types. Select the matching raw declaration in the dependency-master lane.
fn export_vk_memory_fd(device vk.Device, info &vk.MemoryGetFdInfoKHR, fd &int) vk.Result {
	$if vulkan_fd_i32 ? {
		return vk.get_memory_fd_khr(device, info, unsafe { &i32(fd) })
	} $else {
		return vk.get_memory_fd_khr(device, info, fd)
	}
}

fn export_vk_semaphore_fd(device vk.Device, info &vk.SemaphoreGetFdInfoKHR, fd &int) vk.Result {
	$if vulkan_fd_i32 ? {
		return vk.get_semaphore_fd_khr(device, info, unsafe { &i32(fd) })
	} $else {
		return vk.get_semaphore_fd_khr(device, info, fd)
	}
}
