// Device-specific program binaries with caller-controlled storage and source fallback.
module opencl

import crypto.sha256

pub struct ProgramBinary {
pub:
	key  string
	data []u8
}

pub struct CachedProgram {
pub:
	program         &OwnedProgram
	cache_hit       bool
	fallback_reason string
}

pub fn program_cache_key(device DeviceSummary, source string, options string) string {
	mut identity := 'antono2.opencl.binary.v1:'
	for part in [device.vendor, device.name, device.driver, source, options] {
		identity += '${part.len}:${part}'
	}
	return sha256.hexhash(identity)
}

// binary returns the binary for this single-device owned program.
pub fn (program &OwnedProgram) binary() ![]u8 {
	mut count := u32(0)
	check(get_program_info(program.handle, program_num_devices, sizeof(count), &count,
		unsafe { nil }), 'query program device count')!
	if count != 1 { return error('binary helper requires a single-device program') }
	mut size := usize(0)
	check(get_program_info(program.handle, program_binary_sizes, sizeof(size), &size,
		unsafe { nil }), 'query program binary size')!
	if size == 0 || size > usize(max_int) { return error('invalid program binary size') }
	mut data := []u8{len: int(size)}
	pointer := &u8(data.data)
	check(get_program_info(program.handle, program_binaries, sizeof(pointer), &pointer,
		unsafe { nil }), 'read program binary')!
	return data
}

pub fn build_binary_program(context &OwnedContext, device DeviceId, data []u8, options string) !&OwnedProgram {
	if data.len == 0 { return error('program binary is empty') }
	size := usize(data.len)
	pointer := &u8(data.data)
	mut status := success
	mut binary_status := success
	handle := create_program_with_binary(context.handle, 1, &device, &size, &pointer,
		&binary_status, &status)
	check(status, 'create binary program')!
	mut keep := false
	defer {
		if !keep && !isnil(handle) { release_program(handle) }
	}
	check(binary_status, 'load program binary')!
	if isnil(handle) { return error('OpenCL returned a null binary program') }
	mut option_pointer := &char(unsafe { nil })
	if options != '' { option_pointer = options.str }
	status = build_program(handle, 1, &device, option_pointer, unsafe { nil }, unsafe { nil })
	if status != success { return ProgramBuildError{
			status: status
			log:    read_program_build_log(handle, device)
		} }
	keep = true
	return &OwnedProgram{
		handle: handle
		device: device
	}
}

// Callers persist both key and bytes. A mismatch or rejected binary rebuilds
// from source and reports why; source compilation errors remain visible.
pub fn build_cached_program(context &OwnedContext, device DeviceSummary, source string, options string, cached ProgramBinary) !CachedProgram {
	mut reason := 'cache key mismatch or no cached binary'
	if cached.key == program_cache_key(device, source, options) && cached.data.len > 0 {
		program := build_binary_program(context, device.device, cached.data, options) or {
			reason = err.msg()
			return CachedProgram{
				program:         build_source_program(context, device.device, source, options)!
				fallback_reason: reason
			}
		}
		return CachedProgram{
			program:   program
			cache_hit: true
		}
	}
	return CachedProgram{
		program:         build_source_program(context, device.device, source, options)!
		fallback_reason: reason
	}
}
