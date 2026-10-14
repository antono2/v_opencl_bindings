# Ergonomic API design

The generated `opencl.v` file remains the complete, low-level ABI binding. Hand-written
ergonomic APIs live in separate files in the same module and are optional: existing code
can continue calling the generated functions directly.

## Shared conventions

- Preserve native result codes in typed errors and include the failed operation.
- Return `!&T` for owning convenience operations instead of discarding status
  codes or copying resource wrappers across module boundaries.
- Hide count-then-fill enumeration without hiding the returned native handles.
- Use `close()` for reference-counted OpenCL ownership wrappers.
- Owning wrappers are `@[nocopy]` and constructors return owned pointers.
  `clone_ref()` is the only supported way to create another native reference;
  SVM remains uniquely owned because OpenCL provides no retain operation.
- Keep constructors explicit about device choice and requested capabilities.
- Never enable an extension or feature merely because headers declare it; query runtime support.
- Keep unsafe pointers at the low-level boundary and expose slices or strings where ownership is clear.

These conventions intentionally match the companion Vulkan convenience layer where the APIs
have equivalent shapes. Vulkan retains its distinct explicit destruction and synchronization
model rather than pretending to be reference-counted like OpenCL.

## Delivery slices

1. Typed errors, platform/device discovery and string information helpers.
2. Context and command-queue ownership. (Implemented.)
3. Typed buffers and bounds-checked blocking transfer helpers. (Implemented.)
4. Program compilation with build logs and scalar, slice and buffer kernel argument helpers. (Implemented.)
5. Owned events, wait lists, profiling, markers, barriers and asynchronous 1D/2D/3D buffer/kernel operations. (Implemented.)
6. Optional extension capability objects and device UUID helpers. (Implemented.)
7. Platform-specific external-memory and external-semaphore loaders, opaque-FD imports, ownership handoffs and owned imported semaphores. (Implemented.)
8. Typed two-dimensional images, owned samplers and typed shared virtual memory with explicit host/device synchronization. (Implemented.)

## Ecosystem scope

The package includes optional, reusable device-resident algorithms alongside
thin Khronos bindings. `algorithms` begins with unsigned scan and stable index
compaction, accepting native-backed buffers, reusable scratch and event dependencies.
Empty inputs, capacity, ordering and arithmetic behavior are explicit contracts.

VSL integration and reuse are encouraged where APIs and ownership match. They
are not prerequisites for delivering useful OpenCL algorithms here. Tensor APIs,
cross-backend dispatch and application-specific simulation rules remain separate
concerns; additions are evaluated by concrete consumers and maintenance cost.

See [helper reference](docs/helpers.md), [algorithms](docs/algorithms.md), and
[runtime and caching](docs/runtime.md) for the added session, transfer, binary
cache and optional dynamic-loader APIs.
