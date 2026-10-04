<!-- Maintained in antono2/v_opencl_bindings/packaging/published_README.md. -->
# OpenCL for V

[![Test OpenCL module and advanced example](https://github.com/antono2/opencl/actions/workflows/test.yml/badge.svg)](https://github.com/antono2/opencl/actions/workflows/test.yml)

OpenCL bindings for the [V programming language](https://vlang.io/), with the
complete OpenCL 1.0 through 3.0 core API, selected Khronos extensions, and
optional helpers for device discovery and explicit resource ownership.

[Available on VPM](https://vpm.vlang.io/packages/antono2.opencl) ·
[Release notes](https://github.com/antono2/opencl/releases/tag/v@VERSION@) ·
[Project portfolio](https://oreskin.de/projects_en.php)

## Install and setup

Install the release described by this README:

```sh
v install antono2.opencl@v@VERSION@
```

Then install or verify native prerequisites using the setup script in the
installed module. At the default V module location:

```sh
v run "$HOME/.vmodules/antono2/opencl/setup.vsh"
```

From a source checkout, use `v run setup.vsh`. The script supports Ubuntu and
Debian, Fedora, Arch, openSUSE, macOS, and Windows. It reuses an existing V module.
For diagnostics without installing packages, add `--check` to either invocation.

On Linux, setup installs OpenCL headers, the ICD loader, and PoCL for CPU-based
development. On Windows, it installs headers and the Khronos loader through
vcpkg; the GPU vendor driver supplies the OpenCL implementation. macOS uses
its built-in OpenCL framework. Device and optional-feature availability is
always determined by the installed implementation at runtime.

For other package versions, see the [releases](https://github.com/antono2/opencl/releases).
The package version is separate from the OpenCL API versions it exposes.

## First program

Save this as `main.v`, then run `v run main.v`:

```v
import antono2.opencl as cl

fn main() {
	mut count := u32(0)
	result := cl.get_platform_ids(0, unsafe { nil }, &count)
	if result != cl.success {
		panic('clGetPlatformIDs failed: ${result}')
	}
	println('OpenCL platforms: ${count}')
}
```

## Convenience API

The generated functions expose the complete raw API. Optional helpers add typed
errors, device discovery, and explicit resource ownership. The snippets below
show individual operations; see the [examples](#examples) for complete programs.

### Platform and device discovery

```v
for platform in cl.platforms()! {
	println(cl.platform_info_string(platform, cl.platform_name)!)
	for device in cl.devices(platform, cl.device_type_all)! {
		println('  ${cl.device_info_string(device, cl.device_name)!}')
	}
}
```

### Contexts, queues, and buffers

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

The element type used by `Buffer[T]`, typed transfers, and kernel arguments
must be a plain C-layout value without V-managed references such as strings,
maps, or slices. Element-count multiplication is checked for overflow before
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

Owned contexts, queues, buffers, images, samplers, programs, kernels, events,
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
full-image and region transfers, and bind directly to kernels alongside owned
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

See [`API_DESIGN.md`](API_DESIGN.md) for the conventions shared with the companion
Vulkan convenience layer.
See [`OWNERSHIP.md`](OWNERSHIP.md) for the current ownership and cleanup rules.

## Examples

[`examples/vector_add`](examples/vector_add) is a compact introduction to the
owned convenience API. It runs asynchronous buffer uploads, a kernel, profiled
readback, and explicit cleanup.

[`examples/image_svm`](examples/image_svm) copies a typed RGBA image through an
image kernel and owned sampler, then executes a second kernel directly over a
typed SVM allocation when the selected device advertises buffer SVM support.

[`examples/vulkan_particles`](examples/vulkan_particles) is an interactive particle-galaxy
example that combines OpenCL compute with Vulkan presentation. On UUID-matched devices it imports
one exported Vulkan allocation into OpenCL and synchronizes access with reusable opaque-FD
semaphores. It also includes a portable host-staged fallback, swapchain recreation, velocity
trails, interactive controls, and display-independent interoperability smoke tests.

The example is a separate nested V module, so its `vulkan` and `glfw` dependencies are not
dependencies of applications that only import `opencl`.

## API coverage

The module exposes the complete OpenCL 1.0 through 3.0 core API and selected
portable Khronos extensions with V-style snake-case wrappers,
including platform and device discovery, contexts, queues, memory and images,
programs, kernels, events, profiling, synchronization, and object lifecycle.
The bindings generator reads command prototypes, types, pointer depth, and all
OpenCL 1.0 through 3.0 core constants from Khronos' XML registry. Constants are
exposed using their corresponding OpenCL typedefs.
Core command callbacks use named V function types, allowing callback signatures
to be checked at compile time while optional callbacks still accept `unsafe { nil }`.
The initial extension set covers `cl_khr_il_program`,
`cl_khr_create_command_queue`, `cl_khr_subgroups`, and
`cl_khr_suggested_local_work_size`.
Zero-copy synchronization support covers `cl_khr_semaphore`,
`cl_khr_external_semaphore`, and `cl_khr_external_memory`, including opaque-FD,
DMA-BUF, and sync-file handle variants.
`cl_khr_device_uuid` provides UUID, LUID, and node-mask device queries for
matching an OpenCL device with another compute or graphics API.
Optional extension commands are resolved through the ICD at runtime instead of
being required linker symbols, so applications that do not use them can still
build against older OpenCL loaders.

CI exercises complete typed buffer, image/sampler, and SVM kernel paths, OpenCL
1.1 user events, an OpenCL 1.2 marker-with-wait-list dependency, and OpenCL 2.0
property-list queue creation and SVM allocation on PoCL.
OpenCL 2.1 coverage additionally checks synchronized device and host timer
queries; IL programs, kernel cloning, subgroup queries, and SVM migration are
present in the generated API.
OpenCL 2.2 adds program specialization constants and program-release callbacks.
OpenCL 3.0 adds numeric version helpers, `NameVersion`, context destructor
callbacks, and property-based buffer and image creation.

## Supported toolchains

CI pins the release compiler and a V3 compiler revision. The exact compiler,
runner, and dependency versions are recorded in
[the test workflow](.github/workflows/test.yml).

| Platform | Compiler lane | Validation |
| --- | --- | --- |
| Linux | Pinned release V, GCC | Kernels, images, SVM, and Vulkan-particle validation smoke tests |
| Linux | Pinned release V, TinyCC | Vulkan-particle compile and headless smoke test |
| Linux | Pinned V3, TinyCC | Required frontend checks and module/vector-add runtime smoke tests |
| macOS | Pinned release V, Clang | OpenCL framework ABI compilation |
| Windows | Pinned release V, MSVC | OpenCL loader ABI compilation |
| Linux | Current V master, GCC | Advisory runtime compatibility checks |

The pinned V3 frontend checks also cover the particle example and ABI probe.
Windows and macOS compilation confirms the loader ABI; it does not establish
that every device supports every optional feature. The moving V-master and
Vulkan/GLFW-master lanes report compatibility regressions without blocking
releases on an unrelated upstream change.

## Maintenance and release provenance

The canonical sources, helpers, examples, and this README are maintained in
[`antono2/v_opencl_bindings`](https://github.com/antono2/v_opencl_bindings).
Submit changes there; its publication workflow updates this module.

Bindings are generated from Khronos' OpenCL XML registry. `REGISTRY_COMMIT` and
`HEADERS_COMMIT` identify the immutable Khronos inputs, `GENERATOR_COMMIT`
identifies the generator revision, and `VERSION` records the package version.
The publisher fills this README's installation command from `VERSION` and
checks documentation drift together with the other distribution files.
