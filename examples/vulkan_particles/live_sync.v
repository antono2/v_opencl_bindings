module main

import antono2.opencl as cl
import antono2.vulkan as vk

struct LiveInteropSync {
	vk_to_cl vk.Semaphore
	cl_to_vk vk.Semaphore
	memory   cl.ExternalMemoryInterop
mut:
	cl_wait   cl.OwnedExternalSemaphore
	cl_signal cl.OwnedExternalSemaphore
}

fn create_live_interop_sync(compute &Compute, memory cl.ExternalMemoryInterop,
	semaphores cl.ExternalSemaphoreInterop, device vk.Device, queue vk.Queue) !LiveInteropSync {
	mut export_info := vk.ExportSemaphoreCreateInfo{
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

	mut cl_wait := semaphores.import_opaque_fd(&compute.context, vk_to_cl_fd)!
	cl_signal := semaphores.import_opaque_fd(&compute.context, cl_to_vk_fd) or {
		cl_wait.close() or {}
		return err
	}

	// There is no preceding render for frame zero, so seed the binary handshake once.
	prime := vk.SubmitInfo{
		signalSemaphoreCount: 1
		pSignalSemaphores: &vk_to_cl
	}
	vk_check(vk.queue_submit(queue, 1, &prime, unsafe { nil }), 'prime live interop semaphore')!
	return LiveInteropSync{
		vk_to_cl: vk_to_cl
		cl_to_vk: cl_to_vk
		memory: memory
		cl_wait: cl_wait
		cl_signal: cl_signal
	}
}

fn (sync &LiveInteropSync) begin_compute(compute &Compute, buffer cl.Mem) ! {
	mut wait_event := sync.cl_wait.wait(&compute.queue, [])!
	mut acquire_event := sync.memory.acquire(&compute.queue, [buffer], [
		wait_event.handle,
	])!
	acquire_event.close()!
	wait_event.close()!
}

fn (sync &LiveInteropSync) end_compute(compute &Compute, buffer cl.Mem) ! {
	mut release_event := sync.memory.release(&compute.queue, [buffer], [])!
	mut signal_event := sync.cl_signal.signal(&compute.queue, [release_event.handle])!
	signal_event.close()!
	release_event.close()!
}

fn (mut sync LiveInteropSync) destroy(device vk.Device) {
	sync.cl_signal.close() or {}
	sync.cl_wait.close() or {}
	vk.destroy_semaphore(device, sync.cl_to_vk, unsafe { nil })
	vk.destroy_semaphore(device, sync.vk_to_cl, unsafe { nil })
}
