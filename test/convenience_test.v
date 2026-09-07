module main

import antono2.opencl as cl

fn test_error_preserves_operation_and_status() {
	err := cl.OpenCLError{
		operation: 'create buffer'
		status: cl.invalid_value
	}
	assert err.code() == -30
	assert err.msg() == 'create buffer: invalid_value (-30)'
}

fn test_check_accepts_success() {
	cl.check(cl.success, 'successful operation') or { assert false, err.msg() }
}

fn test_unknown_error_name_is_stable() {
	assert cl.error_code_name(cl.ErrorCode(-9999)) == 'opencl_error'
}

fn test_owned_context_and_queue_lifecycle() ! {
	available_platforms := cl.platforms()!
	if available_platforms.len == 0 {
		return
	}
	available_devices := cl.devices(available_platforms[0], cl.device_type_all)!
	if available_devices.len == 0 {
		return
	}
	mut context := cl.new_context(available_devices[0])!
	mut queue := context.command_queue(available_devices[0], cl.CommandQueueProperties(0))!
	queue.close()!
	context.close()!
	assert isnil(queue.handle)
	assert isnil(context.handle)
	queue.close()!
	context.close()!
}

fn test_typed_buffer_round_trip() ! {
	available_platforms := cl.platforms()!
	if available_platforms.len == 0 {
		return
	}
	available_devices := cl.devices(available_platforms[0], cl.device_type_all)!
	if available_devices.len == 0 {
		return
	}
	mut context := cl.new_context(available_devices[0])!
	mut queue := context.command_queue(available_devices[0], cl.CommandQueueProperties(0))!
	mut buffer := cl.new_buffer[u32](&context, cl.mem_read_write, 4)!
	buffer.write(&queue, 0, [u32(3), 5, 8, 13])!
	mut result := []u32{len: 4}
	buffer.read(&queue, 0, mut result)!
	assert result == [u32(3), 5, 8, 13]
	buffer.close()!
	queue.close()!
	context.close()!
}
