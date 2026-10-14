# Convenience recipes

The generated functions expose the complete raw API. Optional helpers add typed
errors, device discovery and explicit resource ownership. The snippets below
show individual operations; see the [examples](../README.md#examples) for complete programs.

### Platform and device discovery

```v
for platform in cl.platforms()! {
	println(cl.platform_info_string(platform, cl.platform_name)!)
	for device in cl.devices(platform, cl.device_type_all)! {
		println('  ${cl.device_info_string(device, cl.device_name)!}')
	}
}
```

### Contexts, queues and buffers

Contexts and queues use explicit, idempotent cleanup:

```v
mut context := cl.new_context(device)!
defer { context.close() or {} }
mut queue := context.command_queue(device, cl.CommandQueueProperties(0))!
defer { queue.close() or {} }

mut buffer := cl.new_buffer[f32](context, cl.mem_read_write, 1024)!
defer { buffer.close() or {} }
buffer.write(queue, 0, []f32{len: 1024, init: f32(index)})!
```

The element type used by `Buffer[T]`, typed transfers and kernel arguments
must be a plain C-layout value without V-managed references such as strings,
maps or slices. Element-count multiplication is checked for overflow before
an OpenCL allocation or transfer call.

### Programs and kernels

Source compilation preserves compiler diagnostics through `ProgramBuildError`. Owned
kernels support typed scalar and buffer arguments plus one-dimensional dispatch:

```v
mut program := cl.build_source_program(context, device, source, '')!
defer { program.close() or {} }
mut kernel := program.kernel('transform')!
defer { kernel.close() or {} }
kernel.set_buffer_arg(0, buffer.handle)!
kernel.set_slice_arg(1, [f32(0.5), 1.0])! // e.g. an OpenCL float2
kernel.enqueue_1d(queue, usize(buffer.count), 0)!
```

### Events and asynchronous transfers

Non-blocking transfers and dispatch return owned events and accept native event
dependency lists. Host slices must remain alive until their transfer event completes:

```v
mut uploaded := buffer.write_async(queue, 0, values, []cl.Event{})!
mut dispatched := kernel.enqueue_1d_after(queue, usize(buffer.count), 0,
	[uploaded.handle])!
mut downloaded := buffer.read_async(queue, 0, mut result, [dispatched.handle])!
downloaded.wait()!
profile := downloaded.profile()! // queue must use cl.queue_profiling_enable
downloaded.close()!
dispatched.close()!
uploaded.close()!
```

### Ownership and cleanup

Owned contexts, queues, buffers, images, samplers, programs, kernels, events
and external semaphores are `@[nocopy]`, preventing accidental double release.
Constructors return owned pointers; pass them directly without adding another
`&`. When two independently closable owners are required,
call `clone_ref()`; it performs the matching OpenCL retain operation. SVM
allocations cannot be retained and therefore always have one unique owner.

For multidimensional kernels, `enqueue_nd_after()` accepts one to three global
dimensions and either a matching local-size slice or an empty slice for an
implementation-selected work-group size.

### Images and shared virtual memory

Typed 2D images validate that `T` represents one complete pixel, provide checked
full-image and region transfers and bind directly to kernels alongside owned
samplers:

```v
format := cl.ImageFormat{
	image_channel_order:     cl.rgba
	image_channel_data_type: cl.unorm_int8
}
mut image := cl.new_image_2d[u32](context, cl.mem_read_write, format, 64, 64)!
defer { image.close() or {} }
mut sampler := cl.new_sampler(context, false, cl.address_clamp_to_edge,
	cl.filter_nearest)!
defer { sampler.close() or {} }
image.write(queue, pixels)!
image.set_kernel_arg(kernel, 0)!
kernel.set_sampler_arg(1, sampler)!
```

Shared virtual memory is similarly typed and capability-gated. Coarse-grained
allocations can use checked copies or explicit map/unmap transitions, and can be
bound directly to a kernel:

```v
svm_capabilities := cl.device_svm_support(device)!
if svm_capabilities & (cl.device_svm_coarse_grain_buffer |
	cl.device_svm_fine_grain_buffer) != 0 {
	mut shared := cl.new_svm[u32](context, cl.mem_read_write, 1024, 0)!
	defer { shared.close() }
	shared.write(queue, 0, values)!
	shared.set_kernel_arg(kernel, 0)!
}
```

Apple's OpenCL 1.2 framework does not expose SVM entry points, so SVM capability
discovery reports the feature as unavailable on macOS. Image support remains
available according to the selected device's advertised formats.

### Optional features and Vulkan interoperability

Optional features can be discovered once without substring matching or unsafe
UUID buffers:

```v
capabilities := cl.device_capabilities(device)!
if capabilities.has_all(['cl_khr_external_memory',
	'cl_khr_external_memory_opaque_fd']) && capabilities.device_uuid {
	device_uuid := capabilities.uuid()!
}
```

Opaque-FD external objects use the same explicit ownership and event model. File
descriptors are obtained from the exporting API; its handle-ownership rules still apply:

```v
memory_interop := cl.load_external_memory_interop(platform, capabilities)!
mut shared := memory_interop.import_opaque_fd_buffer[f32](context, memory_fd,
	element_count, cl.mem_read_write)!
defer { shared.close() or {} }

semaphore_interop := cl.load_external_semaphore_interop(platform, capabilities)!
mut ready := semaphore_interop.import_opaque_fd(context, semaphore_fd)!
defer { ready.close() or {} }
mut waited := ready.wait(queue, [])!
mut acquired := memory_interop.acquire(queue, [shared.handle], [waited.handle])!
defer { acquired.close() or {} }
defer { waited.close() or {} }
```

Owned events expose explicit wait lists without manual reference counting:

```v
mut uploaded := queue.marker([]cl.Event{})!
defer { uploaded.close() or {} }
mut ready := queue.barrier([uploaded.handle])!
defer { ready.close() or {} }
ready.wait()!
```

See [`API_DESIGN.md`](../API_DESIGN.md) for the conventions shared with the companion
Vulkan convenience layer.
See [`OWNERSHIP.md`](../OWNERSHIP.md) for the current ownership and cleanup rules.
