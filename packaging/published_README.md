<!-- Maintained in antono2/v_opencl_bindings/packaging/published_README.md. -->
# OpenCL for V

[![Test OpenCL module and advanced example](https://github.com/antono2/opencl/actions/workflows/test.yml/badge.svg)](https://github.com/antono2/opencl/actions/workflows/test.yml)

OpenCL bindings for the [V programming language](https://vlang.io/), with the
complete OpenCL 1.0 through 3.0 core API, selected Khronos extensions and
optional helpers for device discovery and explicit resource ownership.

[Available on VPM](https://vpm.vlang.io/packages/antono2.opencl) ·
[Release notes](https://github.com/antono2/opencl/releases) ·
[Project portfolio](https://oreskin.de/projects_en.php)

## Install and setup

Install the current bindings in your V module directory:

```sh
v install antono2.opencl
```

This installs the repository's current default branch, not a fixed release.
For reproducible builds, select a published package tag from the
[releases](https://github.com/antono2/opencl/releases) and append `@<tag>` to
the module name in your install command or `v.mod`. A release pin is optional;
it is not required to use the API described by this checkout's README.

Then install or verify native prerequisites using the setup script in the
installed module. At the default V module location (POSIX shell):

```sh
v run "$HOME/.vmodules/antono2/opencl/setup.vsh"
```

For PowerShell at the default module location:

```powershell
v run "$HOME\.vmodules\antono2\opencl\setup.vsh" --check
v run "$HOME\.vmodules\antono2\opencl\setup.vsh" --probe
```

If `VMODULES` is configured, use the `antono2/opencl` directory under that
module root instead. Setup reuses an installed module and its selected release.

From a source checkout, use `v run setup.vsh`. The script supports Ubuntu and
Debian, Fedora, Arch, openSUSE, macOS and Windows. It reuses an existing V module.
For diagnostics without installing packages, add `--check` to either invocation.
Use `--probe` to compile and execute a kernel through these bindings and verify its result.

On Linux, setup installs OpenCL headers, the ICD loader and PoCL for CPU-based
development. On Windows, it installs headers and the Khronos loader through
vcpkg; the GPU vendor driver supplies the OpenCL implementation. macOS uses
its built-in OpenCL framework. Device and optional-feature availability is
always determined by the installed implementation at runtime.

This checkout's package version is `@VERSION@`, as recorded in `v.mod` and
`VERSION`. The package version is separate from the OpenCL API versions it
exposes. When using a pinned release, consult that tag's README for its API
and setup instructions.

## First program

Save this complete program as `main.v` and run `v run main.v`. It selects an
available GPU, falling back to a CPU OpenCL device, and checks the kernel output.
Expected output ends with `[2.0, 4.0, 6.0, 8.0]`; the device name varies.

<!-- example: examples/getting_started/main.v -->
```v
// A complete first kernel with checked output and failure-safe cleanup.
module main

import antono2.opencl as cl

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}

fn run() ! {
	mut session := cl.new_session(cl.SessionOptions{})!
	defer { session.close() or {} }
	mut values := cl.buffer_from_slice[f32](session.context, session.queue, cl.mem_read_write, [
		f32(1),
		2,
		3,
		4,
	])!
	defer { values.close() or {} }
	mut program := cl.build_source_program(session.context, session.device.device,
		'__kernel void twice(__global float *v) { v[get_global_id(0)] *= 2.0f; }', '')!
	defer { program.close() or {} }
	mut kernel := program.kernel('twice')!
	defer { kernel.close() or {} }
	kernel.set_buffer_arg(0, values.handle)!
	kernel.enqueue_1d(session.queue, 4, 0)!
	mut result := []f32{len: 4}
	values.read(session.queue, 0, mut result)!
	assert result == [f32(2), 4, 6, 8]
	println('${session.device.name}: ${result}')
}
```

## Choose your next step

| Task | Guide or runnable example |
| --- | --- |
| Run your first verified kernel | [Getting started](examples/getting_started) |
| Select a device, reuse buffers, chain transfers | [Convenience reference](docs/helpers.md) |
| Scan values or compact active indices on the device | [Algorithms](docs/algorithms.md) |
| Use images, SVM, or native OpenCL operations | [Recipes](docs/convenience.md) |
| Deploy optional acceleration or reuse program binaries | [Runtime and caching](docs/runtime.md) |
| Understand cleanup and host-memory lifetime | [Ownership](OWNERSHIP.md) |

## Examples

[`examples/vector_add`](examples/vector_add) is a compact introduction to the
owned convenience API. It runs asynchronous buffer uploads, a kernel, profiled
readback and explicit cleanup.

[`examples/image_svm`](examples/image_svm) copies a typed RGBA image through an
image kernel and owned sampler, then executes a second kernel directly over a
typed SVM allocation when the selected device advertises buffer SVM support.

[`examples/vulkan_particles`](examples/vulkan_particles) is an interactive particle-galaxy
example that combines OpenCL compute with Vulkan presentation. On UUID-matched devices it imports
one exported Vulkan allocation into OpenCL and synchronizes access with reusable opaque-FD
semaphores. It also includes a portable host-staged fallback, swapchain recreation, velocity
trails, interactive controls and display-independent interoperability smoke tests.

The example is a separate nested V module, so its `vulkan` and `glfw` dependencies are not
dependencies of applications that only import `opencl`.

## API coverage

The module exposes the complete OpenCL 1.0 through 3.0 core API and selected
portable Khronos extensions with V-style snake-case wrappers,
including platform and device discovery, contexts, queues, memory and images,
programs, kernels, events, profiling, synchronization and object lifecycle.
The bindings generator reads command prototypes, types, pointer depth and all
OpenCL 1.0 through 3.0 core constants from Khronos' XML registry. Constants are
exposed using their corresponding OpenCL typedefs.
Core command callbacks use named V function types, allowing callback signatures
to be checked at compile time while optional callbacks still accept `unsafe { nil }`.
The initial extension set covers `cl_khr_il_program`,
`cl_khr_create_command_queue`, `cl_khr_subgroups` and
`cl_khr_suggested_local_work_size`.
Zero-copy synchronization support covers `cl_khr_semaphore`,
`cl_khr_external_semaphore` and `cl_khr_external_memory`, including opaque-FD,
DMA-BUF and sync-file handle variants.
`cl_khr_device_uuid` provides UUID, LUID and node-mask device queries for
matching an OpenCL device with another compute or graphics API.
Optional extension commands are resolved through the ICD at runtime instead of
being required linker symbols, so applications that do not use them can still
build against older OpenCL loaders.

CI exercises complete typed buffer, image/sampler and SVM kernel paths, OpenCL
1.1 user events, an OpenCL 1.2 marker-with-wait-list dependency, and OpenCL 2.0
property-list queue creation and SVM allocation on PoCL.
OpenCL 2.1 coverage additionally checks synchronized device and host timer
queries; IL programs, kernel cloning, subgroup queries and SVM migration are
present in the generated API.
OpenCL 2.2 adds program specialization constants and program-release callbacks.
OpenCL 3.0 adds numeric version helpers, `NameVersion`, context destructor
callbacks and property-based buffer and image creation.

## Supported toolchains

CI pins the release compiler and a V3 compiler revision. The exact compiler,
runner and dependency versions are recorded in
[the test workflow](.github/workflows/test.yml).

| Platform | Compiler lane | Validation |
| --- | --- | --- |
| Linux | Pinned release V, GCC | Kernels, images, SVM and Vulkan-particle validation smoke tests |
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

The canonical sources, helpers, examples and this README are maintained in
[`antono2/v_opencl_bindings`](https://github.com/antono2/v_opencl_bindings).
Submit changes there; its publication workflow updates this module.

Bindings are generated from Khronos' OpenCL XML registry. `REGISTRY_COMMIT` and
`HEADERS_COMMIT` identify the immutable Khronos inputs, `GENERATOR_COMMIT`
identifies the generator revision, and `VERSION` records the package version.
The publisher fills this README's package metadata from `VERSION` and checks
documentation drift together with the other distribution files. The primary
installation command remains unpinned; release tags are an optional choice
for reproducible builds.

## Source navigation

`opencl.v` is generated; its introduction and declarations belong to the
[canonical generator](https://github.com/antono2/v_opencl_bindings).
Handwritten discovery, ownership, event, image and interoperability files have
purpose comments describing their role. Make shared source and example changes
in that repository, then run its publisher; direct edits here can be overwritten.
Keep vendored OpenCL headers and their upstream license notices intact.


## Compatibility and diagnostics

See [tested profiles and read-only diagnostics](docs/compatibility.md) for
compiler/dependency versions, setup recovery actions and upgrade checks.
