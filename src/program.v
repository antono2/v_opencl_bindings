module opencl

// ProgramBuildError includes the compiler log returned for the selected device.
pub struct ProgramBuildError {
	Error
pub:
	status ErrorCode
	log    string
}

pub fn (err ProgramBuildError) msg() string {
	return if err.log.len > 0 {
		'build OpenCL program: ${error_code_name(err.status)} (${err.status})\n${err.log}'
	} else {
		'build OpenCL program: ${error_code_name(err.status)} (${err.status})'
	}
}

pub fn (err ProgramBuildError) code() int {
	return int(err.status)
}

// OwnedProgram owns one compiled OpenCL program reference.
pub struct OwnedProgram {
pub mut:
	handle Program
pub:
	device DeviceId
}

// build_source_program creates and synchronously builds source for one device.
pub fn build_source_program(context &OwnedContext, device DeviceId, source string,
	options string) !OwnedProgram {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'build program from closed OpenCL context'
			status: invalid_context
		}
	}
	pointer := source.str
	length := usize(source.len)
	mut status := success
	handle := create_program_with_source(context.handle, 1, &pointer, &length, &status)
	check(status, 'create OpenCL source program')!
	if isnil(handle) {
		return OpenCLError{
			operation: 'create OpenCL source program'
			status: out_of_host_memory
		}
	}
	mut option_pointer := &char(unsafe { nil })
	if options.len > 0 {
		option_pointer = options.str
	}
	status = build_program(handle, 1, &device, option_pointer, unsafe { nil }, unsafe { nil })
	if status != success {
		log := read_program_build_log(handle, device)
		release_program(handle)
		return ProgramBuildError{
			status: status
			log: log
		}
	}
	return OwnedProgram{
		handle: handle
		device: device
	}
}

// kernel creates an owned kernel by name.
pub fn (program &OwnedProgram) kernel(name string) !OwnedKernel {
	if isnil(program.handle) {
		return OpenCLError{
			operation: 'create kernel from closed OpenCL program'
			status: invalid_program
		}
	}
	mut status := success
	handle := create_kernel(program.handle, name.str, &status)
	check(status, 'create OpenCL kernel `${name}`')!
	return OwnedKernel{
		handle: handle
	}
}

// close releases the owned program reference. Close its kernels first.
pub fn (mut program OwnedProgram) close() ! {
	if isnil(program.handle) {
		return
	}
	check(release_program(program.handle), 'release OpenCL program')!
	program.handle = unsafe { nil }
}

// OwnedKernel owns one OpenCL kernel reference.
pub struct OwnedKernel {
pub mut:
	handle Kernel
}

// set_arg copies one scalar or plain-value argument into the kernel.
pub fn (kernel &OwnedKernel) set_arg[T](index u32, value &T) ! {
	if isnil(kernel.handle) {
		return OpenCLError{
			operation: 'set argument on closed OpenCL kernel'
			status: invalid_kernel
		}
	}
	check(set_kernel_arg(kernel.handle, index, sizeof(T), value), 'set OpenCL kernel argument')!
}

// set_slice_arg copies the contiguous elements of a non-empty slice as one
// by-value kernel argument, for example a two-element f32 slice for float2.
pub fn (kernel &OwnedKernel) set_slice_arg[T](index u32, values []T) ! {
	if isnil(kernel.handle) {
		return OpenCLError{
			operation: 'set argument on closed OpenCL kernel'
			status: invalid_kernel
		}
	}
	if values.len == 0 {
		return OpenCLError{
			operation: 'set empty OpenCL kernel slice argument'
			status: invalid_arg_size
		}
	}
	check(set_kernel_arg(kernel.handle, index, usize(values.len) * sizeof(T), values.data), 'set OpenCL kernel slice argument')!
}

// set_buffer_arg binds an OpenCL memory object, such as Buffer.handle.
pub fn (kernel &OwnedKernel) set_buffer_arg(index u32, buffer Mem) ! {
	if isnil(buffer) {
		return OpenCLError{
			operation: 'bind closed OpenCL buffer to kernel'
			status: invalid_mem_object
		}
	}
	kernel.set_arg(index, &buffer)!
}

