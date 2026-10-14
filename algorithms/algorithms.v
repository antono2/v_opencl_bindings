// Optional device-resident integer scan and stable index compaction.
module algorithms

import antono2.opencl as cl

const source = '
__kernel void vcl_normalize(__global const uint *input, __global uint *output) {
  size_t i = get_global_id(0); output[i] = input[i] != 0;
}
__kernel void vcl_scan_step(__global const uint *input, __global uint *output, uint offset) {
  size_t i = get_global_id(0); uint v = input[i];
  if (i >= offset) v += input[i-offset]; output[i] = v;
}
__kernel void vcl_scatter(__global const uint *flags, __global const uint *scan,
                      __global uint *indices, __global uint *count, uint n) {
  size_t i = get_global_id(0);
  if (flags[i]) indices[scan[i]-1] = (uint)i;
  if (i == n-1) count[0] = scan[i];
}'

// Workspace caches kernels and storage. Calls serialize through events without
// host waits. It is not thread-safe; use one workspace per producer. Inputs and
// outputs must share its context. Close after completing submitted work.
@[nocopy]
pub struct Workspace {
mut:
	queue     &cl.OwnedCommandQueue
	program   &cl.OwnedProgram
	normalize &cl.OwnedKernel
	step      &cl.OwnedKernel
	scatter   &cl.OwnedKernel
	a         &cl.ScratchBuffer[u32]
	b         &cl.ScratchBuffer[u32]
	last      ?&cl.OwnedEvent
}

pub fn new_workspace(context &cl.OwnedContext, queue &cl.OwnedCommandQueue, device cl.DeviceId) !&Workspace {
	mut program := cl.build_source_program(context, device, source, '')!
	mut success := false
	defer {
		if !success { program.close() or {} }
	}
	mut normalize := program.kernel('vcl_normalize')!
	defer {
		if !success { normalize.close() or {} }
	}
	mut step := program.kernel('vcl_scan_step')!
	defer {
		if !success { step.close() or {} }
	}
	mut scatter := program.kernel('vcl_scatter')!
	defer {
		if !success { scatter.close() or {} }
	}
	mut a := cl.new_scratch_buffer[u32](context, cl.mem_read_write)!
	defer {
		if !success { a.close() or {} }
	}
	mut b := cl.new_scratch_buffer[u32](context, cl.mem_read_write)!
	defer {
		if !success { b.close() or {} }
	}
	retained_queue := queue.clone_ref()!
	success = true
	return &Workspace{
		queue:     retained_queue
		program:   program
		normalize: normalize
		step:      step
		scatter:   scatter
		a:         a
		b:         b
	}
}

fn (workspace &Workspace) dependencies(events []cl.Event) []cl.Event {
	mut result := events.clone()
	if previous := workspace.last { result << previous.handle }
	return result
}

fn (mut workspace Workspace) remember(event &cl.OwnedEvent) ! {
	mut retained := event.clone_ref() or {
		event.wait() or {}
		return err
	}
	if mut previous := workspace.last {
		previous.close() or {
			retained.close() or {}
			event.wait() or {}
			return err
		}
	}
	workspace.last = retained
}

