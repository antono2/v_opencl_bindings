module main

import antono2.opencl as cl
import antono2.opencl.algorithms

fn test_session_buffers_transfers_and_binary_cache() ! {
	mut session := cl.new_session(cl.SessionOptions{ profiling: true })!
	defer { session.close() or {} }
	assert session.device.available
	assert session.device.max_work_group_size > 0
	rejected := cl.device_candidates(cl.DeviceRequirements{
		required_extensions: [
			'cl_test_nonexistent_extension',
		]
	})!
	assert rejected.len > 0
	for candidate in rejected {
		assert candidate.rejection.contains('cl_test_nonexistent_extension')
	}
	mut scratch := cl.new_scratch_buffer[u32](session.context, cl.mem_read_write)!
	defer { scratch.close() or {} }
	scratch.reserve(0)!
	assert scratch.buffer == none
	scratch.reserve(4)!
	first := scratch.buffer or { return error('expected buffer') }
	first.write(session.queue, 0, [u32(2), 4, 6, 8])!
	scratch.reserve(2)!
	reused := scratch.buffer or { return error('expected buffer') }
	assert first.handle == reused.handle
	mut rejected_growth := false
	scratch.reserve(-1) or {
		rejected_growth = true
		assert err.msg().contains('negative')
	}
	assert rejected_growth
	mut grown := scratch.reserve_preserving(session.queue, 8, [])!
	defer { grown.close() or {} }
	grown.wait()!
	buffer := scratch.buffer or { return error('expected replacement') }
	mut result := []u32{len: 4}
	buffer.read(session.queue, 0, mut result)!
	assert result == [u32(2), 4, 6, 8]
	mut fill := buffer.fill(session.queue, u32(9), 4, 4, [])!
	defer { fill.close() or {} }
	mut download := buffer.download_owned(session.queue, 4, 4, [fill.handle])!
	defer { download.close() or {} }
	assert download.values()! == [u32(9), 9, 9, 9]
	mut original := [u32(1), 3, 5, 7]
	mut upload := buffer.upload_owned(session.queue, 0, original, [])!
	defer { upload.close() or {} }
	original[0] = 99
	mut copied := buffer.download_owned(session.queue, 0, 4, [
		upload.event(),
	])!
	defer { copied.close() or {} }
	assert copied.values()! == [u32(1), 3, 5, 7]
	mut rejected_copy := false
	buffer.copy_to(session.queue, buffer, 0, 1, 2, []) or {
		rejected_copy = true
		assert err.msg().contains('overlap')
	}
	assert rejected_copy
	source := '__kernel void add(__global uint *x) { x[get_global_id(0)] += 1; }'
	built :=
		cl.build_cached_program(session.context, session.device, source, '', cl.ProgramBinary{})!
	mut program := built.program
	defer { program.close() or {} }
	assert !built.cache_hit
	blob := cl.ProgramBinary{
		key:  cl.program_cache_key(session.device, source, '')
		data: program.binary()!
	}
	cached := cl.build_cached_program(session.context, session.device, source, '', blob)!
	mut restored := cached.program
	defer { restored.close() or {} }
	assert cached.cache_hit
	mut kernel := restored.kernel('add')!
	defer { kernel.close() or {} }
	assert kernel.work_group_info(session.device.device)!.max_size > 0
	kernel.set_buffer_arg(0, buffer.handle)!
	kernel.enqueue_1d(session.queue, 4, 0)!
	buffer.read(session.queue, 0, mut result)!
	assert result == [u32(2), 4, 6, 8]
	fallback := cl.build_cached_program(session.context, session.device, source, '', cl.ProgramBinary{
		key:  blob.key
		data: [u8(0), 1, 2, 3]
	})!
	mut recovered := fallback.program
	defer { recovered.close() or {} }
	assert !fallback.cache_hit && fallback.fallback_reason != ''
	changed := source.replace('+= 1', '+= 2')
	rebuilt := cl.build_cached_program(session.context, session.device, changed, '', blob)!
	mut changed_program := rebuilt.program
	defer { changed_program.close() or {} }
	assert !rebuilt.cache_hit
	mut changed_kernel := changed_program.kernel('add')!
	defer { changed_kernel.close() or {} }
	changed_kernel.set_buffer_arg(0, buffer.handle)!
	changed_kernel.enqueue_1d(session.queue, 4, 0)!
	buffer.read(session.queue, 0, mut result)!
	assert result == [u32(4), 6, 8, 10]
}

