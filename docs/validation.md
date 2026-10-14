# Local validation — 2026-10-14

Validated on Linux with V 0.5.2, GCC and TinyCC, and an NVIDIA GeForce GTX 1060
6GB. These results describe this checkout, not a cross-platform certification.
Windows and macOS compilation checks are configured in CI but were not run locally.

- Generator tests (24) and publisher tests (11) passed.
- Existing convenience and ABI tests and new helper tests passed.
- Linked and dynamically loaded helper tests passed; the dynamic executable
  starts without an OpenCL loader and reports an actionable error.
- Scan and compaction matched CPU results for empty, single-item, irregular,
  all-zero, all-nonzero and mixed inputs; unsigned wraparound and out-of-order
  queue dependencies were checked.
- First-use and algorithm examples ran with the V3 backend; strict V3 frontend
  checks also passed. Typed image/SVM and existing compute smoke examples passed.
- The existing particle example passed shared-memory and semaphore handoff
  checks and rendered 16 frames with dynamic loading and Vulkan validation.
- README code matches the executable first-use example. Generated source is
  reproducible from the pinned registry after formatting.

See [algorithm measurements](algorithms.md) for end-to-end CPU/GPU timings.
No consumer backend was switched automatically. Source ownership remains in this
repository; the public module receives the same files through the publisher.
