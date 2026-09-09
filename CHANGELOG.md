# Changelog

## Unreleased

- Mark the generator as the source of truth for the Vulkan particles example
  while continuing to ship its synchronized copy with the public module.
- Record synchronized paths in `DISTRIBUTION_FILES` and remove files retired
  from the canonical distribution without touching unrelated local files.

## 0.4.1 - 2026-09-09

- Allow the Vulkan particles example to compile and run with TinyCC by keeping
  every Vulkan structure referenced through generated mutable-pointer fields
  mutable and removing the obsolete compiler guard.
- Update GitHub checkout actions to the Node.js 24 generation.

## 0.4.0

- Add owned typed 2D images with format-size validation, bounds-checked blocking and asynchronous transfers, supported-format discovery, and typed kernel arguments.
- Add owned samplers and typed sampler kernel arguments.
- Add owned typed shared virtual memory with capability discovery, checked allocation and transfers, coarse-grained map/unmap operations, and typed kernel arguments.
- Add an image and SVM example that executes both memory models through real OpenCL kernels.
- Map particle-example cursor coordinates to Vulkan's downward-positive viewport and use logical window dimensions on HiDPI displays.
- Reuse acquire semaphores only after their submission fence signals and keep one presentation semaphore per swapchain image in the Vulkan particle renderer.

## 0.3.2

- Make the particle example's headless default explicit at runtime and in its usage documentation.
- Reject external-buffer element counts whose byte size would overflow before calling OpenCL.
- Run the live V-master compatibility lane with the complete source-built compiler toolchain.

## 0.3.1

- Add stable aggregate `required-checks` status for protected branches.
- Record the exact generator revision in published modules with `GENERATOR_COMMIT`.
- Synchronize package version metadata and the license into `antono2/opencl` publication pull requests.
- Coordinate releases so a successful generator release creates the matching OpenCL tag only after version and provenance validation.
- Serialize publication runs and reliably update only an open publication pull request.

## 0.3.0

- Preserve typed OpenCL pointer declarations at the C ABI while accepting opaque-handle arrays through pointer-safe `voidptr` wrapper parameters.
- Pass real null event and global-offset pointers from blocking transfers and synchronous kernel dispatch.
- Add a strict C pointer-ABI regression test independent of the installed OpenCL implementation.
- Reject typed-buffer byte-size overflow before calling OpenCL.
- Pin the Khronos registry and header revisions used by generation and CI.
- Publish releases only from matching version tags after the full test matrix succeeds.

## 0.2.2

- Add owned opaque-FD external-memory and external-semaphore interoperability helpers.
- Resolve extension entry points for the selected OpenCL platform and preserve Windows calling conventions.
- Migrate the Vulkan particles example to typed imports and explicit event dependency chains.
- Validate live zero-copy memory and semaphore interoperability on an NVIDIA GeForce GTX 1060.

## 0.2.1

- Add parsed runtime capability and device/driver UUID helpers.

## 0.2.0

- Generate the complete cumulative OpenCL 1.0 through 3.0 API.
- Add ergonomic ownership, error, discovery, buffer, program, kernel, event,
  profiling, and multidimensional-dispatch layers to generated packages.
- Generate external-memory, external-semaphore, and device UUID extensions.
- Add automated Linux runtime, macOS ABI, and Windows ABI validation.
- Add portable and Vulkan/OpenCL interoperability examples.

## 0.1.3

- Publish generated bindings and release automation.
