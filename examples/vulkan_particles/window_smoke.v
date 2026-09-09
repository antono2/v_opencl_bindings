module main

import antono2.glfw
import antono2.opencl as cl
import time
import antono2.vulkan as vk

fn C.glfwGetCursorPos(window &glfw.Window, x &f64, y &f64)

fn C.glfwGetWindowSize(window &glfw.Window, width &i32, height &i32)

fn C.glfwSetWindowTitle(window &glfw.Window, title &char)

const key_r = 82
const key_t = 84

fn cursor_to_particle_position(cursor_x f64, cursor_y f64, window_width i32,
	window_height i32) (f32, f32) {
	if window_width <= 0 || window_height <= 0 {
		return 0, 0
	}
	return f32(cursor_x / f64(window_width) * 2.0 - 1.0), f32(cursor_y / f64(window_height) * 2.0 - 1.0)
}

fn window_device_loop(compute &Compute, particle_count usize, use_zero_copy bool,
	frame_limit int) ! {
	cl_device := compute.device
	if !glfw.initialize() {
		return error('GLFW initialization failed')
	}
	defer { glfw.terminate() }
	if !glfw.vulkan_supported() {
		return error('GLFW cannot find a Vulkan loader')
	}
	glfw.window_hint(glfw.client_api, glfw.no_api)
	window := glfw.create_window(960, 640, 'Vulkan + OpenCL particles', unsafe { nil },
		unsafe { nil })
	if isnil(window) {
		return error('GLFW window creation failed')
	}
	defer { glfw.destroy_window(window) }

	if vk.initialize_loader() != vk.Result.success {
		return error('initialize Vulkan loader')
	}
	mut extension_count := u32(0)
	extensions := glfw.get_required_instance_extensions(&extension_count)
	mut app_info := vk.ApplicationInfo{
		pApplicationName:   c'Vulkan + OpenCL particles'
		applicationVersion: 1
		pEngineName:        c'none'
		apiVersion:         vk.api_version_1_1
	}
	instance_info := vk.InstanceCreateInfo{
		pApplicationInfo:        &app_info
		enabledExtensionCount:   extension_count
		ppEnabledExtensionNames: extensions
	}
	mut instance := vk.Instance(unsafe { nil })
	vk_check(vk.create_instance(&instance_info, unsafe { nil }, &instance),
		'create window instance')!
	defer { vk.destroy_instance(instance, unsafe { nil }) }
	vk.load_instance_commands(instance)
	mut surface := vk.SurfaceKHR(unsafe { nil })
	vk_check(glfw.create_window_surface(instance, window, unsafe { nil }, &surface),
		'create GLFW surface')!
	defer { vk.destroy_surface_khr(instance, surface, unsafe { nil }) }

	cl_capabilities := cl.device_capabilities(cl_device) or {
		cl.DeviceCapabilities{
			device: cl_device
		}
	}
	cl_uuid, has_uuid := opencl_uuid(cl_capabilities)
	physical := if use_zero_copy && has_uuid {
		find_vulkan_device_by_uuid(instance, cl_uuid)!
	} else {
		first_vulkan_device(instance)!
	}
	queue_family := graphics_present_queue_family(physical, surface)!
	mut priority := f32(1)
	mut queue_info := vk.DeviceQueueCreateInfo{
		queueFamilyIndex: queue_family
		queueCount:       1
		pQueuePriorities: &priority
	}
	mut device_extensions := [vk.khr_swapchain_extension_name]
	if use_zero_copy {
		device_extensions << vk.khr_external_memory_extension_name
		device_extensions << vk.khr_external_memory_fd_extension_name
		device_extensions << vk.khr_external_semaphore_extension_name
		device_extensions << vk.khr_external_semaphore_fd_extension_name
	}
	mut supported_features := vk.PhysicalDeviceFeatures{}
	vk.get_physical_device_features(physical, mut supported_features)
	mut enabled_features := vk.PhysicalDeviceFeatures{
		largePoints: supported_features.largePoints
	}
	device_info := vk.DeviceCreateInfo{
		queueCreateInfoCount:    1
		pQueueCreateInfos:       &queue_info
		enabledExtensionCount:   u32(device_extensions.len)
		ppEnabledExtensionNames: device_extensions.data
		pEnabledFeatures:        &enabled_features
	}
	mut device := vk.Device(unsafe { nil })
	vk_check(vk.create_device(physical, &device_info, unsafe { nil }, &device),
		'create window device')!
	vk.load_device_commands(device)
	defer { vk.destroy_device(device, unsafe { nil }) }
	mut queue := vk.Queue(unsafe { nil })
	vk.get_device_queue(device, queue_family, 0, &queue)
	if isnil(queue) {
		return error('graphics queue creation failed')
	}
	mut swapchain := create_swapchain(physical, device, surface, window)!
	defer { swapchain.destroy(device) }
	mut frames := create_frame_resources(device, queue_family, &swapchain)!
	defer { frames.destroy(device) }
	mut pipeline := create_particle_pipeline(device, frames.render_pass, swapchain.extent)!
	defer { pipeline.destroy(device) }
	mut particles := []f32{len: int(particle_count * 8)}
	memory_interop := if use_zero_copy {
		cl.load_external_memory_interop(compute.platform, cl_capabilities)!
	} else {
		cl.ExternalMemoryInterop{}
	}
	semaphore_interop := if use_zero_copy {
		cl.load_external_semaphore_interop(compute.platform, cl_capabilities)!
	} else {
		cl.ExternalSemaphoreInterop{}
	}
	mut particle_buffer := if use_zero_copy {
		create_zero_copy_particle_buffer(compute, memory_interop, physical, device)!
	} else {
		compute.read_particles(mut particles)!
		create_staged_particle_buffer(physical, device, particles)!
	}
	defer { particle_buffer.destroy(device) }
	if particle_buffer.zero_copy {
		mut acquire_event := memory_interop.acquire(&compute.queue, [
			particle_buffer.cl_buffer.handle,
		], [])!
		compute.reset_buffer(particle_buffer.cl_buffer.handle, 1)!
		mut release_event := memory_interop.release(&compute.queue, [
			particle_buffer.cl_buffer.handle,
		], [])!
		release_event.close()!
		acquire_event.close()!
		cl_check(cl.finish(compute.queue.handle), 'finish live particle reset')!
	}
	mut interop_sync := if particle_buffer.zero_copy {
		create_live_interop_sync(compute, memory_interop, semaphore_interop, device, queue)!
	} else {
		LiveInteropSync{}
	}
	if particle_buffer.zero_copy {
		println('Live synchronization: external Vulkan/OpenCL semaphores')
	}
	defer {
		if particle_buffer.zero_copy {
			interop_sync.destroy(device)
		}
	}
	started := time.now()
	mut previous := started
	mut frame_number := 0
	mut paused := false
	mut space_was_down := false
	mut reset_was_down := false
	mut trails := true
	mut trails_was_down := false
	mut title_updated := started
	for !glfw.window_should_close(window) && (frame_limit <= 0 || frame_number < frame_limit) {
		glfw.poll_events()
		if glfw.get_key(window, glfw.key_escape) == glfw.press {
			glfw.set_should_close(window, glfw._true)
		}
		space_down := glfw.get_key(window, glfw.key_space) == glfw.press
		if space_down && !space_was_down {
			paused = !paused
		}
		space_was_down = space_down
		reset_down := glfw.get_key(window, key_r) == glfw.press
		reset_requested := reset_down && !reset_was_down
		reset_was_down = reset_down
		trails_down := glfw.get_key(window, key_t) == glfw.press
		if trails_down && !trails_was_down {
			trails = !trails
		}
		trails_was_down = trails_down
		now := time.now()
		measured_dt := f32(time.since(previous).seconds())
		dt := if measured_dt < 1.0 / 20.0 { measured_dt } else { f32(1.0 / 20.0) }
		elapsed := f32(time.since(started).seconds())
		previous = now
		mut cursor_x := f64(0)
		mut cursor_y := f64(0)
		C.glfwGetCursorPos(window, &cursor_x, &cursor_y)
		mut window_width := i32(0)
		mut window_height := i32(0)
		C.glfwGetWindowSize(window, &window_width, &window_height)
		pointer_x, pointer_y := cursor_to_particle_position(cursor_x, cursor_y, window_width,
			window_height)
		if particle_buffer.zero_copy {
			interop_sync.begin_compute(compute, particle_buffer.cl_buffer.handle)!
			if reset_requested {
				compute.reset_buffer(particle_buffer.cl_buffer.handle, u32(frame_number + 1))!
			} else if !paused {
				compute.update_buffer(particle_buffer.cl_buffer.handle, dt, elapsed, pointer_x,
					pointer_y, 0.11)!
			}
			interop_sync.end_compute(compute, particle_buffer.cl_buffer.handle)!
		} else {
			if reset_requested {
				compute.reset_particles(u32(frame_number + 1))!
			} else if !paused {
				compute.update(dt, elapsed, pointer_x, pointer_y, 0.11)!
			}
			compute.read_particles(mut particles)!
			particle_buffer.upload(device, particles)!
		}
		frame_ok := frames.draw_particles(device, queue, &swapchain, &pipeline, &particle_buffer,
			particle_count, elapsed, interop_sync.cl_to_vk, interop_sync.vk_to_cl,
			particle_buffer.zero_copy, trails)!
		if !frame_ok {
			vk_check(vk.device_wait_idle(device), 'wait to recreate swapchain')!
			pipeline.destroy(device)
			frames.destroy(device)
			swapchain.destroy(device)
			mut width := i32(0)
			mut height := i32(0)
			for width == 0 || height == 0 {
				glfw.get_framebuffer_size(window, &width, &height)
				if width == 0 || height == 0 {
					glfw.poll_events()
					time.sleep(16 * time.millisecond)
				}
			}
			swapchain = create_swapchain(physical, device, surface, window)!
			frames = create_frame_resources(device, queue_family, &swapchain)!
			pipeline = create_particle_pipeline(device, frames.render_pass, swapchain.extent)!
		}
		frame_number++
		if time.since(title_updated) >= time.second {
			seconds := time.since(started).seconds()
			fps := if seconds > 0 { f64(frame_number) / seconds } else { 0.0 }
			state := if paused { 'paused' } else { 'running' }
			backend := if particle_buffer.zero_copy { 'zero-copy' } else { 'staged' }
			trail_state := if trails { 'trails' } else { 'points' }
			title := 'Vulkan + OpenCL particles | ${particle_count} | ${fps:.0f} FPS | ${backend} | ${trail_state} | ${state}'
			C.glfwSetWindowTitle(window, title.str)
			title_updated = now
		}
	}
	cl_check(cl.finish(compute.queue.handle), 'finish particle compute queue')!
	vk_check(vk.device_wait_idle(device), 'finish particle render queue')!
	backend := if particle_buffer.zero_copy { 'zero-copy' } else { 'staged' }
	println('Particle loop: rendered ${frame_number} frames with ${particle_count} particles at ${swapchain.extent.width}x${swapchain.extent.height} (${backend})')
}

