module main

import os
import antono2.opencl as cl
import time

fn main() {
	count_text := os.getenv_opt('PARTICLE_COUNT') or { '32768' }
	count := usize(count_text.parse_uint(10, 32) or { panic('invalid PARTICLE_COUNT: ${err}') })
	mut compute := new_compute(count) or { panic(err) }
	defer {
		compute.close()
	}
	println('OpenCL device: ${cl_info_string(compute.device, cl.device_name)}')
	println('Particle count: ${count}')
	interop := probe_interop(compute.device)
	println('Vulkan device: ${interop.vulkan_device}')
	println('Interop mode: ${interop.describe()}')
	if interop.zero_copy_available {
		zero_copy_memory_smoke(&compute) or { panic(err) }
	}
	if os.getenv('PARTICLES_WINDOW') == '1' {
		force_staged := os.getenv('PARTICLES_FORCE_STAGED') == '1'
		if force_staged {
			println('Renderer override: staged transfer path')
		}
		window_device_loop(&compute, count, interop.zero_copy_available && !force_staged) or {
			panic(err)
		}
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
