# Ownership model

The convenience API uses explicit `close()` methods. Close events, kernels,
programs, memory objects, and queues before their parent context.

V structs are values and can be copied. Each copy of an `OwnedContext`,
`OwnedCommandQueue`, `Buffer`, `OwnedProgram`, `OwnedKernel`, `OwnedEvent`, or
external-interoperability owner refers to the same OpenCL reference. Closing
one value clears that value's handle, but it does not clear copies made earlier.

Until a breaking ownership redesign, follow these rules:

1. Treat owning wrappers as move-only by convention.
2. Pass references or raw handles to helpers instead of copying owners.
3. Register cleanup immediately and close children before parents.
4. Never close more than one copy of the same owned reference.

The intended post-`0.x` design is a reference-backed control block. All copies
would observe one closed state and the native reference would be released at
most once. Explicit retain/clone operations would remain separate when the
caller actually wants another OpenCL reference.
