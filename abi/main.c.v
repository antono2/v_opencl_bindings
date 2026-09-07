module main

import antono2.opencl as cl

fn main() {
	_ = cl.PlatformId(unsafe { nil })
	_ = cl.DeviceId(unsafe { nil })
	_ = cl.ImageFormat{}
	_ = cl.ImageDesc{}
	_ = cl.NameVersion{}
	_ = cl.EventCallback(unsafe { nil })
	_ = cl.PFN_clGetKernelSubGroupInfoKHR(unsafe { nil })
	assert sizeof(cl.BufferRegion) == 2 * sizeof(usize)
}
