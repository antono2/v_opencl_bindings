# Device-resident scan and stable compaction

Import `antono2.opencl.algorithms` only when needed. A `Workspace` caches its
program, kernels, queue reference and scratch buffers. Create it once and reuse it.
See the complete [compaction example](../examples/algorithms/main.v).

| Operation | Inputs | Output contract |
| --- | --- | --- |
| `inclusive_scan(input, output, count, waits)` | `Buffer[u32]`; first `count` elements | Inclusive unsigned sums modulo 2^32 |
| `compact_indices(flags, indices, selected_count, count, waits)` | Any nonzero `u32` flag selects an element | Ascending source indices; selected count in `selected_count[0]` |

Buffers must belong to the workspace context. Input/output handles must be
distinct. Scan output and compaction index capacity must cover `count`, even
when few elements are selected. The count buffer needs at least one element.
Only the selected prefix of compacted indices is defined. Zero input skips kernel
launches; compaction writes a zero count. Negative/excess counts are rejected.

Both methods return completion events; close them when done. No result is read
back implicitly. Chain subsequent kernels to the completion event and consume the
count on the device, or explicitly read it on the host. Workspace operations
serialize through a retained last event, including on out-of-order queues. A
workspace is not thread-safe. `close()` waits before releasing cached resources.

The portable baseline uses O(n log n) scan work and O(n) scratch storage. It is a
correctness/reuse baseline, not a promised speedup over application kernels.
Measure packing, allocation, transfer, dispatch and readback together. The
[tests](../test/helpers_test.v) compare empty, singleton, power-of-two and uneven
sizes, zero/all/mixed flags, capacities and ordering against CPU results.

Record gathering, reductions and sorting can build on these APIs later. VSL
adapters are welcome; this submodule does not require a numerical framework.

## Reproducible measurement

Run `v -cc gcc run examples/algorithms_benchmark` to compare a CPU reference
with five warm iterations including OpenCL upload, dispatch and result readback.
Compilation and reusable allocation setup are outside the timed region. Verify
results on each run; use your application's actual layout and workload before
choosing a backend.

An illustrative Linux/GTX 1060 run on 2026-10-14 measured:

| Elements | CPU reference (microseconds) | OpenCL complete round trip (microseconds) |
| --- | ---: | ---: |
| 256 | 3.16 | 66.79 |
| 4,096 | 83.73 | 170.90 |
| 65,536 | 2,045.97 | 422.82 |

These are observations for this example, not thresholds or performance promises.
