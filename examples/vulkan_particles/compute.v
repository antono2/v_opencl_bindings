module main

import antono2.opencl as cl

const particle_stride = usize(8 * sizeof(f32))

struct Compute {
	platform cl.PlatformId
	device   cl.DeviceId
	context  cl.OwnedContext
	queue    cl.OwnedCommandQueue
	program  cl.OwnedProgram
	reset    cl.OwnedKernel
	step     cl.OwnedKernel
	buffer   cl.Buffer[f32]
	count    usize
}

fn new_compute(count usize) !Compute {
	platforms := cl.platforms()!
	if platforms.len == 0 {
		return error('no OpenCL platforms found')
	}

	mut selected_platform := cl.PlatformId(unsafe { nil })
	mut selected_device := cl.DeviceId(unsafe { nil })
	for platform in platforms {
		devices := cl.devices(platform, cl.device_type_gpu)!
		if devices.len > 0 {
			selected_platform = platform
			selected_device = devices[0]
			break
		}
	}
	if isnil(selected_device) {
		selected_platform = platforms[0]
		devices := cl.devices(selected_platform, cl.device_type_all)!
		if devices.len == 0 {
			return error('no OpenCL devices found')
		}
		selected_device = devices[0]
	}

	mut context := cl.new_context(selected_device)!
	mut queue := context.command_queue(selected_device, cl.CommandQueueProperties(0)) or {
		context.close() or {}
		return err
	}
	source := $embed_file('particles.cl').to_string()
	mut program := cl.build_source_program(&context, selected_device, source, '') or {
		queue.close() or {}
		context.close() or {}
		return err
	}
	mut reset := program.kernel('reset_particles') or {
		program.close() or {}
		queue.close() or {}
		context.close() or {}
		return err
	}
	mut step := program.kernel('step_particles') or {
		reset.close() or {}
		program.close() or {}
		queue.close() or {}
		context.close() or {}
		return err
	}
	mut buffer := cl.new_buffer[f32](&context, cl.mem_read_write, int(count * 8)) or {
		step.close() or {}
		reset.close() or {}
		program.close() or {}
		queue.close() or {}
		context.close() or {}
		return err
	}
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
	compute.reset_buffer(compute.buffer.handle, seed)!
}

fn (compute &Compute) reset_buffer(buffer cl.Mem, seed u32) ! {
	compute.reset.set_buffer_arg(0, buffer)!
	compute.reset.set_arg(1, &seed)!
	compute.reset.enqueue_1d(&compute.queue, compute.count, 0)!
	cl.check(cl.finish(compute.queue.handle), 'finish reset kernel')!
}

fn (compute &Compute) update(dt f32, elapsed f32, pointer_x f32, pointer_y f32, attraction f32) ! {
	compute.update_buffer(compute.buffer.handle, dt, elapsed, pointer_x, pointer_y, attraction)!
}

fn (compute &Compute) update_buffer(buffer cl.Mem, dt f32, elapsed f32, pointer_x f32,
	pointer_y f32, attraction f32) ! {
	pointer := [pointer_x, pointer_y]
	compute.step.set_buffer_arg(0, buffer)!
	compute.step.set_arg(1, &dt)!
	compute.step.set_arg(2, &elapsed)!
	compute.step.set_arg(3, &pointer)!
	compute.step.set_arg(4, &attraction)!
	compute.step.enqueue_1d(&compute.queue, compute.count, 0)!
}

fn (compute &Compute) read_particles(mut destination []f32) ! {
	required := int(compute.count * 8)
	if destination.len < required {
		return error('particle destination is too small')
	}
	compute.buffer.read(&compute.queue, 0, mut destination[..required])!
}

fn (mut compute Compute) close() {
	compute.buffer.close() or {}
	compute.step.close() or {}
	compute.reset.close() or {}
	compute.program.close() or {}
	compute.queue.close() or {}
	compute.context.close() or {}
}

fn cl_check(result cl.ErrorCode, operation string) ! {
	cl.check(result, operation)!
}

fn cl_info_string(device cl.DeviceId, parameter cl.DeviceInfo) string {
	return cl.device_info_string(device, parameter) or { 'unknown' }
}
