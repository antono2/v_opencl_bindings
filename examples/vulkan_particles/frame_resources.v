module main

import vulkan as vk

struct FrameResources {
	render_pass  vk.RenderPass
	framebuffers []vk.Framebuffer
	command_pool vk.CommandPool
	commands     []vk.CommandBuffer
	image_ready  vk.Semaphore
	render_done  vk.Semaphore
	fence        vk.Fence
}

fn create_frame_resources(device vk.Device, family u32, swapchain &SwapchainBundle) !FrameResources {
	attachment := vk.AttachmentDescription{
		format: swapchain.format
		samples: ._1
		loadOp: .clear
		storeOp: .store
		stencilLoadOp: .dont_care
		stencilStoreOp: .dont_care
		initialLayout: .undefined
		finalLayout: .present_src_khr
	}
	reference := vk.AttachmentReference{ attachment: 0, layout: .color_attachment_optimal }
	subpass := vk.SubpassDescription{
		pipelineBindPoint: .graphics
		colorAttachmentCount: 1
		pColorAttachments: &reference
	}
	dependency := vk.SubpassDependency{
		srcSubpass: vk.subpass_external
		dstSubpass: 0
		srcStageMask: u32(vk.PipelineStageFlagBits.color_attachment_output)
		dstStageMask: u32(vk.PipelineStageFlagBits.color_attachment_output)
		dstAccessMask: u32(vk.AccessFlagBits.color_attachment_write)
	}
	info := vk.RenderPassCreateInfo{
		attachmentCount: 1
		pAttachments: &attachment
		subpassCount: 1
		pSubpasses: &subpass
		dependencyCount: 1
		pDependencies: &dependency
	}
	mut pass := vk.RenderPass(unsafe { nil })
	vk_check(vk.create_render_pass(device, &info, unsafe { nil }, &pass), 'create render pass')!
	mut framebuffers := []vk.Framebuffer{cap: swapchain.views.len}
	for view in swapchain.views {
		fb_info := vk.FramebufferCreateInfo{
			renderPass: pass
			attachmentCount: 1
			pAttachments: unsafe { &view }
			width: swapchain.extent.width
			height: swapchain.extent.height
			layers: 1
		}
		mut framebuffer := vk.Framebuffer(unsafe { nil })
		vk_check(vk.create_framebuffer(device, &fb_info, unsafe { nil }, &framebuffer), 'create framebuffer')!
		framebuffers << framebuffer
	}
	pool_info := vk.CommandPoolCreateInfo{ queueFamilyIndex: family }
	mut pool := vk.CommandPool(unsafe { nil })
	vk_check(vk.create_command_pool(device, &pool_info, unsafe { nil }, &pool), 'create command pool')!
	mut commands := unsafe { []vk.CommandBuffer{len: swapchain.images.len} }
	allocate := vk.CommandBufferAllocateInfo{
		commandPool: pool
		level: .primary
		commandBufferCount: u32(commands.len)
	}
	vk_check(vk.allocate_command_buffers(device, &allocate, commands.data), 'allocate commands')!
	semaphore_info := vk.SemaphoreCreateInfo{}
	mut ready := vk.Semaphore(unsafe { nil })
	mut done := vk.Semaphore(unsafe { nil })
	vk_check(vk.create_semaphore(device, &semaphore_info, unsafe { nil }, &ready), 'create acquire semaphore')!
	vk_check(vk.create_semaphore(device, &semaphore_info, unsafe { nil }, &done), 'create render semaphore')!
	mut fence := vk.Fence(unsafe { nil })
	fence_info := vk.FenceCreateInfo{ flags: u32(vk.FenceCreateFlagBits.signaled) }
	vk_check(vk.create_fence(device, &fence_info, unsafe { nil }, &fence), 'create frame fence')!
	return FrameResources{pass, framebuffers, pool, commands, ready, done, fence}
}

