module opencl

// OwnedContext owns one reference to an OpenCL context. Call close when done.
pub struct OwnedContext {
pub mut:
	handle Context
}

// new_context creates a context containing exactly one explicitly selected device.
pub fn new_context(device DeviceId) !OwnedContext {
	mut status := success
	handle := create_context(unsafe { nil }, 1, &device, unsafe { nil }, unsafe { nil }, &status)
	check(status, 'create OpenCL context')!
	if isnil(handle) {
		return OpenCLError{
			operation: 'create OpenCL context'
			status: out_of_host_memory
		}
	}
	return OwnedContext{
		handle: handle
	}
}

// command_queue creates a legacy-compatible command queue for a device in this context.
// The properties argument accepts flags such as queue_profiling_enable.
pub fn (context &OwnedContext) command_queue(device DeviceId,
	properties CommandQueueProperties) !OwnedCommandQueue {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'create OpenCL command queue from closed context'
			status: invalid_context
		}
	}
	mut status := success
	handle := create_command_queue(context.handle, device, properties, &status)
	check(status, 'create OpenCL command queue')!
	if isnil(handle) {
		return OpenCLError{
			operation: 'create OpenCL command queue'
			status: out_of_host_memory
		}
	}
	return OwnedCommandQueue{
		handle: handle
	}
}

// close releases the owned context reference. It is safe to call more than once.
// All queues and memory objects associated with the context should be closed first.
pub fn (mut context OwnedContext) close() ! {
	if isnil(context.handle) {
		return
	}
	check(release_context(context.handle), 'release OpenCL context')!
	context.handle = unsafe { nil }
}

// OwnedCommandQueue owns one reference to an OpenCL command queue. Call close when done.
pub struct OwnedCommandQueue {
pub mut:
	handle CommandQueue
}

// close releases the owned queue reference. It is safe to call more than once.
pub fn (mut queue OwnedCommandQueue) close() ! {
	if isnil(queue.handle) {
		return
	}
	check(release_command_queue(queue.handle), 'release OpenCL command queue')!
	queue.handle = unsafe { nil }
}