// inclusive_scan computes unsigned prefix sums modulo 2^32. Input/output must
// be distinct, count may be zero. Returns completion, without reading to host.
pub fn (mut workspace Workspace) inclusive_scan(input &cl.Buffer[u32], output &cl.Buffer[u32], count int, wait_events []cl.Event) !&cl.OwnedEvent {
	if count < 0 || count > input.count || count > output.count {
		return error('scan count exceeds buffer capacity')
	}
	if input.handle == output.handle {
		return error('scan input and output must be distinct')
	}
	dependencies := workspace.dependencies(wait_events)
	if count == 0 {
		mut event := workspace.queue.marker(dependencies)!
		workspace.remember(event) or {
			event.close() or {}
			return err
		}
		return event
	}
	workspace.a.reserve(count)!
	workspace.b.reserve(count)!
	mut a := workspace.a.buffer or { return error('missing scan scratch') }
	mut b := workspace.b.buffer or { return error('missing scan scratch') }
	mut event := input.copy_to(workspace.queue, a, 0, 0, count, dependencies)!
	// Remember every enqueue so an intermediate failure cannot permit scratch
	// reuse before already-submitted work finishes.
	defer { event.close() or {} }
	workspace.remember(event)!
	mut offset := 1
	for offset < count {
		workspace.step.set_buffer_arg(0, a.handle)!
		workspace.step.set_buffer_arg(1, b.handle)!
		value := u32(offset)
		workspace.step.set_arg(2, &value)!
		mut next := workspace.step.enqueue_1d_after(workspace.queue, usize(count), 0, [
			event.handle,
		])!
		workspace.remember(next) or {
			next.close() or {}
			return err
		}
		event.close()!
		event = next
		a, b = b, a
		if offset > count / 2 {
			break
		}
		offset *= 2
	}
	mut result := a.copy_to(workspace.queue, output, 0, 0, count, [event.handle])!
	workspace.remember(result) or {
		result.close() or {}
		return err
	}
	return result
}

// compact_indices emits ascending source indices for nonzero flags. Output
// capacity must cover count (the worst case). selected_count[0] remains on the
// device; only its prefix of indices is defined. All three buffers are distinct.
pub fn (mut workspace Workspace) compact_indices(flags &cl.Buffer[u32], indices &cl.Buffer[u32], selected_count &cl.Buffer[u32], count int, wait_events []cl.Event) !&cl.OwnedEvent {
	if count < 0 || count > flags.count || count > indices.count || selected_count.count < 1 {
		return error('compaction capacity is insufficient')
	}
	if flags.handle == indices.handle || flags.handle == selected_count.handle
		|| indices.handle == selected_count.handle {
		return error('compaction buffers must be distinct')
	}
	dependencies := workspace.dependencies(wait_events)
	if count == 0 {
		mut event := selected_count.fill(workspace.queue, u32(0), 0, 1, dependencies)!
		workspace.remember(event) or {
			event.close() or {}
			return err
		}
		return event
	}
	workspace.a.reserve(count)!
	workspace.b.reserve(count)!
	mut a := workspace.a.buffer or { return error('missing compaction scratch') }
	mut b := workspace.b.buffer or { return error('missing compaction scratch') }
	workspace.normalize.set_buffer_arg(0, flags.handle)!
	workspace.normalize.set_buffer_arg(1, a.handle)!
	mut event := workspace.normalize.enqueue_1d_after(workspace.queue, usize(count), 0,
		dependencies)!
	defer { event.close() or {} }
	workspace.remember(event)!
	mut offset := 1
	for offset < count {
		workspace.step.set_buffer_arg(0, a.handle)!
		workspace.step.set_buffer_arg(1, b.handle)!
		value := u32(offset)
		workspace.step.set_arg(2, &value)!
		mut next := workspace.step.enqueue_1d_after(workspace.queue, usize(count), 0, [
			event.handle,
		])!
		workspace.remember(next) or {
			next.close() or {}
			return err
		}
		event.close()!
		event = next
		a, b = b, a
		if offset > count / 2 {
			break
		}
		offset *= 2
	}
	workspace.scatter.set_buffer_arg(0, flags.handle)!
	workspace.scatter.set_buffer_arg(1, a.handle)!
	workspace.scatter.set_buffer_arg(2, indices.handle)!
	workspace.scatter.set_buffer_arg(3, selected_count.handle)!
	n := u32(count)
	workspace.scatter.set_arg(4, &n)!
	mut result := workspace.scatter.enqueue_1d_after(workspace.queue, usize(count), 0, [
		event.handle,
	])!
	workspace.remember(result) or {
		result.close() or {}
		return err
	}
	return result
}

pub fn (mut workspace Workspace) close() ! {
	if mut event := workspace.last {
		event.wait()!
		event.close()!
		workspace.last = none
	}
	workspace.a.close()!
	workspace.b.close()!
	workspace.scatter.close()!
	workspace.step.close()!
	workspace.normalize.close()!
	workspace.program.close()!
	workspace.queue.close()!
}
