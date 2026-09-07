module main

import antono2.opencl as cl

const particle_stride = usize(8 * sizeof(f32))

struct Compute {
	platform cl.PlatformId
	device   cl.DeviceId
	context  cl.Context
	queue    cl.CommandQueue
	program  cl.Program
	reset    cl.Kernel
	step     cl.Kernel
	buffer   cl.Mem
	count    usize
}

fn new_compute(count usize) !Compute {
	mut platform_count := u32(0)
	cl_check(cl.get_platform_ids(0, unsafe { nil }, &platform_count), 'count OpenCL platforms')!
	if platform_count == 0 {
		return error('no OpenCL platforms found')
	}
	mut platforms := unsafe { []cl.PlatformId{len: int(platform_count)} }
	cl_check(cl.get_platform_ids(platform_count, platforms.data, unsafe { nil }), 'enumerate OpenCL platforms')!

	mut selected_platform := cl.PlatformId(unsafe { nil })
	mut selected_device := cl.DeviceId(unsafe { nil })
	for platform in platforms {
		mut device_count := u32(0)
		if cl.get_device_ids(platform, cl.device_type_gpu, 0, unsafe { nil }, &device_count) == cl.success
			&& device_count > 0 {
			mut devices := unsafe { []cl.DeviceId{len: int(device_count)} }
			cl_check(cl.get_device_ids(platform, cl.device_type_gpu, device_count, devices.data, unsafe { nil }), 'enumerate OpenCL GPUs')!
			selected_platform = platform
			selected_device = devices[0]
			break
		}
	}
	if isnil(selected_device) {
		selected_platform = platforms[0]
		mut device_count := u32(0)
		cl_check(cl.get_device_ids(selected_platform, cl.device_type_all, 0, unsafe { nil }, &device_count), 'count OpenCL devices')!
		if device_count == 0 {
			return error('no OpenCL devices found')
		}
		mut devices := unsafe { []cl.DeviceId{len: int(device_count)} }
		cl_check(cl.get_device_ids(selected_platform, cl.device_type_all, device_count, devices.data, unsafe { nil }), 'enumerate OpenCL devices')!
		selected_device = devices[0]
	}

	mut code := cl.success
	context := cl.create_context(unsafe { nil }, 1, &selected_device, unsafe { nil }, unsafe { nil }, &code)
	cl_check(code, 'create OpenCL context')!
	queue := cl.create_command_queue(context, selected_device, 0, &code)
	cl_check(code, 'create OpenCL command queue') or {
		cl.release_context(context)
		return err
	}
	source := $embed_file('particles.cl').to_string()
	source_pointer := source.str
	source_length := usize(source.len)
	program := cl.create_program_with_source(context, 1, &source_pointer, &source_length, &code)
	cl_check(code, 'create OpenCL program')!
	if cl.build_program(program, 1, &selected_device, unsafe { nil }, unsafe { nil }, unsafe { nil }) != cl.success {
		log := cl_program_build_log(program, selected_device)
		return error('build OpenCL particle kernels:\n${log}')
	}
	reset := cl.create_kernel(program, c'reset_particles', &code)
	cl_check(code, 'create reset_particles kernel')!
	step := cl.create_kernel(program, c'step_particles', &code)
	cl_check(code, 'create step_particles kernel')!
	buffer := cl.create_buffer(context, cl.mem_read_write, count * particle_stride, unsafe { nil }, &code)
	cl_check(code, 'create particle buffer')!
	mut compute := Compute{
		platform: selected_platform
		device: selected_device
		context: context
		queue: queue
		program: program
		reset: reset
		step: step
		buffer: buffer
		count: count
	}
	compute.reset_particles(1)!
	return compute
}

fn (compute &Compute) reset_particles(seed u32) ! {
	compute.reset_buffer(compute.buffer, seed)!
}

fn (compute &Compute) reset_buffer(buffer cl.Mem, seed u32) ! {
	cl_check(cl.set_kernel_arg(compute.reset, 0, sizeof(cl.Mem), &buffer), 'set reset buffer')!
	cl_check(cl.set_kernel_arg(compute.reset, 1, sizeof(u32), &seed), 'set reset seed')!
	cl_check(cl.enqueue_nd_range_kernel(compute.queue, compute.reset, 1, unsafe { nil }, &compute.count, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'enqueue reset kernel')!
	cl_check(cl.finish(compute.queue), 'finish reset kernel')!
}

fn (compute &Compute) update(dt f32, elapsed f32, pointer_x f32, pointer_y f32, attraction f32) ! {
	compute.update_buffer(compute.buffer, dt, elapsed, pointer_x, pointer_y, attraction)!
}

fn (compute &Compute) update_buffer(buffer cl.Mem, dt f32, elapsed f32, pointer_x f32,
	pointer_y f32, attraction f32) ! {
	pointer := [pointer_x, pointer_y]
	cl_check(cl.set_kernel_arg(compute.step, 0, sizeof(cl.Mem), &buffer), 'set step buffer')!
	cl_check(cl.set_kernel_arg(compute.step, 1, sizeof(f32), &dt), 'set timestep')!
	cl_check(cl.set_kernel_arg(compute.step, 2, sizeof(f32), &elapsed), 'set elapsed time')!
	cl_check(cl.set_kernel_arg(compute.step, 3, 2 * sizeof(f32), pointer.data), 'set pointer')!
	cl_check(cl.set_kernel_arg(compute.step, 4, sizeof(f32), &attraction), 'set attraction')!
	cl_check(cl.enqueue_nd_range_kernel(compute.queue, compute.step, 1, unsafe { nil }, &compute.count, unsafe { nil }, 0, unsafe { nil }, unsafe { nil }), 'enqueue particle step')!
}

fn (compute &Compute) read_particles(mut destination []f32) ! {
	if destination.len < int(compute.count * 8) {
		return error('particle destination is too small')
	}
	cl_check(cl.enqueue_read_buffer(compute.queue, compute.buffer, cl._true, 0, compute.count * particle_stride, destination.data, 0, unsafe { nil }, unsafe { nil }), 'read particle buffer')!
}

fn (compute &Compute) close() {
	cl.release_mem_object(compute.buffer)
	cl.release_kernel(compute.step)
	cl.release_kernel(compute.reset)
	cl.release_program(compute.program)
	cl.release_command_queue(compute.queue)
	cl.release_context(compute.context)
}

fn cl_check(result cl.ErrorCode, operation string) ! {
	if result != cl.success {
		return error('${operation} failed with OpenCL error ${result}')
	}
}

fn cl_info_string(device cl.DeviceId, parameter cl.DeviceInfo) string {
	mut size := usize(0)
	if cl.get_device_info(device, parameter, 0, unsafe { nil }, &size) != cl.success || size == 0 {
		return 'unknown'
	}
	mut bytes := []u8{len: int(size)}
	if cl.get_device_info(device, parameter, size, bytes.data, unsafe { nil }) != cl.success {
		return 'unknown'
	}
	return unsafe { cstring_to_vstring(&char(bytes.data)) }
}

fn cl_program_build_log(program cl.Program, device cl.DeviceId) string {
	mut size := usize(0)
	cl.get_program_build_info(program, device, cl.program_build_log, 0, unsafe { nil }, &size)
	if size == 0 {
		return ''
	}
	mut bytes := []u8{len: int(size)}
	cl.get_program_build_info(program, device, cl.program_build_log, size, bytes.data, unsafe { nil })
	return unsafe { cstring_to_vstring(&char(bytes.data)) }
}
