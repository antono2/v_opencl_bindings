module opencl

// Image2D owns a typed two-dimensional OpenCL image. T represents one complete
// image element (pixel), not one channel. Its size must match format exactly.
pub struct Image2D[T] {
pub mut:
	handle Mem
pub:
	width       int
	height      int
	format      ImageFormat
	pixel_bytes usize
}

// OwnedSampler owns one OpenCL sampler reference.
pub struct OwnedSampler {
pub mut:
	handle Sampler
}

// supported_image2d_formats returns every format supported for a 2D image with flags.
pub fn supported_image2d_formats(context &OwnedContext, flags MemFlags) ![]ImageFormat {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'query image formats from closed OpenCL context'
			status:    invalid_context
		}
	}
	mut count := u32(0)
	check(get_supported_image_formats(context.handle, flags, mem_object_image2d, 0, unsafe { nil },
		&count), 'query supported OpenCL 2D image format count')!
	if count == 0 {
		return []
	}
	if u64(count) > u64(max_int) {
		return OpenCLError{
			operation: 'query too many supported OpenCL 2D image formats'
			status:    out_of_host_memory
		}
	}
	capacity := count
	mut formats := unsafe { []ImageFormat{len: int(capacity)} }
	check(get_supported_image_formats(context.handle, flags, mem_object_image2d, capacity,
		formats.data, &count), 'query supported OpenCL 2D image formats')!
	if count > capacity {
		return OpenCLError{
			operation: 'supported OpenCL 2D image format count changed during query'
			status:    out_of_resources
		}
	}
	return formats[..int(count)].clone()
}

fn image_channel_count(order ChannelOrder) !usize {
	return match order {
		r, a, intensity, luminance, depth {
			usize(1)
		}
		rg, ra, rx {
			usize(2)
		}
		rgb, rgx, srgb {
			usize(3)
		}
		rgba, bgra, argb, rgbx, srgbx, srgba, sbgra, abgr {
			usize(4)
		}
		else {
			return OpenCLError{
				operation: 'use unsupported OpenCL image channel order'
				status:    invalid_image_format_descriptor
			}
		}
	}
}

// image_format_pixel_bytes returns the storage size of one pixel for a core
// OpenCL image format.
pub fn image_format_pixel_bytes(format ImageFormat) !usize {
	match format.image_channel_data_type {
		unorm_short_565, unorm_short_555 {
			if format.image_channel_order != rgb && format.image_channel_order != rgbx {
				return OpenCLError{
					operation: 'use packed 5/6-bit OpenCL image type with non-RGB channel order'
					status:    invalid_image_format_descriptor
				}
			}
			return 2
		}
		unorm_int_101010 {
			if format.image_channel_order != rgb && format.image_channel_order != rgbx {
				return OpenCLError{
					operation: 'use packed 10-bit OpenCL image type with non-RGB channel order'
					status:    invalid_image_format_descriptor
				}
			}
			return 4
		}
		unorm_int_101010_2 {
			if format.image_channel_order != rgba {
				return OpenCLError{
					operation: 'use packed 10/10/10/2 OpenCL image type with non-RGBA channel order'
					status:    invalid_image_format_descriptor
				}
			}
			return 4
		}
		else {}
	}

	channel_bytes := match format.image_channel_data_type {
		snorm_int8, unorm_int8, signed_int8, unsigned_int8 {
			usize(1)
		}
		snorm_int16, unorm_int16, signed_int16, unsigned_int16, half_float {
			usize(2)
		}
		signed_int32, unsigned_int32, float {
			usize(4)
		}
		else {
			return OpenCLError{
				operation: 'use unsupported OpenCL image channel type'
				status:    invalid_image_format_descriptor
			}
		}
	}

	return image_channel_count(format.image_channel_order)! * channel_bytes
}

fn checked_image_dimensions(width int, height int, operation string) !int {
	if width <= 0 || height <= 0 || usize(width) > usize(max_int) / usize(height) {
		return OpenCLError{
			operation: operation
			status:    invalid_image_size
		}
	}
	return width * height
}

