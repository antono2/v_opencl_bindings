module opencl

// OwnedEvent owns one OpenCL event reference. The command queue and context
// which created it must remain valid until the event has completed.
pub struct OwnedEvent {
pub mut:
	handle Event
}

// wait blocks until this event reaches a terminal execution state.
pub fn (event &OwnedEvent) wait() ! {
	if isnil(event.handle) {
		return OpenCLError{
			operation: 'wait for closed OpenCL event'
			status: invalid_event
		}
	}
	check(wait_for_events(1, &event.handle), 'wait for OpenCL event')!
}

// execution_status returns CL_QUEUED, CL_SUBMITTED, CL_RUNNING, CL_COMPLETE,
// or a negative command execution error code.
pub fn (event &OwnedEvent) execution_status() !i32 {
	if isnil(event.handle) {
		return OpenCLError{
			operation: 'query closed OpenCL event'
			status: invalid_event
		}
	}
	mut status := i32(0)
	check(get_event_info(event.handle, event_command_execution_status, sizeof(status), &status, unsafe { nil }), 'query OpenCL event execution status')!
	return status
}

// close releases the owned event reference. It is safe to call more than once.
pub fn (mut event OwnedEvent) close() ! {
	if isnil(event.handle) {
		return
	}
	check(release_event(event.handle), 'release OpenCL event')!
	event.handle = unsafe { nil }
}

// marker enqueues a marker after every event in wait_events and returns its
// completion event. An empty wait list depends on earlier commands in queue.
pub fn (queue &OwnedCommandQueue) marker(wait_events []Event) !OwnedEvent {
	if isnil(queue.handle) {
		return OpenCLError{
			operation: 'enqueue marker on closed OpenCL queue'
			status: invalid_command_queue
		}
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut handle := Event(unsafe { nil })
	check(enqueue_marker_with_wait_list(queue.handle, u32(wait_events.len), wait_pointer, &handle), 'enqueue OpenCL marker')!
	return OwnedEvent{
		handle: handle
	}
}

// barrier enqueues a barrier after every event in wait_events and returns its
// completion event.
pub fn (queue &OwnedCommandQueue) barrier(wait_events []Event) !OwnedEvent {
	if isnil(queue.handle) {
		return OpenCLError{
			operation: 'enqueue barrier on closed OpenCL queue'
			status: invalid_command_queue
		}
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut handle := Event(unsafe { nil })
	check(enqueue_barrier_with_wait_list(queue.handle, u32(wait_events.len), wait_pointer, &handle), 'enqueue OpenCL barrier')!
	return OwnedEvent{
		handle: handle
	}
}