fn first_vulkan_device(instance vk.Instance) !vk.PhysicalDevice {
	mut count := u32(0)
	vk_check(vk.enumerate_physical_devices(instance, &count, unsafe { nil }), 'count devices')!
	if count == 0 {
		return error('no Vulkan physical devices')
	}
	mut devices := unsafe { []vk.PhysicalDevice{len: int(count)} }
	vk_check(vk.enumerate_physical_devices(instance, &count, devices.data), 'enumerate devices')!
	return devices[0]
}

fn graphics_present_queue_family(device vk.PhysicalDevice, surface vk.SurfaceKHR) !u32 {
	mut count := u32(0)
	mut no_properties := unsafe { nil }
	vk.get_physical_device_queue_family_properties(device, &count, mut no_properties)
	mut properties := []vk.QueueFamilyProperties{len: int(count)}
	vk.get_physical_device_queue_family_properties(device, &count, mut properties[0])
	for index, property in properties {
		mut present := vk.Bool32(0)
		vk_check(vk.get_physical_device_surface_support_khr(device, u32(index), surface, &present),
			'query presentation support')!
		if property.queueFlags & u32(vk.QueueFlagBits.graphics) != 0 && present == vk._true {
			return u32(index)
		}
	}
	return error('no queue supports both graphics and presentation')
}
