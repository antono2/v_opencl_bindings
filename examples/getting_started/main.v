// A complete first kernel with checked output and failure-safe cleanup.
module main

import antono2.opencl as cl

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	mut session := cl.new_session(cl.SessionOptions{})!
	defer { session.close() or {} }
	mut values := cl.buffer_from_slice[f32](session.context, session.queue, cl.mem_read_write, [
		f32(1),
		2,
		3,
		4,
	])!
	defer { values.close() or {} }
	mut program := cl.build_source_program(session.context, session.device.device,
		'__kernel void twice(__global float *v) { v[get_global_id(0)] *= 2.0f; }', '')!
	defer { program.close() or {} }
	mut kernel := program.kernel('twice')!
	defer { kernel.close() or {} }
	kernel.set_buffer_arg(0, values.handle)!
	kernel.enqueue_1d(session.queue, 4, 0)!
	mut result := []f32{len: 4}
	values.read(session.queue, 0, mut result)!
	assert result == [f32(2), 4, 6, 8]
	println('${session.device.name}: ${result}')
}