// enqueue_1d submits a one-dimensional kernel. A local size of zero lets the runtime choose.
pub fn (kernel &OwnedKernel) enqueue_1d(queue &OwnedCommandQueue, global_size usize,
	local_size usize) ! {
	if isnil(queue.handle) {
		return OpenCLError{
			operation: 'enqueue OpenCL kernel on closed queue'
			status: invalid_command_queue
		}
	}
	if global_size == 0 {
		return OpenCLError{
			operation: 'enqueue OpenCL kernel with zero global size'
			status: invalid_global_work_size
		}
	}
	mut local_pointer := &usize(unsafe { nil })
	mut requested_local_size := local_size
	if local_size > 0 {
		local_pointer = &requested_local_size
	}
	check(enqueue_nd_range_kernel(queue.handle, kernel.handle, 1, unsafe { nil }, &global_size, local_pointer, 0, unsafe { nil }, unsafe { nil }), 'enqueue OpenCL kernel')!
}

// enqueue_1d_after submits a one-dimensional kernel after wait_events and
// returns an owned completion event. A local size of zero lets the runtime choose.
pub fn (kernel &OwnedKernel) enqueue_1d_after(queue &OwnedCommandQueue, global_size usize,
	local_size usize, wait_events []Event) !OwnedEvent {
	local_sizes := if local_size > 0 { [local_size] } else { []usize{} }
	return kernel.enqueue_nd_after(queue, [global_size], local_sizes, wait_events)
}

// enqueue_nd_after submits a one-, two-, or three-dimensional kernel after
// wait_events and returns an owned completion event. An empty local_sizes slice
// lets the runtime select work-group dimensions.
pub fn (kernel &OwnedKernel) enqueue_nd_after(queue &OwnedCommandQueue, global_sizes []usize,
	local_sizes []usize, wait_events []Event) !OwnedEvent {
	if isnil(kernel.handle) {
		return OpenCLError{
			operation: 'enqueue closed OpenCL kernel'
			status: invalid_kernel
		}
	}
	if isnil(queue.handle) {
		return OpenCLError{
			operation: 'enqueue OpenCL kernel on closed queue'
			status: invalid_command_queue
		}
	}
	if global_sizes.len < 1 || global_sizes.len > 3 {
		return OpenCLError{
			operation: 'enqueue OpenCL kernel with invalid work dimension'
			status: invalid_work_dimension
		}
	}
	for size in global_sizes {
		if size == 0 {
			return OpenCLError{
				operation: 'enqueue OpenCL kernel with zero global size'
				status: invalid_global_work_size
			}
		}
	}
	if local_sizes.len != 0 && local_sizes.len != global_sizes.len {
		return OpenCLError{
			operation: 'enqueue OpenCL kernel with mismatched local dimensions'
			status: invalid_work_group_size
		}
	}
	for size in local_sizes {
		if size == 0 {
			return OpenCLError{
				operation: 'enqueue OpenCL kernel with zero local size'
				status: invalid_work_group_size
			}
		}
	}
	mut local_pointer := &usize(unsafe { nil })
	if local_sizes.len > 0 {
		local_pointer = local_sizes.data
	}
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(enqueue_nd_range_kernel(queue.handle, kernel.handle, u32(global_sizes.len), unsafe { nil }, global_sizes.data, local_pointer, u32(wait_events.len), wait_pointer, &event), 'enqueue OpenCL kernel with event')!
	return OwnedEvent{
		handle: event
	}
}

// close releases the owned kernel reference.
pub fn (mut kernel OwnedKernel) close() ! {
	if isnil(kernel.handle) {
		return
	}
	check(release_kernel(kernel.handle), 'release OpenCL kernel')!
	kernel.handle = unsafe { nil }
}

fn read_program_build_log(program Program, device DeviceId) string {
	mut size := usize(0)
	if get_program_build_info(program, device, program_build_log, 0, unsafe { nil }, &size) != success
		|| size == 0 {
		return ''
	}
	mut bytes := []u8{len: int(size)}
	if get_program_build_info(program, device, program_build_log, size, bytes.data, unsafe { nil }) != success {
		return ''
	}
	length := if bytes.last() == 0 { bytes.len - 1 } else { bytes.len }
	return bytes[..length].bytestr()
}
