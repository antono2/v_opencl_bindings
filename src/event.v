module opencl

// OwnedEvent owns one OpenCL event reference. The command queue and context
// which created it must remain valid until the event has completed.
pub struct OwnedEvent {
pub mut:
	handle Event
}

// EventProfile contains device timestamps in nanoseconds. Values are valid for
// commands from queues created with queue_profiling_enable.
pub struct EventProfile {
pub:
	queued u64
	submit u64
	start  u64
	end    u64
}

// duration returns device execution time in nanoseconds.
pub fn (profile EventProfile) duration() u64 {
	return profile.end - profile.start
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

// profiling_timestamp reads one OpenCL profiling timestamp.
pub fn (event &OwnedEvent) profiling_timestamp(parameter ProfilingInfo) !u64 {
	if isnil(event.handle) {
		return OpenCLError{
			operation: 'profile closed OpenCL event'
			status: invalid_event
		}
	}
	mut timestamp := u64(0)
	check(get_event_profiling_info(event.handle, parameter, sizeof(timestamp), &timestamp, unsafe { nil }), 'query OpenCL event profiling timestamp')!
	return timestamp
}

// profile waits for completion and returns the portable queued, submit, start,
// and end timestamps. It returns profiling_info_not_available for queues which
// were not created with queue_profiling_enable.
pub fn (event &OwnedEvent) profile() !EventProfile {
	event.wait()!
	return EventProfile{
		queued: event.profiling_timestamp(profiling_command_queued)!
		submit: event.profiling_timestamp(profiling_command_submit)!
		start: event.profiling_timestamp(profiling_command_start)!
		end: event.profiling_timestamp(profiling_command_end)!
	}
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
