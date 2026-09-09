module main

import antono2.opencl as cl

const image_source = '__kernel void copy_image(read_only image2d_t source, write_only image2d_t destination, sampler_t image_sampler) { int2 p = (int2)(get_global_id(0), get_global_id(1)); write_imagef(destination, p, read_imagef(source, image_sampler, p)); }'
const svm_source = '__kernel void brighten(__global uint *values, uint amount) { values[get_global_id(0)] += amount; }'

fn run() ! {
	platforms := cl.platforms()!
	if platforms.len == 0 {
		return error('no OpenCL platform found')
	}
	devices := cl.devices(platforms[0], cl.device_type_all)!
	if devices.len == 0 {
		return error('no OpenCL device found')
	}
	device := devices[0]
	println('OpenCL device: ${cl.device_info_string(device, cl.device_name)!}')
	mut context := cl.new_context(device)!
	mut queue := context.command_queue(device, cl.CommandQueueProperties(0))!

	format := cl.ImageFormat{
		image_channel_order:     cl.rgba
		image_channel_data_type: cl.unorm_int8
	}
	mut source_image := cl.new_image_2d[u32](&context, cl.mem_read_only, format, 2, 2)!
	mut destination_image := cl.new_image_2d[u32](&context, cl.mem_write_only, format, 2, 2)!
	mut sampler := cl.new_sampler(&context, false, cl.address_clamp_to_edge, cl.filter_nearest)!
	mut image_program := cl.build_source_program(&context, device, image_source, '')!
	mut image_kernel := image_program.kernel('copy_image')!
	source_image.set_kernel_arg(&image_kernel, 0)!
	destination_image.set_kernel_arg(&image_kernel, 1)!
	image_kernel.set_sampler_arg(2, &sampler)!
	pixels := [u32(0xff0000ff), 0xff00ff00, 0xffff0000, 0xffffffff]
	mut uploaded := source_image.write_async(&queue, pixels, []cl.Event{})!
	mut copied := image_kernel.enqueue_nd_after(&queue, [usize(2), 2], []usize{}, [
		uploaded.handle,
	])!
	mut image_result := []u32{len: pixels.len}
	mut downloaded := destination_image.read_async(&queue, mut image_result, [
		copied.handle,
	])!
	downloaded.wait()!
	if image_result != pixels {
		return error('typed image round trip failed: ${image_result}')
	}
	println('Typed RGBA image kernel round trip passed')
	downloaded.close()!
	copied.close()!
	uploaded.close()!
	image_kernel.close()!
	image_program.close()!
	sampler.close()!

	capabilities := cl.device_svm_support(device)!
	if capabilities & (cl.device_svm_coarse_grain_buffer | cl.device_svm_fine_grain_buffer) != 0 {
		mut allocation := cl.new_svm[u32](&context, cl.mem_read_write, 4, 0)!
		mut program := cl.build_source_program(&context, device, svm_source, '')!
		mut kernel := program.kernel('brighten')!
		allocation.set_kernel_arg(&kernel, 0)!
		amount := u32(5)
		kernel.set_arg(1, &amount)!
		allocation.write(&queue, 0, [u32(1), 2, 3, 4])!
		kernel.enqueue_1d(&queue, 4, 0)!
		mut svm_result := []u32{len: 4}
		allocation.read(&queue, 0, mut svm_result)!
		if svm_result != [u32(6), 7, 8, 9] {
			return error('typed SVM kernel round trip failed: ${svm_result}')
		}
		println('Typed SVM kernel round trip passed')
		kernel.close()!
		program.close()!
		allocation.close()
	} else {
		println('SVM unavailable; typed SVM example skipped')
	}

	destination_image.close()!
	source_image.close()!
	queue.close()!
	context.close()!
}

fn main() {
	run() or {
		eprintln(err)
		exit(1)
	}
}
