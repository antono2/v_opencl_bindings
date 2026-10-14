module main

import antono2.opencl as cl
import antono2.opencl.algorithms

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	mut session := cl.new_session(cl.SessionOptions{})!
	defer { session.close() or {} }
	mut workspace := algorithms.new_workspace(session.context, session.queue, session.device.device)!
	defer { workspace.close() or {} }
	mut flags := cl.buffer_from_slice[u32](session.context, session.queue, cl.mem_read_only, [
		u32(0),
		7,
		0,
		1,
		1,
	])!
	defer { flags.close() or {} }
	mut indices := cl.new_buffer[u32](session.context, cl.mem_read_write, 5)!
	defer { indices.close() or {} }
	mut count := cl.new_buffer[u32](session.context, cl.mem_read_write, 1)!
	defer { count.close() or {} }
	mut done := workspace.compact_indices(flags, indices, count, 5, [])!
	defer { done.close() or {} }
	done.wait()!
	mut selected := [u32(0)]
	count.read(session.queue, 0, mut selected)!
	mut result := []u32{len: int(selected[0])}
	indices.read(session.queue, 0, mut result)!
	assert result == [u32(1), 3, 4]
	println('selected indices: ${result}')
}
