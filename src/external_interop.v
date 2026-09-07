module opencl

type ExternalMemoryCommand = fn (CommandQueue, u32, &Mem, u32, &Event, &Event) ErrorCode

type ExternalSemaphoreCommand = fn (CommandQueue, u32, &SemaphoreKhr, &SemaphorePayloadKhr, u32, &Event, &Event) ErrorCode

// ExternalMemoryInterop holds platform-specific cl_khr_external_memory entry
// points. Load it only after selecting the platform and device.
pub struct ExternalMemoryInterop {
	acquire_command ExternalMemoryCommand = unsafe { nil }
	release_command ExternalMemoryCommand = unsafe { nil }
}

// load_external_memory_interop validates opaque-FD support and resolves entry
// points for the selected platform rather than using the deprecated global lookup.
pub fn load_external_memory_interop(platform PlatformId, capabilities DeviceCapabilities) !ExternalMemoryInterop {
	if !capabilities.has_all(['cl_khr_external_memory', 'cl_khr_external_memory_opaque_fd']) {
		return OpenCLError{
			operation: 'load opaque-FD OpenCL external-memory interoperability'
			status: invalid_operation
		}
	}
	acquire_address := get_extension_function_address_for_platform(platform, c'clEnqueueAcquireExternalMemObjectsKHR')
	release_address := get_extension_function_address_for_platform(platform, c'clEnqueueReleaseExternalMemObjectsKHR')
	if isnil(acquire_address) || isnil(release_address) {
		return OpenCLError{
			operation: 'resolve OpenCL external-memory entry points'
			status: invalid_operation
		}
	}
	return ExternalMemoryInterop{
		acquire_command: unsafe { ExternalMemoryCommand(acquire_address) }
		release_command: unsafe { ExternalMemoryCommand(release_address) }
	}
}

// import_opaque_fd_buffer imports an externally allocated buffer. The caller
// remains responsible for the exporting API's handle-ownership requirements.
pub fn (interop ExternalMemoryInterop) import_opaque_fd_buffer[T](context &OwnedContext, fd int,
	count int, flags MemFlags) !Buffer[T] {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'import external buffer into closed OpenCL context'
			status: invalid_context
		}
	}
	if fd < 0 {
		return OpenCLError{
			operation: 'import OpenCL external buffer with invalid file descriptor'
			status: invalid_property
		}
	}
	if count <= 0 {
		return OpenCLError{
			operation: 'import OpenCL external buffer with non-positive element count'
			status: invalid_buffer_size
		}
	}
	properties := [MemProperties(external_memory_handle_opaque_fd_khr), MemProperties(fd),
		MemProperties(0)]
	mut status := success
	handle := create_buffer_with_properties(context.handle, properties.data, flags, usize(count) * sizeof(T), unsafe { nil }, &status)
	check(status, 'import opaque-FD OpenCL buffer')!
	return Buffer[T]{
		handle: handle
		count: count
	}
}

// acquire enqueues ownership acquisition for external memory objects.
pub fn (interop ExternalMemoryInterop) acquire(queue &OwnedCommandQueue, objects []Mem,
	wait_events []Event) !OwnedEvent {
	return interop.enqueue_memory_command(interop.acquire_command, queue, objects, wait_events, 'acquire OpenCL external memory')
}

// release enqueues ownership release for external memory objects.
pub fn (interop ExternalMemoryInterop) release(queue &OwnedCommandQueue, objects []Mem,
	wait_events []Event) !OwnedEvent {
	return interop.enqueue_memory_command(interop.release_command, queue, objects, wait_events, 'release OpenCL external memory')
}

