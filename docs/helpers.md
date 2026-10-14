# Sessions, buffers, and transfers

Start with the complete [first program](../examples/getting_started/main.v).
Every owner needs explicit cleanup; register `defer` immediately after creation.
Close buffers, transfers and kernels before closing their session. A session
exposes its device, context and in-order queue; it never hides a CPU fallback.
Read `session.device.name` and `session.device.kind` to report the selected path.

## Device selection

| `DeviceRequirements` field | Default | Meaning |
| --- | --- | --- |
| `preferred_types` | GPU, then CPU | Ordered eligible types; `[cl.device_type_gpu]` forbids CPU fallback |
| `required_uuid` | None | Match a device UUID obtained from another API; unavailable UUIDs are rejected |
| `required_extensions` | Empty | Every listed extension must be advertised |
| `minimum_global_memory` | 0 bytes | Minimum reported global memory, not currently free memory |
| `require_compiler` | `true` | Require source compilation; disable for binary-only applications |

`device_candidates()` returns every device with its rejection reason. Native
query failures remain errors. `select_device()` chooses the first eligible device
in preference order. `new_session_on()` accepts a previously inspected device.
`SessionOptions.profiling` enables timestamp collection on the in-order queue.

## Buffer operations

All offsets/counts below are **elements**, not bytes. Element types must be plain
C-layout values without strings, slices, maps or other managed references.

| Operation | Host blocking | Ownership and result |
| --- | --- | --- |
| `buffer_from_slice[T]` | Until upload finishes | New buffer; empty input is rejected |
| `ScratchBuffer.reserve(count)` | Allocation only | Reuses capacity; growth discards contents after successful allocation |
| `reserve_preserving(queue, count, waits)` | Allocation only | Copies existing elements on growth; returns completion event |
| `Buffer.copy_to(queue, destination, source_offset, destination_offset, count, waits)` | No | Bounds-checked copy; overlapping same-buffer ranges rejected |
| `Buffer.fill(queue, value, offset, count, waits)` | No | OpenCL 1.2; pattern size must be a power of two, up to 128 bytes |
| `upload_owned(queue, offset, values, waits)` | Host copy only | Transfer owner holds a copy of the source slice |
| `download_owned(queue, offset, count, waits)` | No | Transfer owner holds destination storage |

Scratch `reserve(0)` is harmless and leaves an unallocated scratch buffer empty.
Access borrowed storage through `buffer()!`, which reports an error before the
first allocation or after close. Rebind kernel arguments after
growth; cloned references continue referring to the old allocation. A preserving
growth event must precede device use of the new contents. Scratch owners are not
thread-safe; callers order old/new buffer access with events.

Zero-length copy/fill/transfer operations return a marker honoring dependencies.
Owned transfer `event()` is borrowed. `values()` waits and returns an independent
host copy. `close()` waits before releasing storage. Keep the transfer owner alive
until completion; there are no finalizers. Existing `write_async`/`read_async`
remain available when the caller manages host memory lifetime directly.

## Kernel dispatch

| `enqueue_1d_after` parameter | Unit | Contract |
| --- | --- | --- |
| `queue` | Queue owner | Valid queue in the kernel's context |
| `global_size` | Work-items | Positive; kernel must accept this range |
| `local_size` | Work-items per group | `0` lets the runtime choose; explicit dimensions must satisfy device/kernel limits |
| `wait_events` | Borrowed native events | Empty means no additional dependencies |

Returns an owned event. Work submission is asynchronous. Work sizes are never
silently rounded: a kernel without bounds guards must not receive padded work.
`work_group_info(device)` reports maximum size, preferred multiple, compile-time
dimensions and local-memory usage. `set_local_arg(index, bytes)` sets a nonzero
size for an OpenCL `__local` argument. Raw OpenCL calls remain accessible.

See [recipes](convenience.md) for images, SVM and explicit event chains.
