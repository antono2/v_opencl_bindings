// Device selection and a small explicit owner for an in-order compute session.
module opencl

pub struct DeviceRequirements {
pub:
	required_uuid         ?[16]u8
	preferred_types       []DeviceType = [device_type_gpu, device_type_cpu]
	required_extensions   []string
	minimum_global_memory u64
	require_compiler      bool = true
}

pub struct DeviceSummary {
pub:
	queue_properties    CommandQueueProperties
	platform            PlatformId
	device              DeviceId
	name                string
	vendor              string
	driver              string
	kind                DeviceType
	global_memory       u64
	max_allocation      u64
	max_work_group_size usize
	available           bool
	compiler_available  bool
	capabilities        DeviceCapabilities
}

fn device_scalar[T](device DeviceId, parameter DeviceInfo) !T {
	mut value := T{}
	check(get_device_info(device, parameter, sizeof(T), &value, unsafe { nil }),
		'query OpenCL device limit')!
	return value
}

pub fn device_summary(platform PlatformId, device DeviceId) !DeviceSummary {
	return DeviceSummary{
		queue_properties:    device_scalar[CommandQueueProperties](device, device_queue_properties)!
		platform:            platform
		device:              device
		name:                device_info_string(device, device_name)!
		vendor:              device_info_string(device, device_vendor)!
		driver:              device_info_string(device, driver_version)!
		kind:                device_scalar[DeviceType](device, device_type)!
		global_memory:       device_scalar[u64](device, device_global_mem_size)!
		max_allocation:      device_scalar[u64](device, device_max_mem_alloc_size)!
		max_work_group_size: device_scalar[usize](device, device_max_work_group_size)!
		available:           device_scalar[Bool](device, device_available)! != 0
		compiler_available:  device_scalar[Bool](device, device_compiler_available)! != 0
		capabilities:        device_capabilities(device)!
	}
}

pub struct DeviceCandidate {
pub:
	summary   DeviceSummary
	rejection string
}

// candidates reports every enumerated device, including why requirements reject it.
// Native query failures are returned rather than silently treated as absent devices.
pub fn device_candidates(requirements DeviceRequirements) ![]DeviceCandidate {
	mut result := []DeviceCandidate{}
	for platform in platforms()! {
		for device in devices(platform, device_type_all)! {
			summary := device_summary(platform, device)!
			mut reasons := []string{}
			mut eligible_type := false
			for kind in requirements.preferred_types {
				if summary.kind & kind != 0 { eligible_type = true }
			}
			if !eligible_type { reasons << 'type not requested' }
			if !summary.available { reasons << 'device unavailable' }
			if requirements.require_compiler && !summary.compiler_available {
				reasons << 'source compiler unavailable'
			}
			if summary.global_memory < requirements.minimum_global_memory {
				reasons << 'insufficient global memory'
			}
			for extension in requirements.required_extensions {
				if !summary.capabilities.has(extension) { reasons << 'missing ${extension}' }
			}
			if uuid := requirements.required_uuid {
				if !summary.capabilities.device_uuid {
					reasons << 'device UUID unavailable'
				} else if summary.capabilities.uuid()! != uuid {
					reasons << 'device UUID mismatch'
				}
			}
			result << DeviceCandidate{
				summary:   summary
				rejection: reasons.join('; ')
			}
		}
	}
	return result
}

// Only listed types are eligible: [gpu] explicitly disables CPU fallback.
pub fn select_device(requirements DeviceRequirements) !DeviceSummary {
	candidates := device_candidates(requirements)!
	for kind in requirements.preferred_types {
		for candidate in candidates {
			if candidate.rejection == '' && candidate.summary.kind & kind != 0 {
				return candidate.summary
			}
		}
	}
	mut reasons := []string{}
	for candidate in candidates {
		reasons << '${candidate.summary.name}: ${if candidate.rejection == '' {
			'type not requested'
		} else {
			candidate.rejection
		}}'
	}
	return error('no suitable OpenCL device: ${if reasons.len == 0 {
		'no devices enumerated'
	} else {
		reasons.join('; ')
	}}')
}

pub struct SessionOptions {
pub:
	requirements DeviceRequirements
	profiling    bool
}

@[nocopy]
pub struct Session {
pub:
	device DeviceSummary
pub mut:
	context &OwnedContext
	queue   &OwnedCommandQueue
}

pub fn new_session(options SessionOptions) !&Session {
	selected := select_device(options.requirements)!
	return new_session_on(selected, options.profiling)
}

pub fn new_session_on(device DeviceSummary, profiling bool) !&Session {
	mut context := new_context(device.device)!
	queue := context.command_queue(device.device, if profiling {
		queue_profiling_enable
	} else {
		CommandQueueProperties(0)
	}) or {
		context.close() or {}
		return err
	}
	return &Session{
		device:  device
		context: context
		queue:   queue
	}
}

// Close application-owned children first. finish is explicit; close is not a wait.
pub fn (mut session Session) close() ! {
	session.queue.close()!
	session.context.close()!
}

pub fn (queue &OwnedCommandQueue) finish() ! {
	check(finish(queue.handle), 'finish OpenCL queue')!
}

pub fn buffer_from_slice[T](context &OwnedContext, queue &OwnedCommandQueue, flags MemFlags, values []T) !&Buffer[T] {
	mut buffer := new_buffer[T](context, flags, values.len)!
	buffer.write(queue, 0, values) or {
		buffer.close() or {}
		return err
	}
	return buffer
}