// new_image_2d allocates a tightly packed 2D image without a host pointer.
pub fn new_image_2d[T](context &OwnedContext, flags MemFlags, format ImageFormat, width int,
	height int) !Image2D[T] {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'create OpenCL image from closed context'
			status:    invalid_context
		}
	}
	pixel_count := checked_image_dimensions(width, height,
		'create OpenCL image with invalid dimensions')!
	checked_element_bytes[T](pixel_count, 'create OpenCL image with overflowing dimensions')!
	pixel_bytes := image_format_pixel_bytes(format)!
	if pixel_bytes != usize(sizeof(T)) {
		return OpenCLError{
			operation: 'create typed OpenCL image whose pixel type does not match its format'
			status:    invalid_image_format_descriptor
		}
	}
	description := ImageDesc{
		image_type:   mem_object_image2d
		image_width:  usize(width)
		image_height: usize(height)
	}
	mut status := success
	handle := create_image(context.handle, flags, &format, &description, unsafe { nil }, &status)
	check(status, 'create OpenCL 2D image')!
	if isnil(handle) {
		return OpenCLError{
			operation: 'create OpenCL 2D image'
			status:    mem_object_allocation_failure
		}
	}
	return Image2D[T]{
		handle:      handle
		width:       width
		height:      height
		format:      format
		pixel_bytes: pixel_bytes
	}
}

fn (image &Image2D[T]) validate_region(queue &OwnedCommandQueue, x int, y int, width int,
	height int, length int, operation string) ! {
	if isnil(image.handle) {
		return OpenCLError{
			operation: '${operation} closed OpenCL image'
			status:    invalid_mem_object
		}
	}
	if isnil(queue.handle) {
		return OpenCLError{
			operation: '${operation} OpenCL image using closed queue'
			status:    invalid_command_queue
		}
	}
	pixel_count := checked_image_dimensions(width, height,
		'${operation} OpenCL image with invalid region')!
	if x < 0 || y < 0 || x > image.width || y > image.height || width > image.width - x
		|| height > image.height - y {
		return OpenCLError{
			operation: '${operation} outside OpenCL image bounds'
			status:    invalid_value
		}
	}
	if length != pixel_count {
		return OpenCLError{
			operation: '${operation} OpenCL image with mismatched pixel count'
			status:    invalid_value
		}
	}
	checked_element_bytes[T](length, '${operation} OpenCL image with overflowing region')!
}

// write replaces every pixel and blocks until values can be reused.
pub fn (image &Image2D[T]) write(queue &OwnedCommandQueue, values []T) ! {
	image.write_region(queue, 0, 0, image.width, image.height, values)!
}

// write_async enqueues replacement of every pixel. values must remain allocated
// and unchanged until the returned event completes.
pub fn (image &Image2D[T]) write_async(queue &OwnedCommandQueue, values []T,
	wait_events []Event) !OwnedEvent {
	return image.write_region_async(queue, 0, 0, image.width, image.height, values, wait_events)
}

// write_region replaces a tightly packed image rectangle and blocks until complete.
pub fn (image &Image2D[T]) write_region(queue &OwnedCommandQueue, x int, y int, width int,
	height int, values []T) ! {
	image.validate_region(queue, x, y, width, height, values.len, 'write')!
	origin := [usize(x), usize(y), usize(0)]
	region := [usize(width), usize(height), usize(1)]
	row_pitch := usize(width) * image.pixel_bytes
	check(enqueue_write_image(queue.handle, image.handle, blocking, origin.data, region.data,
		row_pitch, 0, values.data, 0, unsafe { nil }, unsafe { nil }), 'write OpenCL image')!
}

// write_region_async enqueues a tightly packed image write. values must remain
// allocated and unchanged until the returned event completes.
pub fn (image &Image2D[T]) write_region_async(queue &OwnedCommandQueue, x int, y int,
	width int, height int, values []T, wait_events []Event) !OwnedEvent {
	image.validate_region(queue, x, y, width, height, values.len, 'write')!
	origin := [usize(x), usize(y), usize(0)]
	region := [usize(width), usize(height), usize(1)]
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(enqueue_write_image(queue.handle, image.handle, non_blocking, origin.data, region.data,
		usize(width) * image.pixel_bytes, 0, values.data, u32(wait_events.len), wait_pointer,
		&event), 'write OpenCL image asynchronously')!
	return OwnedEvent{
		handle: event
	}
}

