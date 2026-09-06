#!/usr/bin/env python3
"""Small, deterministic OpenCL XML to V generator.

The initial surface intentionally covers discovery and information queries.
The registry checks make stale or renamed Khronos entries fail generation
instead of silently producing an incomplete module.
"""

from __future__ import annotations

from pathlib import Path
import xml.etree.ElementTree as ET


REQUIRED_COMMANDS = (
    "clGetPlatformIDs",
    "clGetPlatformInfo",
    "clGetDeviceIDs",
    "clGetDeviceInfo",
)

REQUIRED_ENUMS = (
    "CL_SUCCESS",
    "CL_DEVICE_NOT_FOUND",
    "CL_PLATFORM_NOT_FOUND_KHR",
    "CL_PLATFORM_PROFILE",
    "CL_PLATFORM_VERSION",
    "CL_PLATFORM_NAME",
    "CL_PLATFORM_VENDOR",
    "CL_PLATFORM_EXTENSIONS",
    "CL_DEVICE_TYPE_DEFAULT",
    "CL_DEVICE_TYPE_CPU",
    "CL_DEVICE_TYPE_GPU",
    "CL_DEVICE_TYPE_ACCELERATOR",
    "CL_DEVICE_TYPE_CUSTOM",
    "CL_DEVICE_TYPE_ALL",
    "CL_DEVICE_NAME",
    "CL_DEVICE_VENDOR",
    "CL_DEVICE_VERSION",
    "CL_DRIVER_VERSION",
)


HEADER = """// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
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
	return C.clGetPlatformInfo(platform, param_name, param_value_size, param_value,
		param_value_size_ret)
}

pub fn get_device_ids(platform PlatformId, device_type DeviceType, num_entries u32,
	devices &DeviceId, num_devices &u32) ErrorCode {
	return C.clGetDeviceIDs(platform, device_type, num_entries, devices, num_devices)
}

pub fn get_device_info(device DeviceId, param_name DeviceInfo, param_value_size usize,
	param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetDeviceInfo(device, param_name, param_value_size, param_value,
		param_value_size_ret)
}
"""


class OpenCLGenerator:
    def __init__(self, registry: Path):
        self.registry = registry

    def validate_registry(self) -> None:
        if not self.registry.is_file():
            raise FileNotFoundError(f"OpenCL registry not found: {self.registry}")
        root = ET.parse(self.registry).getroot()
        commands = {node.get("name") or node.findtext("proto/name") for node in root.findall("commands/command")}
        enums = {node.get("name") for node in root.findall(".//enum")}
        missing_commands = sorted(set(REQUIRED_COMMANDS) - commands)
        missing_enums = sorted(set(REQUIRED_ENUMS) - enums)
        if missing_commands or missing_enums:
            raise RuntimeError(
                f"Registry is missing commands={missing_commands}, enums={missing_enums}"
            )

    def write(self, output: Path) -> None:
        self.validate_registry()
        output.write_text(HEADER, encoding="utf-8")

