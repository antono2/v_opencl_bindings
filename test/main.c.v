module main

import opencl as cl

fn main() {
	assert sizeof(cl.ImageFormat) == 2 * sizeof(u32)
	assert sizeof(cl.BufferRegion) == 2 * sizeof(usize)
	assert sizeof(cl.ImageDesc) == 8 * sizeof(usize) + 2 * sizeof(u32)
	mut count := u32(0)
	check(cl.get_platform_ids(0, unsafe { nil }, &count), 'count platforms')
	assert count > 0

	mut platform := cl.PlatformId(unsafe { nil })
	check(cl.get_platform_ids(1, &platform, unsafe { nil }), 'get platform ID')

	mut device_count := u32(0)
	check(cl.get_device_ids(platform, cl.device_type_all, 0, unsafe { nil }, &device_count), 'count devices')
	assert device_count > 0
	mut device := cl.DeviceId(unsafe { nil })
	check(cl.get_device_ids(platform, cl.device_type_all, 1, &device, unsafe { nil }), 'get device')

	mut error_code := cl.success
	context := cl.create_context(unsafe { nil }, 1, &device, unsafe { nil }, unsafe { nil }, &error_code)
	check(error_code, 'create context')
	defer {
		check(cl.release_context(context), 'release context')
	}
	user_event := cl.create_user_event(context, &error_code)
	check(error_code, 'create user event')
	mut event_status := i32(-1)
	check(cl.set_user_event_status(user_event, cl.complete), 'complete user event')
	check(cl.get_event_info(user_event, cl.event_command_execution_status, sizeof(i32), &event_status, unsafe { nil }), 'get user event status')
	assert event_status == cl.complete
	check(cl.release_event(user_event), 'release user event')

	queue := cl.create_command_queue(context, device, 0, &error_code)
	check(error_code, 'create command queue')
	defer {
		check(cl.release_command_queue(queue), 'release command queue')
	}
	dependency := cl.create_user_event(context, &error_code)
	check(error_code, 'create marker dependency')
	check(cl.set_user_event_status(dependency, cl.complete), 'complete marker dependency')
	mut marker := cl.Event(unsafe { nil })
	check(cl.enqueue_marker_with_wait_list(queue, 1, &dependency, &marker), 'enqueue marker with wait list')
	check(cl.wait_for_events(1, &marker), 'wait for marker')
	check(cl.release_event(marker), 'release marker')
	check(cl.release_event(dependency), 'release marker dependency')

	input := [f32(1), 2, 3, 4]
	mut output := []f32{len: input.len}
	byte_size := usize(input.len) * sizeof(f32)
	input_buffer := cl.create_buffer(context, cl.mem_read_only | cl.mem_copy_host_ptr, byte_size, unsafe { input.data }, &error_code)
	check(error_code, 'create input buffer')
	defer {
		check(cl.release_mem_object(input_buffer), 'release input buffer')
	}
	output_buffer := cl.create_buffer(context, cl.mem_write_only, byte_size, unsafe { nil }, &error_code)
	check(error_code, 'create output buffer')
	defer {
		check(cl.release_mem_object(output_buffer), 'release output buffer')
	}

	source := '__kernel void add_one(__global const float *input, __global float *output) {\n' + '  size_t i = get_global_id(0); output[i] = input[i] + 1.0f;\n}'
	source_pointer := source.str
	source_length := usize(source.len)
	program := cl.create_program_with_source(context, 1, &source_pointer, &source_length, &error_code)
	check(error_code, 'create program')
	defer {
		check(cl.release_program(program), 'release program')
	}
	build_result := cl.build_program(program, 1, &device, unsafe { nil }, unsafe { nil }, unsafe { nil })
	if build_result != cl.success {
		panic('build program failed (${build_result}): ${program_build_log(program, device)}')
	}

	kernel := cl.create_kernel(program, c'add_one', &error_code)
	check(error_code, 'create kernel')
	defer {
		check(cl.release_kernel(kernel), 'release kernel')
	}
	check(cl.set_kernel_arg(kernel, 0, sizeof(cl.Mem), &input_buffer), 'set input argument')
	check(cl.set_kernel_arg(kernel, 1, sizeof(cl.Mem), &output_buffer), 'set output argument')
	global_size := usize(input.len)
	check(cl.enqueue_nd_range_kernel(queue, kernel, 1, unsafe { nil }, &global_size, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'enqueue kernel')
	check(cl.enqueue_read_buffer(queue, output_buffer, cl._true, 0, byte_size, output.data, 0, unsafe { nil }, unsafe { nil }), 'read output')
	check(cl.finish(queue), 'finish queue')
	assert output == [f32(2), 3, 4, 5]
	println('OpenCL compute smoke test passed on ${device_name(device)}')
}

fn check(result cl.ErrorCode, operation string) {
	if result != cl.success {
		panic('${operation} failed: ${result}')
	}
}

fn program_build_log(program cl.Program, device cl.DeviceId) string {
	mut size := usize(0)
	check(cl.get_program_build_info(program, device, cl.program_build_log, 0, unsafe { nil }, &size), 'get build log size')
	if size == 0 {
		return ''
	}
	mut bytes := []u8{len: int(size)}
	check(cl.get_program_build_info(program, device, cl.program_build_log, size, bytes.data, unsafe { nil }), 'get build log')
	return unsafe { cstring_to_vstring(&char(bytes.data)) }
}

fn device_name(device cl.DeviceId) string {
	mut size := usize(0)
	check(cl.get_device_info(device, cl.device_name, 0, unsafe { nil }, &size), 'get device name size')
	mut bytes := []u8{len: int(size)}
	check(cl.get_device_info(device, cl.device_name, size, bytes.data, unsafe { nil }), 'get device name')
	return unsafe { cstring_to_vstring(&char(bytes.data)) }
}
