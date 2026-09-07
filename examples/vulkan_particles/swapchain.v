module main

import antono2.glfw
import vulkan as vk

struct SwapchainBundle {
	handle      vk.SwapchainKHR
	format      vk.Format
	color_space vk.ColorSpaceKHR
	extent      vk.Extent2D
	images      []vk.Image
	views       []vk.ImageView
}

fn create_swapchain(physical vk.PhysicalDevice, device vk.Device, surface vk.SurfaceKHR,
	window &glfw.Window) !SwapchainBundle {
	mut capabilities := vk.SurfaceCapabilitiesKHR{}
	vk_check(vk.get_physical_device_surface_capabilities_khr(physical, surface, mut capabilities), 'query surface capabilities')!
	formats := surface_formats(physical, surface)!
	present_modes := surface_present_modes(physical, surface)!
	selected_format := choose_surface_format(formats)
	present_mode := choose_present_mode(present_modes)
	extent := choose_extent(capabilities, window)
	mut image_count := capabilities.minImageCount + 1
	if capabilities.maxImageCount > 0 && image_count > capabilities.maxImageCount {
		image_count = capabilities.maxImageCount
	}
	composite_alpha := choose_composite_alpha(capabilities.supportedCompositeAlpha)
	create_info := vk.SwapchainCreateInfoKHR{
		surface: surface
		minImageCount: image_count
		imageFormat: selected_format.format
		imageColorSpace: selected_format.colorSpace
		imageExtent: extent
		imageArrayLayers: 1
		imageUsage: u32(vk.ImageUsageFlagBits.color_attachment)
		imageSharingMode: .exclusive
		preTransform: capabilities.currentTransform
		compositeAlpha: composite_alpha
		presentMode: present_mode
		clipped: vk._true
	}
	mut handle := vk.SwapchainKHR(unsafe { nil })
	vk_check(vk.create_swapchain_khr(device, &create_info, unsafe { nil }, &handle), 'create swapchain')!
	mut actual_count := u32(0)
	vk_check(vk.get_swapchain_images_khr(device, handle, &actual_count, unsafe { nil }), 'count swapchain images')!
	mut images := unsafe { []vk.Image{len: int(actual_count)} }
	vk_check(vk.get_swapchain_images_khr(device, handle, &actual_count, images.data), 'get swapchain images')!
	mut views := []vk.ImageView{cap: int(actual_count)}
	for image in images {
		view_info := vk.ImageViewCreateInfo{
			image: image
			viewType: ._2d
			format: selected_format.format
			subresourceRange: vk.ImageSubresourceRange{
				aspectMask: u32(vk.ImageAspectFlagBits.color)
				levelCount: 1
				layerCount: 1
			}
		}
		mut view := vk.ImageView(unsafe { nil })
		if vk.create_image_view(device, &view_info, unsafe { nil }, &view) != .success {
			for created in views {
				vk.destroy_image_view(device, created, unsafe { nil })
			}
			vk.destroy_swapchain_khr(device, handle, unsafe { nil })
			return error('create swapchain image view')
		}
		views << view
	}
	return SwapchainBundle{handle, selected_format.format, selected_format.colorSpace, extent, images, views}
}

fn (swapchain &SwapchainBundle) destroy(device vk.Device) {
	for view in swapchain.views {
		vk.destroy_image_view(device, view, unsafe { nil })
	}
	vk.destroy_swapchain_khr(device, swapchain.handle, unsafe { nil })
}

fn surface_formats(device vk.PhysicalDevice, surface vk.SurfaceKHR) ![]vk.SurfaceFormatKHR {
	mut count := u32(0)
	mut no_formats := unsafe { nil }
	vk_check(vk.get_physical_device_surface_formats_khr(device, surface, &count, mut no_formats), 'count surface formats')!
	if count == 0 {
		return error('surface exposes no formats')
	}
	mut formats := []vk.SurfaceFormatKHR{len: int(count)}
	vk_check(vk.get_physical_device_surface_formats_khr(device, surface, &count, mut formats[0]), 'get surface formats')!
	return formats
}

fn surface_present_modes(device vk.PhysicalDevice, surface vk.SurfaceKHR) ![]vk.PresentModeKHR {
	mut count := u32(0)
	vk_check(vk.get_physical_device_surface_present_modes_khr(device, surface, &count, unsafe { nil }), 'count present modes')!
	mut modes := []vk.PresentModeKHR{len: int(count)}
	if count > 0 {
		vk_check(vk.get_physical_device_surface_present_modes_khr(device, surface, &count, modes[0]), 'get present modes')!
	}
	return modes
}

fn choose_surface_format(formats []vk.SurfaceFormatKHR) vk.SurfaceFormatKHR {
	for format in formats {
		if format.format == .b8g8r8a8_srgb && format.colorSpace == .srgb_nonlinear {
			return format
		}
	}
	return formats[0]
}

fn choose_present_mode(modes []vk.PresentModeKHR) vk.PresentModeKHR {
	for mode in modes {
		if mode == .mailbox {
			return mode
		}
	}
	return .fifo
}

fn choose_extent(capabilities vk.SurfaceCapabilitiesKHR, window &glfw.Window) vk.Extent2D {
	if capabilities.currentExtent.width != max_u32 {
		return capabilities.currentExtent
	}
	mut width := i32(0)
	mut height := i32(0)
	glfw.get_framebuffer_size(window, &width, &height)
	return vk.Extent2D{
		width: clamp_u32(u32(width), capabilities.minImageExtent.width, capabilities.maxImageExtent.width)
		height: clamp_u32(u32(height), capabilities.minImageExtent.height, capabilities.maxImageExtent.height)
	}
}

fn clamp_u32(value u32, minimum u32, maximum u32) u32 {
	return if value < minimum {
		minimum
	} else if value > maximum { maximum } else { value }
}

fn choose_composite_alpha(flags vk.CompositeAlphaFlagsKHR) vk.CompositeAlphaFlagBitsKHR {
	for choice in [vk.CompositeAlphaFlagBitsKHR.opaque, .pre_multiplied, .post_multiplied, .inherit] {
		if flags & u32(choice) != 0 {
			return choice
		}
	}
	return .opaque
}
