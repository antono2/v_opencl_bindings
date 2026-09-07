module main

import antono2.opencl as cl
import antono2.vulkan as vk

struct LiveInteropSync {
	vk_to_cl  vk.Semaphore
	cl_to_vk  vk.Semaphore
	cl_wait   cl.SemaphoreKhr
	cl_signal cl.SemaphoreKhr
	wait      EnqueueSemaphoreCommand = unsafe { nil }
	signal    EnqueueSemaphoreCommand = unsafe { nil }
	release   ReleaseSemaphoreCommand = unsafe { nil }
}

fn create_live_interop_sync(compute &Compute, device vk.Device, queue vk.Queue) !LiveInteropSync {
	export_info := vk.ExportSemaphoreCreateInfo{
		handleTypes: u32(vk.ExternalSemaphoreHandleTypeFlagBits.opaque_fd)
	}
	info := vk.SemaphoreCreateInfo{ pNext: &export_info }
	mut vk_to_cl := vk.Semaphore(unsafe { nil })
	mut cl_to_vk := vk.Semaphore(unsafe { nil })
	vk_check(vk.create_semaphore(device, &info, unsafe { nil }, &vk_to_cl), 'create live Vulkan-to-OpenCL semaphore')!
	vk_check(vk.create_semaphore(device, &info, unsafe { nil }, &cl_to_vk), 'create live OpenCL-to-Vulkan semaphore') or {
		vk.destroy_semaphore(device, vk_to_cl, unsafe { nil })
		return err
	}

	mut vk_to_cl_fd := -1
	mut cl_to_vk_fd := -1
	vk_wait_fd_info := vk.SemaphoreGetFdInfoKHR{
		semaphore: vk_to_cl
		handleType: .opaque_fd
	}
	cl_signal_fd_info := vk.SemaphoreGetFdInfoKHR{
		semaphore: cl_to_vk
		handleType: .opaque_fd
	}
	vk_check(vk.get_semaphore_fd_khr(device, &vk_wait_fd_info, &vk_to_cl_fd), 'export live Vulkan-to-OpenCL semaphore')!
	vk_check(vk.get_semaphore_fd_khr(device, &cl_signal_fd_info, &cl_to_vk_fd), 'export live OpenCL-to-Vulkan semaphore')!

	create := load_create_semaphore_command(compute.platform)!
	wait := load_enqueue_semaphore_command(compute.platform, c'clEnqueueWaitSemaphoresKHR')!
	signal := load_enqueue_semaphore_command(compute.platform, c'clEnqueueSignalSemaphoresKHR')!
	release := load_release_semaphore_command(compute.platform)!
	wait_properties := [u64(cl.semaphore_type_khr), u64(cl.semaphore_type_binary_khr),
		u64(cl.semaphore_handle_opaque_fd_khr), u64(vk_to_cl_fd), u64(0)]
	signal_properties := [u64(cl.semaphore_type_khr), u64(cl.semaphore_type_binary_khr),
		u64(cl.semaphore_handle_opaque_fd_khr), u64(cl_to_vk_fd), u64(0)]
	mut code := cl.success
	cl_wait := create(compute.context, wait_properties.data, &code)
	cl_check(code, 'import live Vulkan-to-OpenCL semaphore')!
	cl_signal := create(compute.context, signal_properties.data, &code)
	cl_check(code, 'import live OpenCL-to-Vulkan semaphore') or {
		release(cl_wait)
		return err
	}

	// There is no preceding render for frame zero, so seed the binary handshake once.
	prime := vk.SubmitInfo{
		signalSemaphoreCount: 1
		pSignalSemaphores: &vk_to_cl
	}
	vk_check(vk.queue_submit(queue, 1, &prime, unsafe { nil }), 'prime live interop semaphore')!
	return LiveInteropSync{vk_to_cl, cl_to_vk, cl_wait, cl_signal, wait, signal, release}
}

fn (sync &LiveInteropSync) begin_compute(compute &Compute, buffer cl.Mem,
	acquire ExternalMemoryCommand) ! {
	cl_check(sync.wait(compute.queue, 1, &sync.cl_wait, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'wait for Vulkan particle read')!
	cl_check(acquire(compute.queue, 1, &buffer, 0, unsafe { nil }, unsafe { nil }), 'acquire live particle buffer')!
}

fn (sync &LiveInteropSync) end_compute(compute &Compute, buffer cl.Mem,
	release_memory ExternalMemoryCommand) ! {
	cl_check(release_memory(compute.queue, 1, &buffer, 0, unsafe { nil }, unsafe { nil }), 'release live particle buffer')!
	cl_check(sync.signal(compute.queue, 1, &sync.cl_signal, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'signal Vulkan particle render')!
}

fn (sync &LiveInteropSync) destroy(device vk.Device) {
	sync.release(sync.cl_signal)
	sync.release(sync.cl_wait)
	vk.destroy_semaphore(device, sync.cl_to_vk, unsafe { nil })
	vk.destroy_semaphore(device, sync.vk_to_cl, unsafe { nil })
}
