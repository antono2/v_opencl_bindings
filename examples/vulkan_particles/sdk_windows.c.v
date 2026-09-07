module main

// The Khronos Windows SDK is not installed in a system include/library directory by default.
#flag -I$env('OPENCL_INCLUDE')
#flag -L$env('OPENCL_LIB')
