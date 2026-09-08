module main

import antono2.opencl as cl

#flag -I @VMODROOT

#include "pointer_abi_shim.c"

fn C.opencl_pointer_shim_reset()

fn C.opencl_pointer_shim_expect_platform_array(voidptr)

fn C.opencl_pointer_shim_blocking_write_calls() int

fn C.opencl_pointer_shim_blocking_read_calls() int

fn C.opencl_pointer_shim_kernel_enqueue_calls() int

fn test_zero_count_and_slice_handle_arrays_reach_c_unchanged() {
	C.opencl_pointer_shim_reset()
	mut count := u32(0)
	assert cl.get_platform_ids(0, unsafe { nil }, &count) == cl.success
	assert count == 2

	mut platforms := unsafe { []cl.PlatformId{len: int(count)} }
	C.opencl_pointer_shim_expect_platform_array(platforms.data)
	assert cl.get_platform_ids(count, platforms.data, &count) == cl.success
	assert !isnil(platforms[0])
	assert !isnil(platforms[1])
	assert platforms[0] != platforms[1]
}

fn test_blocking_transfers_pass_null_event_pointers() ! {
	C.opencl_pointer_shim_reset()
	mut queue_storage := u8(0)
	mut buffer_storage := u8(0)
	queue := cl.OwnedCommandQueue{
		handle: cl.CommandQueue(&queue_storage)
	}
	buffer := cl.Buffer[u32]{
		handle: cl.Mem(&buffer_storage)
		count: 2
	}
	values := [u32(3), 5]
	buffer.write(&queue, 0, values)!
	mut destination := []u32{len: 2}
	buffer.read(&queue, 0, mut destination)!
	assert C.opencl_pointer_shim_blocking_write_calls() == 1
	assert C.opencl_pointer_shim_blocking_read_calls() == 1
}

fn test_kernel_enqueue_passes_null_offset_and_event_pointers() ! {
	C.opencl_pointer_shim_reset()
	mut queue_storage := u8(0)
	mut kernel_storage := u8(0)
	queue := cl.OwnedCommandQueue{
		handle: cl.CommandQueue(&queue_storage)
	}
	kernel := cl.OwnedKernel{
		handle: cl.Kernel(&kernel_storage)
	}
	kernel.enqueue_1d(&queue, 64, 0)!
	assert C.opencl_pointer_shim_kernel_enqueue_calls() == 1
}
