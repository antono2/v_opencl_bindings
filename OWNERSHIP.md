# Ownership model

The convenience API uses explicit `close()` methods. Close events, kernels,
programs, memory objects, and queues before their parent context.

`OwnedContext`, `OwnedCommandQueue`, `Buffer`, `Image2D`, `OwnedSampler`,
`SvmAllocation`, `OwnedProgram`, `OwnedKernel`, `OwnedEvent`, and
`OwnedExternalSemaphore` are `@[nocopy]`. Constructors return owned pointers so
resources cross module boundaries without copying. Pass those pointers directly
to convenience functions; do not add another `&`.

`close()` is mutable and idempotent: it releases one native reference and
clears the wrapper's handle. There are no implicit finalizers. For OpenCL
objects which support native reference counting, `clone_ref()` performs the
matching `clRetain*` operation and returns a separate owned pointer which must
also be closed. SVM has no retain operation and remains uniquely owned.

1. Keep each returned owner pointer and register cleanup immediately.
2. Pass owner pointers directly; copy only raw handles and discovery values.
3. Close children before parents.
4. Use `clone_ref()` only when a second independently retained reference is
   required, and close both owners.

For coarse-grained SVM, call `map()` before accessing `SvmAllocation.handle`
from the host and `unmap()` before submitting device work. Wait for the unmap
event before using the allocation from a kernel. Blocking and asynchronous
`write`/`read` helpers perform OpenCL SVM copies and do not expose host access.
