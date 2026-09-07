module opencl

// DeviceCapabilities is a snapshot of optional extension support advertised by
// one OpenCL device. Feature booleans never imply that extension entry points
// have been loaded successfully; command wrappers still report native errors.
pub struct DeviceCapabilities {
pub:
	device                       DeviceId
	extensions                   []string
	device_uuid                  bool
	external_memory              bool
	external_memory_opaque_fd    bool
	external_memory_dma_buf      bool
	semaphore                    bool
	external_semaphore           bool
	external_semaphore_opaque_fd bool
	semaphore_sync_fd            bool
}

// has reports exact extension-name support without substring matching.
pub fn (capabilities DeviceCapabilities) has(name string) bool {
	return name in capabilities.extensions
}

// has_all reports whether every required extension is advertised.
pub fn (capabilities DeviceCapabilities) has_all(required []string) bool {
	for name in required {
		if !capabilities.has(name) {
			return false
		}
	}
	return true
}

// device_capabilities queries and parses the device extension string once.
pub fn device_capabilities(device DeviceId) !DeviceCapabilities {
	extensions := device_info_string(device, device_extensions)!.fields()
	return DeviceCapabilities{
		device: device
		extensions: extensions
		device_uuid: 'cl_khr_device_uuid' in extensions
		external_memory: 'cl_khr_external_memory' in extensions
		external_memory_opaque_fd: 'cl_khr_external_memory_opaque_fd' in extensions
		external_memory_dma_buf: 'cl_khr_external_memory_dma_buf' in extensions
		semaphore: 'cl_khr_semaphore' in extensions
		external_semaphore: 'cl_khr_external_semaphore' in extensions
		external_semaphore_opaque_fd: 'cl_khr_external_semaphore_opaque_fd' in extensions
		semaphore_sync_fd: 'cl_khr_external_semaphore_sync_fd' in extensions
	}
}

// uuid returns the stable device UUID exposed by cl_khr_device_uuid.
pub fn (capabilities DeviceCapabilities) uuid() ![16]u8 {
	if !capabilities.device_uuid {
		return OpenCLError{
			operation: 'query OpenCL device UUID without cl_khr_device_uuid'
			status: invalid_operation
		}
	}
	mut uuid := [16]u8{}
	check(get_device_info(capabilities.device, device_uuid_khr, usize(uuid_size_khr), &uuid[0], unsafe { nil }), 'query OpenCL device UUID')!
	return uuid
}

// driver_uuid returns the driver UUID exposed by cl_khr_device_uuid.
pub fn (capabilities DeviceCapabilities) driver_uuid() ![16]u8 {
	if !capabilities.device_uuid {
		return OpenCLError{
			operation: 'query OpenCL driver UUID without cl_khr_device_uuid'
			status: invalid_operation
		}
	}
	mut uuid := [16]u8{}
	check(get_device_info(capabilities.device, driver_uuid_khr, usize(uuid_size_khr), &uuid[0], unsafe { nil }), 'query OpenCL driver UUID')!
	return uuid
}
