// Reusable capacity and device-side transfers. All sizes and offsets are elements.
module opencl

@[nocopy]
pub struct ScratchBuffer[T] {
mut:
	context &OwnedContext
	flags   MemFlags
	storage &Buffer[T] = unsafe { &Buffer[T](nil) }
}

pub fn new_scratch_buffer[T](context &OwnedContext, flags MemFlags) !&ScratchBuffer[T] {
	return &ScratchBuffer[T]{
		context: context.clone_ref()!
		flags:   flags
	}
}

// reserve discards old contents only after replacement allocation succeeds.
// Existing cloned references remain valid. Rebind kernel arguments after growth.
// Zero requests do nothing; obtain borrowed storage through buffer().
pub fn (mut scratch ScratchBuffer[T]) reserve(count int) ! {
	if count < 0 {
		return error('scratch capacity must not be negative')
	}
	if count == 0 {
		return
	}
	if !isnil(scratch.storage) {
		current := scratch.storage
		if current.count >= count {
			return
		}
	}
	mut replacement := new_buffer[T](scratch.context, scratch.flags, count)!
	if !isnil(scratch.storage) {
		mut previous := scratch.storage
		previous.close() or {
			replacement.close() or {}
			return err
		}
	}
	scratch.storage = replacement
}

pub fn (mut scratch ScratchBuffer[T]) close() ! {
	if !isnil(scratch.storage) { scratch.storage.close()! }
	scratch.storage = unsafe { nil }
	scratch.context.close()!
}

pub fn (source &Buffer[T]) copy_to(queue &OwnedCommandQueue, destination &Buffer[T], source_offset int, destination_offset int, count int, wait_events []Event) !&OwnedEvent {
	source.validate_transfer(queue, source_offset, count, 'copy source')!
	destination.validate_transfer(queue, destination_offset, count, 'copy destination')!
	if count == 0 {
		return queue.marker(wait_events)
	}
	if source.handle == destination.handle && source_offset < destination_offset + count
		&& destination_offset < source_offset + count {
		return error('OpenCL buffer copy ranges overlap')
	}
	mut event := Event(unsafe { nil })
	mut waits := &Event(unsafe { nil })
	if wait_events.len > 0 { waits = wait_events.data }
	check(enqueue_copy_buffer(queue.handle, source.handle, destination.handle, checked_element_bytes[T](source_offset,
		'copy source offset')!, checked_element_bytes[T](destination_offset,
		'copy destination offset')!, checked_element_bytes[T](count, 'copy count')!,
		u32(wait_events.len), waits, &event), 'copy OpenCL buffer')!
	return &OwnedEvent{
		handle: event
	}
}

// fill requires OpenCL 1.2 and a power-of-two pattern size no greater than 128 bytes.
pub fn (buffer &Buffer[T]) fill(queue &OwnedCommandQueue, value T, offset int, count int, wait_events []Event) !&OwnedEvent {
	buffer.validate_transfer(queue, offset, count, 'fill')!
	if count == 0 {
		return queue.marker(wait_events)
	}
	size := usize(sizeof(T))
	if size == 0 || size > 128 || size & (size - 1) != 0 {
		return error('invalid OpenCL fill pattern size')
	}
	mut event := Event(unsafe { nil })
	mut waits := &Event(unsafe { nil })
	if wait_events.len > 0 { waits = wait_events.data }
	check(enqueue_fill_buffer(queue.handle, buffer.handle, &value, size, checked_element_bytes[T](offset,
		'fill offset')!, checked_element_bytes[T](count, 'fill count')!, u32(wait_events.len),
		waits, &event), 'fill OpenCL buffer')!
	return &OwnedEvent{
		handle: event
	}
}

pub struct WorkGroupLimits {
pub:
	max_size           usize
	preferred_multiple usize
	local_memory       u64
	compile_size       [3]usize
}

pub fn (kernel &OwnedKernel) work_group_info(device DeviceId) !WorkGroupLimits {
	mut max_size := usize(0)
	mut multiple := usize(0)
	mut local_memory := u64(0)
	mut compile_size := [3]usize{}
	check(get_kernel_work_group_info(kernel.handle, device, kernel_work_group_size,
		sizeof(max_size), &max_size, unsafe { nil }), 'query kernel work-group size')!
	check(get_kernel_work_group_info(kernel.handle, device,
		kernel_preferred_work_group_size_multiple, sizeof(multiple), &multiple, unsafe { nil }),
		'query kernel preferred multiple')!
	check(get_kernel_work_group_info(kernel.handle, device, kernel_local_mem_size,
		sizeof(local_memory), &local_memory, unsafe { nil }), 'query kernel local memory')!
	check(get_kernel_work_group_info(kernel.handle, device, kernel_compile_work_group_size,
		sizeof(compile_size), &compile_size[0], unsafe { nil }), 'query kernel compile dimensions')!
	return WorkGroupLimits{
		max_size:           max_size
		preferred_multiple: multiple
		local_memory:       local_memory
		compile_size:       compile_size
	}
}

pub fn (kernel &OwnedKernel) set_local_arg(index u32, bytes usize) ! {
	if bytes == 0 {
		return error('local argument size must be positive')
	}
	check(set_kernel_arg(kernel.handle, index, bytes, unsafe { nil }),
		'set kernel local memory argument')!
}

// reserve_preserving copies existing elements on growth, respecting waits.
// The returned event must complete before the replacement contents are used.
pub fn (mut scratch ScratchBuffer[T]) reserve_preserving(queue &OwnedCommandQueue, count int, waits []Event) !&OwnedEvent {
	if count < 0 { return error('scratch capacity must not be negative') }
	if !isnil(scratch.storage) {
		mut previous := scratch.storage
		if previous.count >= count { return queue.marker(waits) }
		mut replacement := new_buffer[T](scratch.context, scratch.flags, count)!
		mut event := previous.copy_to(queue, replacement, 0, 0, previous.count, waits) or {
			replacement.close() or {}
			return err
		}
		previous.close() or {
			event.close() or {}
			replacement.close() or {}
			return err
		}
		scratch.storage = replacement
		return event
	}
	scratch.reserve(count)!
	return queue.marker(waits)
}

// buffer returns borrowed storage; reserve positive capacity before accessing it.
pub fn (scratch &ScratchBuffer[T]) buffer() !&Buffer[T] {
	if isnil(scratch.storage) { return error('scratch buffer has no allocation') }
	return scratch.storage
}
