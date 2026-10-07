// Adapts Vulkan external-memory and semaphore file-descriptor output pointers to the C ABI.
module main

import antono2.vulkan as vk

// Vulkan v3.2.0 exposes POSIX file descriptors as i32. C int has the same
// ABI here but is a distinct V type, so cast the pointer at this boundary.
fn export_vk_memory_fd(device vk.Device, info &vk.MemoryGetFdInfoKHR, fd &int) vk.Result {
	return vk.get_memory_fd_khr(device, info, unsafe { &i32(fd) })
}

fn export_vk_semaphore_fd(device vk.Device, info &vk.SemaphoreGetFdInfoKHR, fd &int) vk.Result {
	return vk.get_semaphore_fd_khr(device, info, unsafe { &i32(fd) })
}
