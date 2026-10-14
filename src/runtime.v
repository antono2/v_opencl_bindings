// Optional runtime availability. Build with -d opencl_dynamic to avoid loader linkage.
module opencl

$if opencl_dynamic ? {
	fn C.vcl_symbol(name &char) voidptr
}

// Dynamic loading is initialized once per process. Set OPENCL_LIBRARY before
// the first call to select a specific runtime; a failed override never falls back.
pub fn runtime_available() bool {
	$if opencl_dynamic ? {
		return !isnil(C.vcl_symbol(c'clGetPlatformIDs'))
	} $else {
		return true
	}
}
