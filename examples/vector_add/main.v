// Builds and executes a vector-add kernel using owned OpenCL resource helpers.
module main

import antono2.opencl as cl

const source = '__kernel void add(__global const float *a, __global const float *b, __global float *result) { size_t i = get_global_id(0); result[i] = a[i] + b[i]; }'

fn run() ! {
	platforms := cl.platforms()!
	if platforms.len == 0 {
		return error('no OpenCL platform found')
	}
	devices := cl.devices(platforms[0], cl.device_type_all)!
	if devices.len == 0 {
		return error('no OpenCL device found')
	}
	device := devices[0]
	mut context := cl.new_context(device)!
	mut queue := context.command_queue(device, cl.queue_profiling_enable)!
	left := [f32(1), 2, 3, 4]
	right := [f32(10), 20, 30, 40]
	mut a := cl.new_buffer[f32](context, cl.mem_read_only, left.len)!
	mut b := cl.new_buffer[f32](context, cl.mem_read_only, left.len)!
	mut result_buffer := cl.new_buffer[f32](context, cl.mem_write_only, left.len)!
	mut program := cl.build_source_program(context, device, source, '')!
	mut kernel := program.kernel('add')!
	// Argument indices follow the add(a, b, result) kernel signature.
	kernel.set_buffer_arg(0, a.handle)!
	kernel.set_buffer_arg(1, b.handle)!
	kernel.set_buffer_arg(2, result_buffer.handle)!

	// Transfers start at element 0 and cover the entire input.
	mut left_ready := a.write_async(queue, 0, left, []cl.Event{})!
	mut right_ready := b.write_async(queue, 0, right, []cl.Event{})!
	// Local size 0 lets OpenCL choose; launch one work-item per input element.
	mut computed := kernel.enqueue_1d_after(queue, usize(left.len), 0,
		[left_ready.handle, right_ready.handle])!
	mut result := []f32{len: left.len}
	mut downloaded := result_buffer.read_async(queue, 0, mut result, [
		computed.handle,
	])!
	profile := downloaded.profile()!
	println('${result} (readback ${profile.duration()} ns)')

	downloaded.close()!
	computed.close()!
	right_ready.close()!
	left_ready.close()!
	kernel.close()!
	program.close()!
	result_buffer.close()!
	b.close()!
	a.close()!
	queue.close()!
	context.close()!
}

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}
