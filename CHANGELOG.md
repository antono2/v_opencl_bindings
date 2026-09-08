# Changelog

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
