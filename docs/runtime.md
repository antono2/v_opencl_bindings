# Optional runtime loading and program binaries

Normal builds keep the existing OpenCL loader linkage. To make acceleration
optional at process startup, compile with `v -d opencl_dynamic your_app.v`.
This mode resolves core commands from the runtime and preserves the generated
API. `runtime_available()` checks loader availability; `platforms()` reports a
clear error if loading failed. Device availability is a separate check.

| Setting | Behavior |
| --- | --- |
| No `OPENCL_LIBRARY` | System OpenCL loader/framework |
| `OPENCL_LIBRARY=/absolute/path/to/library` | Use only this library; failure does not silently select another |
| Missing core command returning a status | `invalid_operation` |
| Missing creation/allocation command | Null handle; `errcode_ret` is set when supplied |
| Missing void command | No operation; capability-check optional operations before using them |

Loading is thread-safe and occurs once. Set the override before the first OpenCL
call. Libraries stay loaded for process lifetime so live native objects retain
valid dispatch. Compilation still needs OpenCL headers. Linux dynamic builds do
not link `libOpenCL`; Windows/macOS use their native library loading mechanisms.

Application policy decides whether an unavailable runtime should disable
acceleration or be fatal. Optional extensions still require capability checks.

## Binary cache

`build_cached_program(context, summary, source, options, cached)` returns a
`CachedProgram` containing an owned `program`, `cache_hit` and `fallback_reason`.
Close that program normally. A missing/mismatched key or rejected binary rebuilds
from source. Source compiler failures retain their build log.

Persist a `ProgramBinary` with:

| Field | Source |
| --- | --- |
| `key` | `program_cache_key(summary, source, options)` |
| `data` | `program.binary()` |

The key incorporates source, compiler options, device name/vendor and driver
version. The driver also validates the binary. If the source includes external
headers, callers must include their contents/version in the cache policy or
invalidate the cache when they change. Filesystem location, eviction, locking and
atomic writes are application choices; these helpers never write files.

On macOS, the linked Apple framework provides OpenCL through 1.2. Later core
wrappers return `invalid_operation` (or a null handle with that error) instead
of referencing unavailable framework symbols. Dynamic builds resolve symbols
from the selected runtime and report the same failure when a symbol is absent.
