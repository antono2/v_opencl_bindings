// End-to-end comparison, including host upload, count and result readback.
module main

import time
import antono2.opencl as cl
import antono2.opencl.algorithms

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	mut session := cl.new_session(cl.SessionOptions{})!
	defer { session.close() or {} }
	mut workspace :=
		algorithms.new_workspace(session.context, session.queue, session.device.device)!
	defer { workspace.close() or {} }
	println('device=${session.device.name}; five measured iterations after warmup; host microseconds')
	for n in [256, 4096, 65536] {
		values := []u32{len: n, init: if index % 3 == 0 { u32(1) } else { u32(0) }}
		mut input := cl.new_buffer[u32](session.context, cl.mem_read_only, n)!
		defer { input.close() or {} }
		mut output := cl.new_buffer[u32](session.context, cl.mem_read_write, n)!
		defer { output.close() or {} }
		mut count := cl.new_buffer[u32](session.context, cl.mem_read_write, 1)!
		defer { count.close() or {} }
		mut gpu_ns := i64(0)
		mut cpu_ns := i64(0)
		for iteration in 0 .. 6 {
			cpu_start := time.sys_mono_now()
			mut expected := []u32{}
			for i, flag in values {
				if flag != 0 { expected << u32(i) }
			}
			cpu_elapsed := time.sys_mono_now() - cpu_start
			start := time.sys_mono_now()
			input.write(session.queue, 0, values)!
			mut done := workspace.compact_indices(input, output, count, n, [])!
			done.wait()!
			mut selected := [u32(0)]
			count.read(session.queue, 0, mut selected)!
			mut actual := []u32{len: int(selected[0])}
			output.read(session.queue, 0, mut actual)!
			done.close()!
			elapsed := time.sys_mono_now() - start
			assert actual == expected
			if iteration > 0 {
				gpu_ns += elapsed
				cpu_ns += cpu_elapsed
			}
		}
		println('n=${n} cpu_us=${f64(cpu_ns) / 5000.0:.2f} opencl_us=${f64(gpu_ns) / 5000.0:.2f}')
	}
}
