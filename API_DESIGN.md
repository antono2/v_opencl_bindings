# Ergonomic API design

The generated `opencl.v` file remains the complete, low-level ABI binding. Hand-written
ergonomic APIs live in separate files in the same module and are optional: existing code
can continue calling the generated functions directly.

## Shared conventions

- Preserve native result codes in typed errors and include the failed operation.
- Return `!T` from convenience operations instead of discarding status codes.
- Hide count-then-fill enumeration without hiding the returned native handles.
- Use `close()` for reference-counted OpenCL ownership wrappers.
- Keep constructors explicit about device choice and requested capabilities.
- Never enable an extension or feature merely because headers declare it; query runtime support.
- Keep unsafe pointers at the low-level boundary and expose slices or strings where ownership is clear.

These conventions intentionally match the companion Vulkan convenience layer where the APIs
have equivalent shapes. Vulkan retains its distinct explicit destruction and synchronization
model rather than pretending to be reference-counted like OpenCL.

## Delivery slices

1. Typed errors, platform/device discovery, and string information helpers.
2. Context and command-queue ownership. (Implemented.)
3. Typed buffers and bounds-checked blocking transfer helpers. (Implemented.)
4. Program compilation with build logs and kernel argument helpers. (Implemented.)
5. Owned events, wait lists, markers, barriers, and asynchronous buffer/kernel operations. (Implemented.)
6. Optional extension capability objects and interoperability helpers.
