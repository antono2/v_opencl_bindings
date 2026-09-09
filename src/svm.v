module opencl

fn platform_svm_alloc(context Context, flags SvmMemFlags, size usize, alignment u32) voidptr {
	$if macos {
		return unsafe { nil }
	} $else {
		return svm_alloc(context, flags, size, alignment)
	}
}

fn platform_svm_free(context Context, pointer voidptr) {
	$if !macos {
		svm_free(context, pointer)
	}
}

fn platform_enqueue_svm_memcpy(queue CommandQueue, blocking_copy Bool, destination voidptr,
	source voidptr, size usize, wait_count u32, wait_events voidptr, event voidptr) ErrorCode {
	$if macos {
		return invalid_operation
	} $else {
		return enqueue_svm_memcpy(queue, blocking_copy, destination, source, size, wait_count,
			wait_events, event)
	}
}

fn platform_enqueue_svm_map(queue CommandQueue, blocking_map Bool, flags MapFlags,
	pointer voidptr, size usize, wait_count u32, wait_events voidptr, event voidptr) ErrorCode {
	$if macos {
		return invalid_operation
	} $else {
		return enqueue_svm_map(queue, blocking_map, flags, pointer, size, wait_count, wait_events,
			event)
	}
}

fn platform_enqueue_svm_unmap(queue CommandQueue, pointer voidptr, wait_count u32,
	wait_events voidptr, event voidptr) ErrorCode {
	$if macos {
		return invalid_operation
	} $else {
		return enqueue_svm_unmap(queue, pointer, wait_count, wait_events, event)
	}
}

fn platform_set_kernel_arg_svm_pointer(kernel Kernel, index u32, pointer voidptr) ErrorCode {
	$if macos {
		return invalid_operation
	} $else {
		return set_kernel_arg_svm_pointer(kernel, index, pointer)
	}
}

// SvmAllocation owns a typed OpenCL shared virtual memory allocation. T must
// be a plain C-layout value without V-managed references.
pub struct SvmAllocation[T] {
pub mut:
	handle voidptr
pub:
	count   int
	context Context
}

// device_svm_support returns the SVM capabilities advertised by a device.
pub fn device_svm_support(device DeviceId) !DeviceSvmCapabilities {
	if isnil(device) {
		return OpenCLError{
			operation: 'query SVM capabilities of null OpenCL device'
			status:    invalid_device
		}
	}
	mut capabilities := DeviceSvmCapabilities(0)
	status := get_device_info(device, device_svm_capabilities, sizeof(capabilities), &capabilities,
		unsafe { nil })
	if status == invalid_value || status == invalid_operation {
		return DeviceSvmCapabilities(0)
	}
	check(status, 'query OpenCL device SVM capabilities')!
	return capabilities
}

// new_svm allocates count elements of OpenCL shared virtual memory. flags accepts
// CL_MEM_* values, including mem_svm_fine_grain_buffer and mem_svm_atomics.
pub fn new_svm[T](context &OwnedContext, flags MemFlags, count int,
	alignment u32) !SvmAllocation[T] {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'allocate SVM from closed OpenCL context'
			status:    invalid_context
		}
	}
	if count <= 0 {
		return OpenCLError{
			operation: 'allocate SVM with non-positive element count'
			status:    invalid_buffer_size
		}
	}
	byte_size := checked_element_bytes[T](count, 'allocate SVM with overflowing element count')!
	if isnil(context.device) {
		return OpenCLError{
			operation: 'allocate SVM from context without a selected device'
			status:    invalid_device
		}
	}
	capabilities := device_svm_support(context.device)!
	if capabilities & (device_svm_coarse_grain_buffer | device_svm_fine_grain_buffer) == 0 {
		return OpenCLError{
			operation: 'allocate SVM on OpenCL device without buffer SVM support'
			status:    invalid_operation
		}
	}
	if flags & mem_svm_fine_grain_buffer != 0 && capabilities & device_svm_fine_grain_buffer == 0 {
		return OpenCLError{
			operation: 'request fine-grained SVM on unsupported OpenCL device'
			status:    invalid_value
		}
	}
	if flags & mem_svm_atomics != 0 && capabilities & device_svm_atomics == 0 {
		return OpenCLError{
			operation: 'request atomic SVM on unsupported OpenCL device'
			status:    invalid_value
		}
	}
	handle := platform_svm_alloc(context.handle, SvmMemFlags(flags), byte_size, alignment)
	if isnil(handle) {
		return OpenCLError{
			operation: 'allocate OpenCL SVM'
			status:    mem_object_allocation_failure
		}
	}
	return SvmAllocation[T]{
		handle:  handle
		count:   count
		context: context.handle
	}
}

fn (allocation &SvmAllocation[T]) validate_transfer(queue &OwnedCommandQueue, offset int,
	length int, operation string) !usize {
	if isnil(allocation.handle) {
		return OpenCLError{
			operation: '${operation} closed OpenCL SVM allocation'
			status:    invalid_value
		}
	}
	if isnil(queue.handle) {
		return OpenCLError{
			operation: '${operation} OpenCL SVM using closed queue'
			status:    invalid_command_queue
		}
	}
	if offset < 0 || length < 0 || offset > allocation.count || length > allocation.count - offset {
		return OpenCLError{
			operation: '${operation} outside OpenCL SVM bounds'
			status:    invalid_value
		}
	}
	return checked_element_bytes[T](length, '${operation} OpenCL SVM with overflowing length')!
}

