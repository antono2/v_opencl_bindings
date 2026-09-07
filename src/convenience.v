module opencl

// OpenCLError preserves the native OpenCL status code and the operation that failed.
pub struct OpenCLError {
	Error
pub:
	operation string
	status    ErrorCode
}

pub fn (err OpenCLError) msg() string {
	return '${err.operation}: ${error_code_name(err.status)} (${err.status})'
}

pub fn (err OpenCLError) code() int {
	return int(err.status)
}

// check converts an OpenCL status code to V's result-style error handling.
pub fn check(status ErrorCode, operation string) ! {
	if status != success {
		return OpenCLError{
			operation: operation
			status: status
		}
	}
}

// error_code_name returns the registry name for common OpenCL status codes.
pub fn error_code_name(status ErrorCode) string {
	return match status {
		success { 'success' }
		device_not_found { 'device_not_found' }
		device_not_available { 'device_not_available' }
		compiler_not_available { 'compiler_not_available' }
		mem_object_allocation_failure { 'mem_object_allocation_failure' }
		out_of_resources { 'out_of_resources' }
		out_of_host_memory { 'out_of_host_memory' }
		build_program_failure { 'build_program_failure' }
		invalid_value { 'invalid_value' }
		invalid_platform { 'invalid_platform' }
		invalid_device { 'invalid_device' }
		invalid_context { 'invalid_context' }
		invalid_operation { 'invalid_operation' }
		platform_not_found_khr { 'platform_not_found_khr' }
		else { 'opencl_error' }
	}
}

// platforms enumerates every platform exposed by the installed ICD loader.
pub fn platforms() ![]PlatformId {
	mut count := u32(0)
	status := get_platform_ids(0, unsafe { nil }, &count)
	if status == platform_not_found_khr {
		return []
	}
	check(status, 'enumerate OpenCL platforms')!
	if count == 0 {
		return []
	}
	mut result := unsafe { []PlatformId{len: int(count)} }
	check(get_platform_ids(count, result.data, &count), 'enumerate OpenCL platforms')!
	return result[..int(count)].clone()
}

// devices enumerates devices of the requested type for one platform.
pub fn devices(platform PlatformId, device_kind DeviceType) ![]DeviceId {
	mut count := u32(0)
	status := get_device_ids(platform, device_kind, 0, unsafe { nil }, &count)
	if status == device_not_found {
		return []
	}
	check(status, 'enumerate OpenCL devices')!
	if count == 0 {
		return []
	}
	mut result := unsafe { []DeviceId{len: int(count)} }
	check(get_device_ids(platform, device_kind, count, result.data, &count), 'enumerate OpenCL devices')!
	return result[..int(count)].clone()
}

// platform_info_string reads a NUL-terminated platform string safely.
pub fn platform_info_string(platform PlatformId, parameter PlatformInfo) !string {
	mut size := usize(0)
	check(get_platform_info(platform, parameter, 0, unsafe { nil }, &size), 'query OpenCL platform string size')!
	if size == 0 {
		return ''
	}
	mut bytes := []u8{len: int(size)}
	check(get_platform_info(platform, parameter, size, bytes.data, unsafe { nil }), 'read OpenCL platform string')!
	length := if bytes.last() == 0 { bytes.len - 1 } else { bytes.len }
	return bytes[..length].bytestr()
}

// device_info_string reads a NUL-terminated device string safely.
pub fn device_info_string(device DeviceId, parameter DeviceInfo) !string {
	mut size := usize(0)
	check(get_device_info(device, parameter, 0, unsafe { nil }, &size), 'query OpenCL device string size')!
	if size == 0 {
		return ''
	}
	mut bytes := []u8{len: int(size)}
	check(get_device_info(device, parameter, size, bytes.data, unsafe { nil }), 'read OpenCL device string')!
	length := if bytes.last() == 0 { bytes.len - 1 } else { bytes.len }
	return bytes[..length].bytestr()
}
