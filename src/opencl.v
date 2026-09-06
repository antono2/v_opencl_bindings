// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
module opencl

#flag linux -lOpenCL

#flag windows -lOpenCL

#include <CL/opencl.h>

pub type PlatformId = voidptr

pub type DeviceId = voidptr

pub type ErrorCode = i32

pub type PlatformInfo = u32

pub type DeviceInfo = u32

pub type DeviceType = u64

pub const success = ErrorCode(0)
pub const device_not_found = ErrorCode(-1)
pub const platform_not_found_khr = ErrorCode(-1001)

pub const platform_profile = PlatformInfo(0x0900)
pub const platform_version = PlatformInfo(0x0901)
pub const platform_name = PlatformInfo(0x0902)
pub const platform_vendor = PlatformInfo(0x0903)
pub const platform_extensions = PlatformInfo(0x0904)

pub const device_type_default = DeviceType(1 << 0)
pub const device_type_cpu = DeviceType(1 << 1)
pub const device_type_gpu = DeviceType(1 << 2)
pub const device_type_accelerator = DeviceType(1 << 3)
pub const device_type_custom = DeviceType(1 << 4)
pub const device_type_all = DeviceType(0xffff_ffff)

pub const device_name = DeviceInfo(0x102b)
pub const device_vendor = DeviceInfo(0x102c)
pub const driver_version = DeviceInfo(0x102d)
pub const device_version = DeviceInfo(0x102f)

fn C.clGetPlatformIDs(u32, &PlatformId, &u32) ErrorCode

fn C.clGetPlatformInfo(PlatformId, PlatformInfo, usize, voidptr, &usize) ErrorCode

fn C.clGetDeviceIDs(PlatformId, DeviceType, u32, &DeviceId, &u32) ErrorCode

fn C.clGetDeviceInfo(DeviceId, DeviceInfo, usize, voidptr, &usize) ErrorCode

pub fn get_platform_ids(num_entries u32, platforms &PlatformId, num_platforms &u32) ErrorCode {
	return C.clGetPlatformIDs(num_entries, platforms, num_platforms)
}

pub fn get_platform_info(platform PlatformId, param_name PlatformInfo, param_value_size usize,
	param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetPlatformInfo(platform, param_name, param_value_size, param_value, param_value_size_ret)
}

pub fn get_device_ids(platform PlatformId, device_type DeviceType, num_entries u32,
	devices &DeviceId, num_devices &u32) ErrorCode {
	return C.clGetDeviceIDs(platform, device_type, num_entries, devices, num_devices)
}

pub fn get_device_info(device DeviceId, param_name DeviceInfo, param_value_size usize,
	param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetDeviceInfo(device, param_name, param_value_size, param_value, param_value_size_ret)
}
