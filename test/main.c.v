module main

import opencl as cl

fn main() {
	mut count := u32(0)
	result := cl.get_platform_ids(0, unsafe { nil }, &count)
	if result == cl.platform_not_found_khr {
		println('OpenCL ICD loader found; no platform is installed')
		return
	}
	if result != cl.success {
		panic('clGetPlatformIDs failed: ${result}')
	}
	println('OpenCL platforms: ${count}')
}
