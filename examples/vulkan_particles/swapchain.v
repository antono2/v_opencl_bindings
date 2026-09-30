module main

import antono2.glfw
import antono2.vulkan as vk
import antono2.vulkan.ergonomic as vke

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
	selected_format := vke.select_surface_format(formats, [vk.SurfaceFormatKHR{
		format:     .b8g8r8a8_srgb
		colorSpace: .srgb_nonlinear
	}])!
	present_mode := vke.select_present_mode(present_modes, [.mailbox, .fifo])!
	framebuffer := glfw.framebuffer_size(window)
	extent := vke.select_surface_extent(capabilities, vk.Extent2D{
		width:  u32(framebuffer.width)
		height: u32(framebuffer.height)
	})
	image_count := vke.select_surface_image_count(capabilities, 1)
	composite_alpha := vke.select_composite_alpha(capabilities.supportedCompositeAlpha,
		[.opaque, .pre_multiplied, .post_multiplied, .inherit])!
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
