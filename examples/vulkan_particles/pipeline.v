module main

import antono2.vulkan as vk

struct ParticlePipeline {
	handle vk.Pipeline
	trails vk.Pipeline
	layout vk.PipelineLayout
}

fn create_particle_pipeline(device vk.Device, pass vk.RenderPass, extent vk.Extent2D) !ParticlePipeline {
	vert := create_shader_module(device, $embed_file('particles.vert.spv').to_bytes())!
	defer { vk.destroy_shader_module(device, vert, unsafe { nil }) }
	frag := create_shader_module(device, $embed_file('particles.frag.spv').to_bytes())!
	defer { vk.destroy_shader_module(device, frag, unsafe { nil }) }
	trail_vert := create_shader_module(device, $embed_file('trails.vert.spv').to_bytes())!
	defer { vk.destroy_shader_module(device, trail_vert, unsafe { nil }) }
	trail_frag := create_shader_module(device, $embed_file('trails.frag.spv').to_bytes())!
	defer { vk.destroy_shader_module(device, trail_frag, unsafe { nil }) }
	stages := [
		vk.PipelineShaderStageCreateInfo{ stage: .vertex, module: vert, pName: c'main' },
		vk.PipelineShaderStageCreateInfo{ stage: .fragment, module: frag, pName: c'main' },
	]
	mut binding := vk.VertexInputBindingDescription{ stride: u32(particle_stride), inputRate: .vertex }
	attributes := [vk.VertexInputAttributeDescription{ format: .r32g32b32a32_sfloat },
		vk.VertexInputAttributeDescription{ location: 1, format: .r32g32b32a32_sfloat, offset: 16 }]
	mut vertex := vk.PipelineVertexInputStateCreateInfo{ vertexBindingDescriptionCount: 1, pVertexBindingDescriptions: &binding, vertexAttributeDescriptionCount: 2, pVertexAttributeDescriptions: attributes.data }
	mut assembly := vk.PipelineInputAssemblyStateCreateInfo{ topology: .point_list }
	mut viewport := vk.Viewport{ width: f32(extent.width), height: f32(extent.height), maxDepth: 1 }
	mut scissor := vk.Rect2D{ extent: extent }
	mut viewport_state := vk.PipelineViewportStateCreateInfo{ viewportCount: 1, pViewports: &viewport, scissorCount: 1, pScissors: &scissor }
	mut raster := vk.PipelineRasterizationStateCreateInfo{ polygonMode: .fill, cullMode: u32(vk.CullModeFlagBits.none), lineWidth: 1 }
	mut multisample := vk.PipelineMultisampleStateCreateInfo{ rasterizationSamples: ._1 }
	mask := u32(vk.ColorComponentFlagBits.r) | u32(vk.ColorComponentFlagBits.g) | u32(vk.ColorComponentFlagBits.b) | u32(vk.ColorComponentFlagBits.a)
	mut blend_attachment := vk.PipelineColorBlendAttachmentState{ blendEnable: vk._true, srcColorBlendFactor: .one, dstColorBlendFactor: .one, colorBlendOp: .add, srcAlphaBlendFactor: .one, dstAlphaBlendFactor: .one, alphaBlendOp: .add, colorWriteMask: mask }
	mut blend := vk.PipelineColorBlendStateCreateInfo{ attachmentCount: 1, pAttachments: &blend_attachment }
	mut push := vk.PushConstantRange{ stageFlags: u32(vk.ShaderStageFlagBits.vertex), size: 16 }
	layout_info := vk.PipelineLayoutCreateInfo{ pushConstantRangeCount: 1, pPushConstantRanges: &push }
	mut layout := vk.PipelineLayout(unsafe { nil })
	vk_check(vk.create_pipeline_layout(device, &layout_info, unsafe { nil }, &layout), 'create pipeline layout')!
	info := vk.GraphicsPipelineCreateInfo{ stageCount: 2, pStages: stages.data, pVertexInputState: &vertex, pInputAssemblyState: &assembly, pViewportState: &viewport_state, pRasterizationState: &raster, pMultisampleState: &multisample, pColorBlendState: &blend, layout: layout, renderPass: pass }
	mut handle := vk.Pipeline(unsafe { nil })
	result := vk.create_graphics_pipelines(device, unsafe { nil }, 1, &info, unsafe { nil }, &handle)
	if result != .success {
		vk.destroy_pipeline_layout(device, layout, unsafe { nil })
		return error('create graphics pipeline: ${result}')
	}
	trail_stages := [
		vk.PipelineShaderStageCreateInfo{ stage: .vertex, module: trail_vert, pName: c'main' },
		vk.PipelineShaderStageCreateInfo{ stage: .fragment, module: trail_frag, pName: c'main' },
	]
	mut trail_binding := vk.VertexInputBindingDescription{
		stride: u32(particle_stride)
		inputRate: .instance
	}
	mut trail_vertex := vk.PipelineVertexInputStateCreateInfo{
		vertexBindingDescriptionCount: 1
		pVertexBindingDescriptions: &trail_binding
		vertexAttributeDescriptionCount: 2
		pVertexAttributeDescriptions: attributes.data
	}
	mut trail_assembly := vk.PipelineInputAssemblyStateCreateInfo{ topology: .line_list }
	trail_info := vk.GraphicsPipelineCreateInfo{
		stageCount: 2
		pStages: trail_stages.data
		pVertexInputState: &trail_vertex
		pInputAssemblyState: &trail_assembly
		pViewportState: &viewport_state
		pRasterizationState: &raster
		pMultisampleState: &multisample
		pColorBlendState: &blend
		layout: layout
		renderPass: pass
	}
	mut trails := vk.Pipeline(unsafe { nil })
	trail_result := vk.create_graphics_pipelines(device, unsafe { nil }, 1, &trail_info, unsafe { nil }, &trails)
	if trail_result != .success {
		vk.destroy_pipeline(device, handle, unsafe { nil })
		vk.destroy_pipeline_layout(device, layout, unsafe { nil })
		return error('create particle trail pipeline: ${trail_result}')
	}
	return ParticlePipeline{handle, trails, layout}
}

fn create_shader_module(device vk.Device, code []u8) !vk.ShaderModule {
	info := vk.ShaderModuleCreateInfo{ codeSize: usize(code.len), pCode: unsafe { &u32(code.data) } }
	mut shader := vk.ShaderModule(unsafe { nil })
	vk_check(vk.create_shader_module(device, &info, unsafe { nil }, &shader), 'create shader module')!
	return shader
}

fn (pipeline &ParticlePipeline) destroy(device vk.Device) {
	vk.destroy_pipeline(device, pipeline.trails, unsafe { nil })
	vk.destroy_pipeline(device, pipeline.handle, unsafe { nil })
	vk.destroy_pipeline_layout(device, pipeline.layout, unsafe { nil })
}
