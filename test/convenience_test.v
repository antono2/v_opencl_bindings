module main

import antono2.opencl as cl

fn test_error_preserves_operation_and_status() {
	err := cl.OpenCLError{
		operation: 'create buffer'
		status:    cl.invalid_value
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

fn test_generated_error_name_covers_full_core_range() {
	assert cl.error_code_name(cl.invalid_event_wait_list) == 'invalid_event_wait_list'
}

fn test_typed_buffer_rejects_byte_size_overflow_before_opencl_call() {
	element_size := usize(sizeof(u64))
	if usize(max_int) <= ~usize(0) / element_size {
		// On V versions with a 32-bit int, this API cannot express a count
		// large enough to overflow usize on a 64-bit host.
		return
	}
	mut context_storage := u8(0)
	context := cl.OwnedContext{
		handle: cl.Context(&context_storage)
	}
	cl.new_buffer[u64](&context, cl.mem_read_write, max_int) or {
		assert err is cl.OpenCLError
		if err is cl.OpenCLError {
			assert err.status == cl.invalid_buffer_size
		}
		return
	}
	assert false
}

fn test_typed_image_rejects_mismatched_pixel_layout_before_opencl_call() {
	mut context_storage := u8(0)
	context := cl.OwnedContext{
		handle: cl.Context(&context_storage)
	}
	format := cl.ImageFormat{
		image_channel_order:     cl.rgba
		image_channel_data_type: cl.unorm_int8
	}
	cl.new_image_2d[u8](&context, cl.mem_read_write, format, 2, 2) or {
		assert err is cl.OpenCLError
		if err is cl.OpenCLError {
			assert err.status == cl.invalid_image_format_descriptor
		}
		return
	}
	assert false
}

fn test_image_pixel_sizes_cover_scalar_vector_and_packed_formats() ! {
	assert cl.image_format_pixel_bytes(cl.ImageFormat{
		image_channel_order:     cl.r
		image_channel_data_type: cl.float
	})! == 4
	assert cl.image_format_pixel_bytes(cl.ImageFormat{
		image_channel_order:     cl.rgba
		image_channel_data_type: cl.unorm_int8
	})! == 4
	assert cl.image_format_pixel_bytes(cl.ImageFormat{
		image_channel_order:     cl.rgb
		image_channel_data_type: cl.unorm_short_565
	})! == 2
}

fn test_typed_image_rejects_out_of_bounds_region_before_opencl_call() {
	mut image_storage := u8(0)
	mut queue_storage := u8(0)
	image := cl.Image2D[u32]{
		handle:      cl.Mem(&image_storage)
		width:       2
		height:      2
		pixel_bytes: 4
	}
	queue := cl.OwnedCommandQueue{
		handle: cl.CommandQueue(&queue_storage)
	}
	image.write_region(&queue, 1, 0, 2, 2, [u32(1), 2, 3, 4]) or {
		assert err is cl.OpenCLError
		if err is cl.OpenCLError {
			assert err.status == cl.invalid_value
		}
		return
	}
	assert false
}

fn test_svm_rejects_byte_size_overflow_before_opencl_call() {
	element_size := usize(sizeof(u64))
	if usize(max_int) <= ~usize(0) / element_size {
		return
	}
	mut context_storage := u8(0)
	context := cl.OwnedContext{
		handle: cl.Context(&context_storage)
	}
	cl.new_svm[u64](&context, cl.mem_read_write, max_int, 0) or {
		assert err is cl.OpenCLError
		if err is cl.OpenCLError {
			assert err.status == cl.invalid_buffer_size
		}
		return
	}
	assert false
}

fn test_svm_rejects_out_of_bounds_transfer_before_opencl_call() {
	mut allocation_storage := u8(0)
	mut queue_storage := u8(0)
	allocation := cl.SvmAllocation[u32]{
		handle: &allocation_storage
		count:  4
	}
	queue := cl.OwnedCommandQueue{
		handle: cl.CommandQueue(&queue_storage)
	}
	allocation.write(&queue, 3, [u32(1), 2]) or {
		assert err is cl.OpenCLError
		if err is cl.OpenCLError {
			assert err.status == cl.invalid_value
		}
		return
	}
	assert false
}

fn test_external_buffer_rejects_byte_size_overflow_before_opencl_call() {
	element_size := usize(sizeof(u64))
	if usize(max_int) <= ~usize(0) / element_size {
		// On V versions with a 32-bit int, this API cannot express a count
		// large enough to overflow usize on a 64-bit host.
		return
	}
	mut context_storage := u8(0)
	context := cl.OwnedContext{
		handle: cl.Context(&context_storage)
	}
	interop := cl.ExternalMemoryInterop{}
	interop.import_opaque_fd_buffer[u64](&context, 0, max_int, cl.mem_read_write) or {
		assert err is cl.OpenCLError
		if err is cl.OpenCLError {
			assert err.status == cl.invalid_buffer_size
		}
		return
	}
	assert false
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

fn test_external_interop_loader_rejects_missing_capabilities() {
	cl.load_external_memory_interop(cl.PlatformId(unsafe { nil }), cl.DeviceCapabilities{}) or {
		assert err is cl.OpenCLError
		return
	}
	assert false
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

fn test_typed_image_round_trip_and_sampler_lifecycle() ! {
	available_platforms := cl.platforms()!
	if available_platforms.len == 0 {
		return
	}
	available_devices := cl.devices(available_platforms[0], cl.device_type_all)!
	if available_devices.len == 0 {
		return
	}
	mut context := cl.new_context(available_devices[0])!
	formats := cl.supported_image2d_formats(&context, cl.mem_read_write)!
	format := cl.ImageFormat{
		image_channel_order:     cl.rgba
		image_channel_data_type: cl.unorm_int8
	}
	mut supported := false
	for available in formats {
		if available.image_channel_order == format.image_channel_order
			&& available.image_channel_data_type == format.image_channel_data_type {
			supported = true
			break
		}
	}
	if !supported {
		context.close()!
		return
	}
	mut queue := context.command_queue(available_devices[0], cl.CommandQueueProperties(0))!
	mut source_image := cl.new_image_2d[u32](&context, cl.mem_read_only, format, 2, 2)!
	mut destination_image := cl.new_image_2d[u32](&context, cl.mem_write_only, format, 2, 2)!
	mut sampler := cl.new_sampler(&context, false, cl.address_clamp_to_edge, cl.filter_nearest)!
	mut program := cl.build_source_program(&context, available_devices[0],
		'__kernel void copy_image(read_only image2d_t source, write_only image2d_t destination, sampler_t image_sampler) { int2 p = (int2)(get_global_id(0), get_global_id(1)); write_imagef(destination, p, read_imagef(source, image_sampler, p)); }', '')!
	mut kernel := program.kernel('copy_image')!
	source_image.set_kernel_arg(&kernel, 0)!
	destination_image.set_kernel_arg(&kernel, 1)!
	kernel.set_sampler_arg(2, &sampler)!
	values := [u32(0xff0000ff), 0xff00ff00, 0xffff0000, 0xffffffff]
	mut uploaded := source_image.write_async(&queue, values, []cl.Event{})!
	mut copied := kernel.enqueue_nd_after(&queue, [usize(2), 2], []usize{}, [
		uploaded.handle,
	])!
	mut result := []u32{len: 4}
	mut downloaded := destination_image.read_async(&queue, mut result, [
		copied.handle,
	])!
	downloaded.wait()!
	assert result == values
	downloaded.close()!
	copied.close()!
	uploaded.close()!
	kernel.close()!
	program.close()!
	sampler.close()!
	destination_image.close()!
	source_image.close()!
	queue.close()!
	context.close()!
	assert isnil(sampler.handle)
	assert isnil(destination_image.handle)
	assert isnil(source_image.handle)
}

fn test_svm_kernel_round_trip() ! {
	available_platforms := cl.platforms()!
	if available_platforms.len == 0 {
		return
	}
	available_devices := cl.devices(available_platforms[0], cl.device_type_all)!
	if available_devices.len == 0 {
		return
	}
	device := available_devices[0]
	capabilities := cl.device_svm_support(device)!
	if capabilities & (cl.device_svm_coarse_grain_buffer | cl.device_svm_fine_grain_buffer) == 0 {
		return
	}
	mut context := cl.new_context(device)!
	mut queue := context.command_queue(device, cl.CommandQueueProperties(0))!
	mut allocation := cl.new_svm[u32](&context, cl.mem_read_write, 4, 0)!
	allocation.map(&queue, cl.map_write)!
	mut unmapped := allocation.unmap(&queue, []cl.Event{})!
	unmapped.wait()!
	mut program := cl.build_source_program(&context, device,
		'__kernel void add(__global uint *values, uint amount) { values[get_global_id(0)] += amount; }', '')!
	mut kernel := program.kernel('add')!
	allocation.set_kernel_arg(&kernel, 0)!
	amount := u32(7)
	kernel.set_arg(1, &amount)!
	values := [u32(1), 2, 3, 4]
	mut uploaded := allocation.write_async(&queue, 0, values, [unmapped.handle])!
	mut computed := kernel.enqueue_1d_after(&queue, 4, 0, [uploaded.handle])!
	mut result := []u32{len: 4}
	mut downloaded := allocation.read_async(&queue, 0, mut result, [computed.handle])!
	downloaded.wait()!
	assert result == [u32(8), 9, 10, 11]
	downloaded.close()!
	computed.close()!
	uploaded.close()!
	unmapped.close()!
	kernel.close()!
	program.close()!
	allocation.close()
	queue.close()!
	context.close()!
	assert isnil(allocation.handle)
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
	mut program := cl.build_source_program(&context, device,
		'__kernel void add(__global uint *values, uint amount) { size_t index = get_global_id(0) + get_global_size(0) * get_global_id(1); values[index] += amount; }', '')!
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
