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

// Buffer owns a typed OpenCL buffer containing count elements of T.
pub struct Buffer[T] {
pub mut:
	handle Mem
pub:
	count int
}

// new_buffer allocates storage for count elements of T without a host pointer.
pub fn new_buffer[T](context &OwnedContext, flags MemFlags, count int) !Buffer[T] {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'create OpenCL buffer from closed context'
			status: invalid_context
		}
	}
	if count <= 0 {
		return OpenCLError{
			operation: 'create OpenCL buffer with non-positive element count'
			status: invalid_buffer_size
		}
	}
	mut status := success
	handle := create_buffer(context.handle, flags, usize(count) * sizeof(T), unsafe { nil }, &status)
	check(status, 'create OpenCL buffer')!
	if isnil(handle) {
		return OpenCLError{
			operation: 'create OpenCL buffer'
			status: mem_object_allocation_failure
		}
	}
	return Buffer[T]{
		handle: handle
		count: count
	}
}

// write copies a slice into the buffer and waits until the host data is reusable.
pub fn (buffer &Buffer[T]) write(queue &OwnedCommandQueue, offset int, values []T) ! {
	buffer.validate_transfer(queue, offset, values.len, 'write')!
	if values.len == 0 {
		return
	}
	check(enqueue_write_buffer(queue.handle, buffer.handle, blocking, usize(offset) * sizeof(T), usize(values.len) * sizeof(T), values.data, 0, unsafe { nil }, unsafe { nil }), 'write OpenCL buffer')!
}

// write_async enqueues a non-blocking copy and returns its completion event.
// values must remain allocated and unchanged until the returned event completes.
pub fn (buffer &Buffer[T]) write_async(queue &OwnedCommandQueue, offset int, values []T,
	wait_events []Event) !OwnedEvent {
	buffer.validate_transfer(queue, offset, values.len, 'write')!
	if values.len == 0 {
		return queue.marker(wait_events)
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(enqueue_write_buffer(queue.handle, buffer.handle, non_blocking, usize(offset) * sizeof(T), usize(values.len) * sizeof(T), values.data, u32(wait_events.len), wait_pointer, &event), 'write OpenCL buffer asynchronously')!
	return OwnedEvent{
		handle: event
	}
}

// read copies elements from the buffer and waits until the destination is populated.
pub fn (buffer &Buffer[T]) read(queue &OwnedCommandQueue, offset int, mut destination []T) ! {
	buffer.validate_transfer(queue, offset, destination.len, 'read')!
	if destination.len == 0 {
		return
	}
	check(enqueue_read_buffer(queue.handle, buffer.handle, blocking, usize(offset) * sizeof(T), usize(destination.len) * sizeof(T), destination.data, 0, unsafe { nil }, unsafe { nil }), 'read OpenCL buffer')!
}

// read_async enqueues a non-blocking copy and returns its completion event.
// destination must remain allocated and must not be read until the event completes.
pub fn (buffer &Buffer[T]) read_async(queue &OwnedCommandQueue, offset int, mut destination []T,
	wait_events []Event) !OwnedEvent {
	buffer.validate_transfer(queue, offset, destination.len, 'read')!
	if destination.len == 0 {
		return queue.marker(wait_events)
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(enqueue_read_buffer(queue.handle, buffer.handle, non_blocking, usize(offset) * sizeof(T), usize(destination.len) * sizeof(T), destination.data, u32(wait_events.len), wait_pointer, &event), 'read OpenCL buffer asynchronously')!
	return OwnedEvent{
		handle: event
	}
}

fn (buffer &Buffer[T]) validate_transfer(queue &OwnedCommandQueue, offset int, length int,
	operation string) ! {
	if isnil(buffer.handle) {
		return OpenCLError{
			operation: '${operation} closed OpenCL buffer'
			status: invalid_mem_object
		}
	}
	if isnil(queue.handle) {
		return OpenCLError{
			operation: '${operation} OpenCL buffer using closed queue'
			status: invalid_command_queue
		}
	}
	if offset < 0 || length < 0 || offset > buffer.count || length > buffer.count - offset {
		return OpenCLError{
			operation: '${operation} outside OpenCL buffer bounds'
			status: invalid_value
		}
	}
}

// close releases the owned memory-object reference. It is safe to call more than once.
pub fn (mut buffer Buffer[T]) close() ! {
	if isnil(buffer.handle) {
		return
	}
	check(release_mem_object(buffer.handle), 'release OpenCL buffer')!
	buffer.handle = unsafe { nil }
}