fn (allocation &SvmAllocation[T]) pointer_at(offset int, operation string) !voidptr {
	byte_offset := checked_element_bytes[T](offset,
		'${operation} OpenCL SVM with overflowing offset')!
	return unsafe { voidptr(byteptr(allocation.handle) + byte_offset) }
}

// write copies values into SVM and blocks until values can be reused.
pub fn (allocation &SvmAllocation[T]) write(queue &OwnedCommandQueue, offset int,
	values []T) ! {
	byte_size := allocation.validate_transfer(queue, offset, values.len, 'write')!
	if values.len == 0 {
		return
	}
	destination := allocation.pointer_at(offset, 'write')!
	check(platform_enqueue_svm_memcpy(queue.handle, blocking, destination, values.data, byte_size,
		0, unsafe { nil }, unsafe { nil }), 'write OpenCL SVM')!
}

// write_async enqueues a copy into SVM. values must remain allocated and
// unchanged until the returned event completes.
pub fn (allocation &SvmAllocation[T]) write_async(queue &OwnedCommandQueue, offset int,
	values []T, wait_events []Event) !OwnedEvent {
	byte_size := allocation.validate_transfer(queue, offset, values.len, 'write')!
	if values.len == 0 {
		return queue.marker(wait_events)
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	destination := allocation.pointer_at(offset, 'write')!
	check(platform_enqueue_svm_memcpy(queue.handle, non_blocking, destination, values.data,
		byte_size, u32(wait_events.len), wait_pointer, &event), 'write OpenCL SVM asynchronously')!
	return OwnedEvent{
		handle: event
	}
}

// read copies elements from SVM and blocks until destination is populated.
pub fn (allocation &SvmAllocation[T]) read(queue &OwnedCommandQueue, offset int,
	mut destination []T) ! {
	byte_size := allocation.validate_transfer(queue, offset, destination.len, 'read')!
	if destination.len == 0 {
		return
	}
	source := allocation.pointer_at(offset, 'read')!
	check(platform_enqueue_svm_memcpy(queue.handle, blocking, destination.data, source, byte_size,
		0, unsafe { nil }, unsafe { nil }), 'read OpenCL SVM')!
}

// read_async enqueues a copy from SVM. destination must remain allocated and
// unread until the returned event completes.
pub fn (allocation &SvmAllocation[T]) read_async(queue &OwnedCommandQueue, offset int,
	mut destination []T, wait_events []Event) !OwnedEvent {
	byte_size := allocation.validate_transfer(queue, offset, destination.len, 'read')!
	if destination.len == 0 {
		return queue.marker(wait_events)
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	source := allocation.pointer_at(offset, 'read')!
	check(platform_enqueue_svm_memcpy(queue.handle, non_blocking, destination.data, source,
		byte_size, u32(wait_events.len), wait_pointer, &event), 'read OpenCL SVM asynchronously')!
	return OwnedEvent{
		handle: event
	}
}

// map blocks until a coarse-grained SVM allocation is host-accessible through handle.
pub fn (allocation &SvmAllocation[T]) map(queue &OwnedCommandQueue, flags MapFlags) ! {
	byte_size := allocation.validate_transfer(queue, 0, allocation.count, 'map')!
	check(platform_enqueue_svm_map(queue.handle, blocking, flags, allocation.handle, byte_size, 0,
		unsafe { nil }, unsafe { nil }), 'map OpenCL SVM')!
}

// unmap relinquishes host access and returns an event for the device-visible transition.
pub fn (allocation &SvmAllocation[T]) unmap(queue &OwnedCommandQueue,
	wait_events []Event) !OwnedEvent {
	allocation.validate_transfer(queue, 0, allocation.count, 'unmap')!
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(platform_enqueue_svm_unmap(queue.handle, allocation.handle, u32(wait_events.len),
		wait_pointer, &event), 'unmap OpenCL SVM')!
	return OwnedEvent{
		handle: event
	}
}

// set_kernel_arg binds this owned SVM allocation to a kernel argument.
pub fn (allocation &SvmAllocation[T]) set_kernel_arg(kernel &OwnedKernel, index u32) ! {
	if isnil(kernel.handle) {
		return OpenCLError{
			operation: 'set SVM argument on closed OpenCL kernel'
			status:    invalid_kernel
		}
	}
	if isnil(allocation.handle) {
		return OpenCLError{
			operation: 'bind closed OpenCL SVM allocation to kernel'
			status:    invalid_arg_value
		}
	}
	check(platform_set_kernel_arg_svm_pointer(kernel.handle, index, allocation.handle),
		'set OpenCL kernel SVM argument')!
}

// close frees the owned SVM allocation. All commands using it must have completed first.
pub fn (mut allocation SvmAllocation[T]) close() {
	if isnil(allocation.handle) {
		return
	}
	platform_svm_free(allocation.context, allocation.handle)
	allocation.handle = unsafe { nil }
}
