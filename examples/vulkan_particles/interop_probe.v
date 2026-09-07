module main

import antono2.opencl as cl
import antono2.vulkan as vk

struct InteropReport {
mut:
	opencl_device       string
	vulkan_device       string
	uuid_match          bool
	opencl_external     bool
	vulkan_external     bool
	semaphore_external  bool
	zero_copy_available bool
	reason              string
}

fn (report InteropReport) describe() string {
	mode := if report.zero_copy_available { 'zero-copy' } else { 'staged fallback' }
	return '${mode}: ${report.reason}'
}

fn probe_interop(cl_device cl.DeviceId) InteropReport {
	cl_name := cl_info_string(cl_device, cl.device_name)
	capabilities := cl.device_capabilities(cl_device) or { cl.DeviceCapabilities{ device: cl_device } }
	cl_memory := capabilities.has_all(['cl_khr_external_memory', 'cl_khr_external_memory_opaque_fd'])
	cl_semaphore := capabilities.has_all(['cl_khr_semaphore', 'cl_khr_external_semaphore',
		'cl_khr_external_semaphore_opaque_fd'])
	cl_uuid, cl_has_uuid := opencl_uuid(capabilities)
	if vk.initialize_loader() != vk.Result.success {
		return InteropReport{
			opencl_device: cl_name
			reason: 'Vulkan loader initialization failed'
		}
	}

	mut instance := vk.Instance(unsafe { nil })
	app_info := vk.ApplicationInfo{
		pApplicationName: c'V OpenCL particle interop probe'
		applicationVersion: 1
		pEngineName: c'none'
		engineVersion: 1
		apiVersion: vk.api_version_1_1
	}
	create_info := vk.InstanceCreateInfo{
		pApplicationInfo: &app_info
	}
	if vk.create_instance(&create_info, unsafe { nil }, &instance) != vk.Result.success {
		return InteropReport{
			opencl_device: cl_name
			reason: 'Vulkan instance creation failed'
		}
	}
	vk.load_instance_commands(instance)
	defer {
		vk.destroy_instance(instance, unsafe { nil })
	}

	mut count := u32(0)
	if vk.enumerate_physical_devices(instance, &count, unsafe { nil }) != vk.Result.success
		|| count == 0 {
		return InteropReport{
			opencl_device: cl_name
			reason: 'no Vulkan physical devices found'
		}
	}
	mut devices := unsafe { []vk.PhysicalDevice{len: int(count)} }
	if vk.enumerate_physical_devices(instance, &count, devices.data) != vk.Result.success {
		return InteropReport{
			opencl_device: cl_name
			reason: 'Vulkan device enumeration failed'
		}
	}

	mut fallback := InteropReport{
		opencl_device: cl_name
		vulkan_device: 'unknown'
		opencl_external: cl_memory && cl_semaphore
		reason: if !cl_has_uuid {
			'OpenCL device does not advertise cl_khr_device_uuid'
		} else {
			'no Vulkan device UUID matches the OpenCL device'
		}
	}
	for device in devices {
		mut id := vk.PhysicalDeviceIDProperties{}
		mut properties := vk.PhysicalDeviceProperties2{
			pNext: &id
		}
		vk.get_physical_device_properties2(device, mut properties)
		name := unsafe { cstring_to_vstring(&char(&properties.properties.deviceName)) }
		if fallback.vulkan_device == 'unknown' {
			fallback.vulkan_device = name
		}
		matched := cl_has_uuid && uuid_equal(cl_uuid, unsafe { &u8(&id.deviceUUID) })
		if !matched {
			continue
		}

		memory_ok := vulkan_buffer_exportable(device)
		semaphore_ok := vulkan_semaphore_exportable(device)
		available := cl_memory && cl_semaphore && memory_ok && semaphore_ok
		mut reason := 'matching devices support opaque-FD memory and semaphore exchange'
		if !cl_memory {
			reason = 'OpenCL device lacks opaque-FD external-memory support'
		} else if !cl_semaphore {
			reason = 'OpenCL device lacks opaque-FD external-semaphore support'
		} else if !memory_ok {
			reason = 'Vulkan device cannot export an opaque-FD particle buffer'
		} else if !semaphore_ok {
			reason = 'Vulkan device cannot export an opaque-FD semaphore'
		}
		return InteropReport{
			opencl_device: cl_name
			vulkan_device: name
			uuid_match: true
			opencl_external: cl_memory && cl_semaphore
			vulkan_external: memory_ok
			semaphore_external: semaphore_ok
			zero_copy_available: available
			reason: reason
		}
	}
	return fallback
}

fn opencl_uuid(capabilities cl.DeviceCapabilities) ([16]u8, bool) {
	mut uuid := [16]u8{}
	if !capabilities.device_uuid {
		return uuid, false
	}
	uuid = capabilities.uuid() or {
		return uuid, false
	}
	return uuid, true
}

fn uuid_equal(left [16]u8, right &u8) bool {
	for index in 0 .. 16 {
		if left[index] != unsafe { right[index] } {
			return false
		}
	}
	return true
}

fn vulkan_buffer_exportable(device vk.PhysicalDevice) bool {
	info := vk.PhysicalDeviceExternalBufferInfo{
		usage: vk.BufferUsageFlags(u32(vk.BufferUsageFlagBits.vertex_buffer) | u32(vk.BufferUsageFlagBits.storage_buffer))
		handleType: .opaque_fd
	}
	mut properties := vk.ExternalBufferProperties{}
	vk.get_physical_device_external_buffer_properties(device, &info, mut properties)
	features := properties.externalMemoryProperties.externalMemoryFeatures
	return features & u32(vk.ExternalMemoryFeatureFlagBits.exportable) != 0
}

fn vulkan_semaphore_exportable(device vk.PhysicalDevice) bool {
	info := vk.PhysicalDeviceExternalSemaphoreInfo{
		handleType: .opaque_fd
	}
	mut properties := vk.ExternalSemaphoreProperties{}
	vk.get_physical_device_external_semaphore_properties(device, &info, mut properties)
	return properties.externalSemaphoreFeatures & u32(vk.ExternalSemaphoreFeatureFlagBits.exportable) != 0
}
