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

fn test_device_capabilities_use_exact_extension_names() {
	capabilities := cl.DeviceCapabilities{
		extensions: ['cl_khr_device_uuid', 'cl_khr_external_memory']
	}
	assert capabilities.has('cl_khr_device_uuid')
	assert capabilities.has_all(['cl_khr_device_uuid', 'cl_khr_external_memory'])
	assert !capabilities.has('cl_khr_device')
	assert !capabilities.has_all(['cl_khr_device_uuid', 'cl_khr_semaphore'])
}

fn test_device_capability_discovery_and_optional_uuid() ! {
	available_platforms := cl.platforms()!
	if available_platforms.len == 0 {
		return
	}
	available_devices := cl.devices(available_platforms[0], cl.device_type_all)!
	if available_devices.len == 0 {
		return
	}
	capabilities := cl.device_capabilities(available_devices[0])!
	assert capabilities.has_all(capabilities.extensions)
	if capabilities.device_uuid {
		assert capabilities.uuid()!.len == int(cl.uuid_size_khr)
		assert capabilities.driver_uuid()!.len == int(cl.uuid_size_khr)
	}
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

fn test_owned_event_marker_lifecycle() ! {
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
	mut first := queue.marker([]cl.Event{})!
	mut second := queue.barrier([first.handle])!
	second.wait()!
	assert second.execution_status()! == cl.complete
	second.close()!
	first.close()!
	assert isnil(second.handle)
	second.close()!
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

fn test_program_kernel_and_typed_argument() ! {
	available_platforms := cl.platforms()!
	if available_platforms.len == 0 {
		return
	}
	available_devices := cl.devices(available_platforms[0], cl.device_type_all)!
	if available_devices.len == 0 {
		return
	}
	device := available_devices[0]
	mut context := cl.new_context(device)!
	mut queue := context.command_queue(device, cl.queue_profiling_enable)!
	mut buffer := cl.new_buffer[u32](&context, cl.mem_read_write, 4)!
	mut program := cl.build_source_program(&context, device, '__kernel void add(__global uint *values, uint amount) { size_t index = get_global_id(0) + get_global_size(0) * get_global_id(1); values[index] += amount; }', '')!
	mut kernel := program.kernel('add')!
	kernel.set_buffer_arg(0, buffer.handle)!
	amount := u32(7)
	kernel.set_arg(1, &amount)!
	values := [u32(1), 2, 3, 4]
	mut write_event := buffer.write_async(&queue, 0, values, []cl.Event{})!
	mut kernel_event := kernel.enqueue_nd_after(&queue, [usize(2), 2], []usize{}, [
		write_event.handle,
	])!
	mut result := []u32{len: 4}
	mut read_event := buffer.read_async(&queue, 0, mut result, [kernel_event.handle])!
	read_event.wait()!
	assert result == [u32(8), 9, 10, 11]
	profile := read_event.profile()!
	assert profile.end >= profile.start
	read_event.close()!
	kernel_event.close()!
	write_event.close()!
	kernel.close()!
	program.close()!
	buffer.close()!
	queue.close()!
	context.close()!
}