fn test_scan_and_stable_compaction_match_cpu() ! {
	mut session := cl.new_session(cl.SessionOptions{})!
	defer { session.close() or {} }
	mut workspace :=
		algorithms.new_workspace(session.context, session.queue, session.device.device)!
	defer { workspace.close() or {} }
	for n in [0, 1, 2, 3, 31, 32, 33, 257, 513] {
		for pattern in 0 .. 3 {
			capacity := if n == 0 { 1 } else { n }
			mut values := []u32{len: capacity}
			mut expected := []u32{}
			mut prefix := []u32{}
			mut sum := u32(0)
			for i in 0 .. n {
				values[i] = match pattern {
					0 {
						u32(0)
					}
					1 {
						u32(1)
					}
					else {
						if i % 3 == 0 { u32(7) } else { u32(0) }
					}
				}

				sum += values[i]
				prefix << sum
				if values[i] != 0 { expected << u32(i) }
			}
			mut input := cl.buffer_from_slice[u32](session.context, session.queue,
				cl.mem_read_only, values)!
			mut output := cl.new_buffer[u32](session.context, cl.mem_read_write, capacity)!
			mut count := cl.new_buffer[u32](session.context, cl.mem_read_write, 1)!
			mut scanned := workspace.inclusive_scan(input, output, n, [])!
			scanned.wait()!
			mut actual := []u32{len: n}
			output.read(session.queue, 0, mut actual)!
			assert actual == prefix
			mut compacted := workspace.compact_indices(input, output, count, n, [])!
			compacted.wait()!
			mut selected := [u32(999)]
			count.read(session.queue, 0, mut selected)!
			assert selected[0] == u32(expected.len)
			mut indices := []u32{len: expected.len}
			output.read(session.queue, 0, mut indices)!
			assert indices == expected
			mut rejected_alias := false
			workspace.inclusive_scan(input, input, n, []) or {
				rejected_alias = true
				assert err.msg().contains('distinct')
			}
			assert rejected_alias
			mut rejected_capacity := false
			workspace.compact_indices(input, output, count, capacity + 1, []) or {
				rejected_capacity = true
				assert err.msg().contains('capacity')
			}
			assert rejected_capacity
			compacted.close()!
			scanned.close()!
			count.close()!
			output.close()!
			input.close()!
		}
	}
}

fn test_workspace_serializes_out_of_order_queue_and_wraps_unsigned_scan() ! {
	mut session := cl.new_session(cl.SessionOptions{})!
	defer { session.close() or {} }
	if session.device.queue_properties & cl.queue_out_of_order_exec_mode_enable == 0 { return }
	mut queue := session.context.command_queue(session.device.device,
		cl.queue_out_of_order_exec_mode_enable)!
	defer { queue.close() or {} }
	mut workspace := algorithms.new_workspace(session.context, queue, session.device.device)!
	defer { workspace.close() or {} }
	mut input := cl.buffer_from_slice[u32](session.context, queue, cl.mem_read_only, [
		~u32(0),
		1,
		2,
	])!
	defer { input.close() or {} }
	mut output := cl.new_buffer[u32](session.context, cl.mem_read_write, 3)!
	defer { output.close() or {} }
	mut count := cl.new_buffer[u32](session.context, cl.mem_read_write, 1)!
	defer { count.close() or {} }
	mut scanned := workspace.inclusive_scan(input, output, 3, [])!
	defer { scanned.close() or {} }
	scanned.wait()!
	mut actual := []u32{len: 3}
	output.read(queue, 0, mut actual)!
	assert actual == [~u32(0), 0, 2]
	mut compacted := workspace.compact_indices(input, output, count, 3, [])!
	defer { compacted.close() or {} }
	mut empty := workspace.compact_indices(input, output, count, 0, [])!
	defer { empty.close() or {} }
	empty.wait()!
	mut selected := [u32(999)]
	count.read(queue, 0, mut selected)!
	assert selected == [u32(0)]
}