// read copies every pixel and blocks until destination is populated.
pub fn (image &Image2D[T]) read(queue &OwnedCommandQueue, mut destination []T) ! {
	image.read_region(queue, 0, 0, image.width, image.height, mut destination)!
}

// read_async enqueues a copy of every pixel. destination must remain allocated
// and unread until the returned event completes.
pub fn (image &Image2D[T]) read_async(queue &OwnedCommandQueue, mut destination []T,
	wait_events []Event) !OwnedEvent {
	return image.read_region_async(queue, 0, 0, image.width, image.height, mut destination,
		wait_events)
}

// read_region copies a tightly packed image rectangle and blocks until complete.
pub fn (image &Image2D[T]) read_region(queue &OwnedCommandQueue, x int, y int, width int,
	height int, mut destination []T) ! {
	image.validate_region(queue, x, y, width, height, destination.len, 'read')!
	origin := [usize(x), usize(y), usize(0)]
	region := [usize(width), usize(height), usize(1)]
	check(enqueue_read_image(queue.handle, image.handle, blocking, origin.data, region.data,
		usize(width) * image.pixel_bytes, 0, destination.data, 0, unsafe { nil }, unsafe { nil }),
		'read OpenCL image')!
}

// read_region_async enqueues a tightly packed image read. destination must
// remain allocated and unread until the returned event completes.
pub fn (image &Image2D[T]) read_region_async(queue &OwnedCommandQueue, x int, y int,
	width int, height int, mut destination []T, wait_events []Event) !OwnedEvent {
	image.validate_region(queue, x, y, width, height, destination.len, 'read')!
	origin := [usize(x), usize(y), usize(0)]
	region := [usize(width), usize(height), usize(1)]
	mut wait_pointer := &Event(unsafe { nil })
	if wait_events.len > 0 {
		wait_pointer = wait_events.data
	}
	mut event := Event(unsafe { nil })
	check(enqueue_read_image(queue.handle, image.handle, non_blocking, origin.data, region.data,
		usize(width) * image.pixel_bytes, 0, destination.data, u32(wait_events.len), wait_pointer,
		&event), 'read OpenCL image asynchronously')!
	return OwnedEvent{
		handle: event
	}
}

// close releases the owned image reference. It is safe to call more than once.
pub fn (mut image Image2D[T]) close() ! {
	if isnil(image.handle) {
		return
	}
	check(release_mem_object(image.handle), 'release OpenCL image')!
	image.handle = unsafe { nil }
}

// set_kernel_arg binds this owned image to a kernel argument.
pub fn (image &Image2D[T]) set_kernel_arg(kernel &OwnedKernel, index u32) ! {
	if isnil(image.handle) {
		return OpenCLError{
			operation: 'bind closed OpenCL image to kernel'
			status:    invalid_mem_object
		}
	}
	kernel.set_arg(index, &image.handle)!
}

// new_sampler creates an owned sampler for image kernel arguments.
pub fn new_sampler(context &OwnedContext, normalized_coordinates bool,
	addressing_mode AddressingMode, filter_mode FilterMode) !OwnedSampler {
	if isnil(context.handle) {
		return OpenCLError{
			operation: 'create OpenCL sampler from closed context'
			status:    invalid_context
		}
	}
	mut status := success
	normalized := Bool(if normalized_coordinates { 1 } else { 0 })
	handle := create_sampler(context.handle, normalized, addressing_mode, filter_mode, &status)
	check(status, 'create OpenCL sampler')!
	if isnil(handle) {
		return OpenCLError{
			operation: 'create OpenCL sampler'
			status:    out_of_host_memory
		}
	}
	return OwnedSampler{
		handle: handle
	}
}

// close releases the owned sampler reference. It is safe to call more than once.
pub fn (mut sampler OwnedSampler) close() ! {
	if isnil(sampler.handle) {
		return
	}
	check(release_sampler(sampler.handle), 'release OpenCL sampler')!
	sampler.handle = unsafe { nil }
}