fn (r &FrameResources) draw_particles(device vk.Device, queue vk.Queue, swapchain &SwapchainBundle,
	pipeline &ParticlePipeline, particles &ParticleBuffer, count usize, elapsed f32,
	compute_ready vk.Semaphore, graphics_done vk.Semaphore, external_sync bool,
	show_trails bool) !bool {
	mut index := u32(0)
	acquire_result := vk.acquire_next_image_khr(device, swapchain.handle, max_u64, r.image_ready, unsafe { nil }, &index)
	if acquire_result == .error_out_of_date_khr {
		complete_external_handoff(queue, compute_ready, graphics_done, external_sync)!
		return false
	}
	if acquire_result != .success && acquire_result != .suboptimal_khr {
		return error('acquire image failed with Vulkan result ${acquire_result}')
	}
	mut recreate := acquire_result == .suboptimal_khr
	vk_check(vk.wait_for_fences(device, 1, &r.fence, vk._true, max_u64), 'wait frame')!
	vk_check(vk.reset_fences(device, 1, &r.fence), 'reset frame')!
	vk_check(vk.reset_command_pool(device, r.command_pool, 0), 'reset command pool')!
	mut command := r.commands[index]
	begin := vk.CommandBufferBeginInfo{ flags: u32(vk.CommandBufferUsageFlagBits.one_time_submit) }
	vk_check(vk.begin_command_buffer(command, &begin), 'begin commands')!
	mut clear := vk.ClearValue{}
	unsafe {
		clear.color.float32[0] = 0.008
		clear.color.float32[1] = 0.012
		clear.color.float32[2] = 0.03
		clear.color.float32[3] = 1
	}
	render := vk.RenderPassBeginInfo{
		renderPass: r.render_pass
		framebuffer: r.framebuffers[index]
		renderArea: vk.Rect2D{ extent: swapchain.extent }
		clearValueCount: 1
		pClearValues: &clear
	}
	vk.cmd_begin_render_pass(command, &render, .inline)
	offset := vk.DeviceSize(0)
	vk.cmd_bind_vertex_buffers(command, 0, 1, &particles.handle, &offset)
	frame := [f32(swapchain.extent.width), f32(swapchain.extent.height), f32(3.2), elapsed]
	vk.cmd_push_constants(command, pipeline.layout, u32(vk.ShaderStageFlagBits.vertex), 0, 16, frame.data)
	if show_trails {
		vk.cmd_bind_pipeline(command, .graphics, pipeline.trails)
		vk.cmd_draw(command, 2, u32(count), 0, 0)
	}
	vk.cmd_bind_pipeline(command, .graphics, pipeline.handle)
	vk.cmd_draw(command, u32(count), 1, 0, 0)
	vk.cmd_end_render_pass(command)
	vk_check(vk.end_command_buffer(command), 'end commands')!
	mut color_stage := vk.PipelineStageFlags(vk.PipelineStageFlagBits.color_attachment_output)
	mut submit := vk.SubmitInfo{}
	if external_sync {
		waits := [r.image_ready, compute_ready]
		stages := [color_stage, vk.PipelineStageFlags(vk.PipelineStageFlagBits.vertex_input)]
		signals := [r.render_done, graphics_done]
		submit = vk.SubmitInfo{
			waitSemaphoreCount: 2
			pWaitSemaphores: waits.data
			pWaitDstStageMask: stages.data
			commandBufferCount: 1
			pCommandBuffers: &command
			signalSemaphoreCount: 2
			pSignalSemaphores: signals.data
		}
	} else {
		submit = vk.SubmitInfo{
			waitSemaphoreCount: 1
			pWaitSemaphores: &r.image_ready
			pWaitDstStageMask: &color_stage
			commandBufferCount: 1
			pCommandBuffers: &command
			signalSemaphoreCount: 1
			pSignalSemaphores: &r.render_done
		}
	}
	vk_check(vk.queue_submit(queue, 1, &submit, r.fence), 'submit frame')!
	present := vk.PresentInfoKHR{
		waitSemaphoreCount: 1
		pWaitSemaphores: &r.render_done
		swapchainCount: 1
		pSwapchains: &swapchain.handle
		pImageIndices: &index
	}
	present_result := vk.queue_present_khr(queue, &present)
	if present_result == .error_out_of_date_khr || present_result == .suboptimal_khr {
		recreate = true
	} else if present_result != .success {
		return error('present frame failed with Vulkan result ${present_result}')
	}
	return !recreate
}

// Close the semaphore cycle when image acquisition rejects a frame after OpenCL has run.
fn complete_external_handoff(queue vk.Queue, compute_ready vk.Semaphore, graphics_done vk.Semaphore,
	external_sync bool) ! {
	if !external_sync {
		return
	}
	mut stage := vk.PipelineStageFlags(vk.PipelineStageFlagBits.vertex_input)
	submit := vk.SubmitInfo{
		waitSemaphoreCount: 1
		pWaitSemaphores: &compute_ready
		pWaitDstStageMask: &stage
		signalSemaphoreCount: 1
		pSignalSemaphores: &graphics_done
	}
	vk_check(vk.queue_submit(queue, 1, &submit, unsafe { nil }), 'complete skipped frame handoff')!
}

fn (r &FrameResources) destroy(device vk.Device) {
	vk.destroy_fence(device, r.fence, unsafe { nil })
	vk.destroy_semaphore(device, r.render_done, unsafe { nil })
	vk.destroy_semaphore(device, r.image_ready, unsafe { nil })
	vk.destroy_command_pool(device, r.command_pool, unsafe { nil })
	for framebuffer in r.framebuffers {
		vk.destroy_framebuffer(device, framebuffer, unsafe { nil })
	}
	vk.destroy_render_pass(device, r.render_pass, unsafe { nil })
}