fn (interop ExternalMemoryInterop) enqueue_memory_command(command ExternalMemoryCommand,
	queue &OwnedCommandQueue, objects []Mem, wait_events []Event, operation string) !OwnedEvent {
	if isnil(queue.handle) {
		return OpenCLError{
			operation: operation
			status: invalid_command_queue
		}
	}
	if objects.len == 0 {
		return OpenCLError{
			operation: operation
			status: invalid_value
		}
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(command(queue.handle, u32(objects.len), objects.data, u32(wait_events.len), wait_pointer, &event), operation)!
	return OwnedEvent{
		handle: event
	}
}

// ExternalSemaphoreInterop holds platform-specific opaque-FD semaphore entry points.
pub struct ExternalSemaphoreInterop {
	create_command  PFN_clCreateSemaphoreWithPropertiesKHR = unsafe { nil }
	wait_command    ExternalSemaphoreCommand = unsafe { nil }
	signal_command  ExternalSemaphoreCommand = unsafe { nil }
	release_command PFN_clReleaseSemaphoreKHR = unsafe { nil }
}

// load_external_semaphore_interop validates support and resolves entry points.
pub fn load_external_semaphore_interop(platform PlatformId,
	capabilities DeviceCapabilities) !ExternalSemaphoreInterop {
	if !capabilities.has_all(['cl_khr_semaphore', 'cl_khr_external_semaphore',
		'cl_khr_external_semaphore_opaque_fd']) {
		return OpenCLError{
			operation: 'load opaque-FD OpenCL external-semaphore interoperability'
			status: invalid_operation
		}
	}
	create_address := get_extension_function_address_for_platform(platform, c'clCreateSemaphoreWithPropertiesKHR')
	wait_address := get_extension_function_address_for_platform(platform, c'clEnqueueWaitSemaphoresKHR')
	signal_address := get_extension_function_address_for_platform(platform, c'clEnqueueSignalSemaphoresKHR')
	release_address := get_extension_function_address_for_platform(platform, c'clReleaseSemaphoreKHR')
	if isnil(create_address) || isnil(wait_address) || isnil(signal_address)
		|| isnil(release_address) {
		return OpenCLError{
			operation: 'resolve OpenCL external-semaphore entry points'
			status: invalid_operation
		}
	}
	return ExternalSemaphoreInterop{
		create_command: unsafe { PFN_clCreateSemaphoreWithPropertiesKHR(create_address) }
		wait_command: unsafe { ExternalSemaphoreCommand(wait_address) }
		signal_command: unsafe { ExternalSemaphoreCommand(signal_address) }
		release_command: unsafe { PFN_clReleaseSemaphoreKHR(release_address) }
	}
}

// OwnedExternalSemaphore owns one imported cl_semaphore_khr.
pub struct OwnedExternalSemaphore {
	interop ExternalSemaphoreInterop
pub mut:
	handle SemaphoreKhr
}

// import_opaque_fd imports a binary opaque-FD semaphore.
pub fn (interop ExternalSemaphoreInterop) import_opaque_fd(context &OwnedContext,
	fd int) !OwnedExternalSemaphore {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'import semaphore into closed OpenCL context'
			status: invalid_context
		}
	}
	if fd < 0 {
		return OpenCLError{
			operation: 'import OpenCL semaphore with invalid file descriptor'
			status: invalid_property
		}
	}
	properties := [SemaphorePropertiesKhr(semaphore_type_khr),
		SemaphorePropertiesKhr(semaphore_type_binary_khr),
		SemaphorePropertiesKhr(semaphore_handle_opaque_fd_khr), SemaphorePropertiesKhr(fd),
		SemaphorePropertiesKhr(0)]
	mut status := success
	handle := interop.create_command(context.handle, properties.data, &status)
	check(status, 'import opaque-FD OpenCL semaphore')!
	return OwnedExternalSemaphore{
		interop: interop
		handle: handle
	}
}

// wait enqueues a binary semaphore wait and returns its completion event.
pub fn (semaphore &OwnedExternalSemaphore) wait(queue &OwnedCommandQueue,
	wait_events []Event) !OwnedEvent {
	return semaphore.enqueue_semaphore_command(semaphore.interop.wait_command, queue, wait_events, 'wait for OpenCL external semaphore')
}

// signal enqueues a binary semaphore signal and returns its completion event.
pub fn (semaphore &OwnedExternalSemaphore) signal(queue &OwnedCommandQueue,
	wait_events []Event) !OwnedEvent {
	return semaphore.enqueue_semaphore_command(semaphore.interop.signal_command, queue, wait_events, 'signal OpenCL external semaphore')
}

fn (semaphore &OwnedExternalSemaphore) enqueue_semaphore_command(command ExternalSemaphoreCommand,
	queue &OwnedCommandQueue, wait_events []Event, operation string) !OwnedEvent {
	if isnil(semaphore.handle) {
		return OpenCLError{
			operation: operation
			status: invalid_semaphore_khr
		}
	}
	if isnil(queue.handle) {
		return OpenCLError{
			operation: operation
			status: invalid_command_queue
		}
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(command(queue.handle, 1, &semaphore.handle, unsafe { nil }, u32(wait_events.len), wait_pointer, &event), operation)!
	return OwnedEvent{
		handle: event
	}
}

// close releases the imported semaphore. It is safe to call more than once.
pub fn (mut semaphore OwnedExternalSemaphore) close() ! {
	if isnil(semaphore.handle) {
		return
	}
	check(semaphore.interop.release_command(semaphore.handle), 'release OpenCL external semaphore')!
	semaphore.handle = unsafe { nil }
}
