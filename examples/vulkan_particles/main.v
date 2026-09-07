module main

import os
import antono2.opencl as cl
import time

fn main() {
	base_options := options_from_environment() or { panic(err) }
	options := parse_options(base_options, os.args[1..]) or { panic('${err}\n\n${usage()}') }
	if options.help {
		println(usage())
		return
	}
	count := options.particle_count
	mut compute := new_compute(count) or { panic(err) }
	defer {
		compute.close()
	}
	println('OpenCL device: ${cl_info_string(compute.device, cl.device_name)}')
	println('Particle count: ${count}')
	interop := probe_interop(compute.device)
	println('Vulkan device: ${interop.vulkan_device}')
	println('Interop mode: ${interop.describe()}')
	if options.require_zero_copy && !interop.zero_copy_available {
		panic('zero-copy required: ${interop.describe()}')
	}
	if interop.zero_copy_available {
		zero_copy_memory_smoke(&compute) or { panic(err) }
	}
	if options.window {
		if options.force_staged {
			println('Renderer override: staged transfer path')
		}
		window_device_loop(&compute, count, interop.zero_copy_available && !options.force_staged, options.frame_limit) or { panic(err) }
	}

	// Until the Vulkan presentation loop is connected, exercise the exact simulation buffer
	// contract for a few frames. This also provides a display-independent CI smoke mode.
	mut particles := []f32{len: int(count * 8)}
	started := time.now()
	for frame in 0 .. 8 {
		compute.update(1.0 / 60.0, f32(frame) / 60.0, 0.0, 0.0, 0.11) or { panic(err) }
	}
	compute.read_particles(mut particles) or { panic(err) }
	elapsed := time.since(started)
	println('Simulation smoke pass: first particle = (${particles[0]:.3f}, ${particles[1]:.3f}), ${elapsed}')
}
