#!/usr/bin/env python3
"""Deterministic OpenCL XML to V generator."""

from __future__ import annotations

from pathlib import Path
import re
import xml.etree.ElementTree as ET


REQUIRED_COMMANDS = (
    "clGetPlatformIDs",
    "clGetPlatformInfo",
    "clGetDeviceIDs",
    "clGetDeviceInfo",
    "clCreateContext",
    "clReleaseContext",
    "clCreateCommandQueue",
    "clReleaseCommandQueue",
    "clCreateBuffer",
    "clReleaseMemObject",
    "clCreateProgramWithSource",
    "clBuildProgram",
    "clGetProgramBuildInfo",
    "clReleaseProgram",
    "clCreateKernel",
    "clSetKernelArg",
    "clReleaseKernel",
    "clEnqueueNDRangeKernel",
    "clEnqueueReadBuffer",
    "clFinish",
)

TYPED_CONSTANTS = {
    "PlatformInfo": (
        "CL_PLATFORM_PROFILE", "CL_PLATFORM_VERSION", "CL_PLATFORM_NAME",
        "CL_PLATFORM_VENDOR", "CL_PLATFORM_EXTENSIONS",
    ),
    "DeviceType": (
        "CL_DEVICE_TYPE_DEFAULT", "CL_DEVICE_TYPE_CPU", "CL_DEVICE_TYPE_GPU",
        "CL_DEVICE_TYPE_ACCELERATOR", "CL_DEVICE_TYPE_CUSTOM", "CL_DEVICE_TYPE_ALL",
    ),
    "DeviceInfo": (
        "CL_DEVICE_NAME", "CL_DEVICE_VENDOR", "CL_DRIVER_VERSION", "CL_DEVICE_VERSION",
    ),
    "MemFlags": ("CL_MEM_READ_ONLY", "CL_MEM_WRITE_ONLY", "CL_MEM_COPY_HOST_PTR"),
    "ProgramBuildInfo": ("CL_PROGRAM_BUILD_LOG",),
    "u32": ("CL_FALSE", "CL_TRUE"),
}


HEADER = """// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
module opencl

#flag linux -lOpenCL
#flag windows -lOpenCL
#include <CL/opencl.h>

pub type PlatformId = voidptr
pub type DeviceId = voidptr
pub type Context = voidptr
pub type CommandQueue = voidptr
pub type Mem = voidptr
pub type Program = voidptr
pub type Kernel = voidptr
pub type Event = voidptr
pub type ErrorCode = i32
pub type PlatformInfo = u32
pub type DeviceInfo = u32
pub type DeviceType = u64
pub type MemFlags = u64
pub type CommandQueueProperties = u64
pub type ProgramBuildInfo = u32

// __REGISTRY_CONSTANTS__

fn C.clGetPlatformIDs(u32, &PlatformId, &u32) ErrorCode
fn C.clGetPlatformInfo(PlatformId, PlatformInfo, usize, voidptr, &usize) ErrorCode
fn C.clGetDeviceIDs(PlatformId, DeviceType, u32, &DeviceId, &u32) ErrorCode
fn C.clGetDeviceInfo(DeviceId, DeviceInfo, usize, voidptr, &usize) ErrorCode
fn C.clCreateContext(&isize, u32, &DeviceId, voidptr, voidptr, &ErrorCode) Context
fn C.clReleaseContext(Context) ErrorCode
fn C.clCreateCommandQueue(Context, DeviceId, CommandQueueProperties, &ErrorCode) CommandQueue
fn C.clReleaseCommandQueue(CommandQueue) ErrorCode
fn C.clCreateBuffer(Context, MemFlags, usize, voidptr, &ErrorCode) Mem
fn C.clReleaseMemObject(Mem) ErrorCode
fn C.clCreateProgramWithSource(Context, u32, &&char, &usize, &ErrorCode) Program
fn C.clBuildProgram(Program, u32, &DeviceId, &char, voidptr, voidptr) ErrorCode
fn C.clGetProgramBuildInfo(Program, DeviceId, ProgramBuildInfo, usize, voidptr, &usize) ErrorCode
fn C.clReleaseProgram(Program) ErrorCode
fn C.clCreateKernel(Program, &char, &ErrorCode) Kernel
fn C.clSetKernelArg(Kernel, u32, usize, voidptr) ErrorCode
fn C.clReleaseKernel(Kernel) ErrorCode
fn C.clEnqueueNDRangeKernel(CommandQueue, Kernel, u32, &usize, &usize, &usize, u32, &Event, &Event) ErrorCode
fn C.clEnqueueReadBuffer(CommandQueue, Mem, u32, usize, usize, voidptr, u32, &Event, &Event) ErrorCode
fn C.clFinish(CommandQueue) ErrorCode

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

pub fn create_context(properties &isize, num_devices u32, devices &DeviceId,
	pfn_notify voidptr, user_data voidptr, errcode_ret &ErrorCode) Context {
	return C.clCreateContext(properties, num_devices, devices, pfn_notify, user_data, errcode_ret)
}

pub fn release_context(context Context) ErrorCode {
	return C.clReleaseContext(context)
}

pub fn create_command_queue(context Context, device DeviceId,
	properties CommandQueueProperties, errcode_ret &ErrorCode) CommandQueue {
	return C.clCreateCommandQueue(context, device, properties, errcode_ret)
}

pub fn release_command_queue(command_queue CommandQueue) ErrorCode {
	return C.clReleaseCommandQueue(command_queue)
}

pub fn create_buffer(context Context, flags MemFlags, size usize, host_ptr voidptr,
	errcode_ret &ErrorCode) Mem {
	return C.clCreateBuffer(context, flags, size, host_ptr, errcode_ret)
}

pub fn release_mem_object(memobj Mem) ErrorCode {
	return C.clReleaseMemObject(memobj)
}

pub fn create_program_with_source(context Context, count u32, strings &&char,
	lengths &usize, errcode_ret &ErrorCode) Program {
	return C.clCreateProgramWithSource(context, count, strings, lengths, errcode_ret)
}

pub fn build_program(program Program, num_devices u32, device_list &DeviceId,
	options &char, pfn_notify voidptr, user_data voidptr) ErrorCode {
	return C.clBuildProgram(program, num_devices, device_list, options, pfn_notify, user_data)
}

pub fn get_program_build_info(program Program, device DeviceId, param_name ProgramBuildInfo,
	param_value_size usize, param_value voidptr, param_value_size_ret &usize) ErrorCode {
	return C.clGetProgramBuildInfo(program, device, param_name, param_value_size, param_value,
		param_value_size_ret)
}

pub fn release_program(program Program) ErrorCode {
	return C.clReleaseProgram(program)
}

pub fn create_kernel(program Program, kernel_name &char, errcode_ret &ErrorCode) Kernel {
	return C.clCreateKernel(program, kernel_name, errcode_ret)
}

pub fn set_kernel_arg(kernel Kernel, arg_index u32, arg_size usize, arg_value voidptr) ErrorCode {
	return C.clSetKernelArg(kernel, arg_index, arg_size, arg_value)
}

pub fn release_kernel(kernel Kernel) ErrorCode {
	return C.clReleaseKernel(kernel)
}

pub fn enqueue_nd_range_kernel(command_queue CommandQueue, kernel Kernel, work_dim u32,
	global_work_offset &usize, global_work_size &usize, local_work_size &usize,
	num_events_in_wait_list u32, event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueNDRangeKernel(command_queue, kernel, work_dim, global_work_offset,
		global_work_size, local_work_size, num_events_in_wait_list, event_wait_list, event)
}

pub fn enqueue_read_buffer(command_queue CommandQueue, buffer Mem, blocking_read u32,
	offset usize, size usize, ptr voidptr, num_events_in_wait_list u32,
	event_wait_list &Event, event &Event) ErrorCode {
	return C.clEnqueueReadBuffer(command_queue, buffer, blocking_read, offset, size, ptr,
		num_events_in_wait_list, event_wait_list, event)
}

pub fn finish(command_queue CommandQueue) ErrorCode {
	return C.clFinish(command_queue)
}
"""


class OpenCLGenerator:
    def __init__(self, registry: Path):
        self.registry = registry
        self.root: ET.Element | None = None
        self.enums: dict[str, ET.Element] = {}

    def validate_registry(self) -> None:
        if not self.registry.is_file():
            raise FileNotFoundError(f"OpenCL registry not found: {self.registry}")
        self.root = ET.parse(self.registry).getroot()
        commands = {node.get("name") or node.findtext("proto/name") for node in self.root.findall("commands/command")}
        self.enums = {
            node.get("name"): node
            for node in self.root.findall("enums/enum")
            if node.get("name")
            and (node.get("value") is not None or node.get("bitpos") is not None)
        }
        missing_commands = sorted(set(REQUIRED_COMMANDS) - commands)
        required_enums = {name for names in TYPED_CONSTANTS.values() for name in names}
        required_enums.add("CL_PLATFORM_NOT_FOUND_KHR")
        missing_enums = sorted(required_enums - self.enums.keys())
        if missing_commands or missing_enums:
            raise RuntimeError(
                f"Registry is missing commands={missing_commands}, enums={missing_enums}"
            )

    @staticmethod
    def v_name(c_name: str) -> str:
        name = c_name.removeprefix("CL_").lower()
        return f"_{name}" if name in {"false", "true"} else name

    @staticmethod
    def v_value(value: str) -> str:
        value = re.sub(r"(?i)(ull|llu|ul|lu|u|l)$", "", value.strip())
        if value.startswith("(") and value.endswith(")"):
            value = value[1:-1].strip()
        return value

    def constant(self, c_name: str, v_type: str) -> str:
        node = self.enums[c_name]
        value = (f"1 << {node.attrib['bitpos']}" if "bitpos" in node.attrib
                 else self.v_value(node.attrib["value"]))
        return f"pub const {self.v_name(c_name)} = {v_type}({value})"

    def render_constants(self) -> str:
        assert self.root is not None
        error_names = [
            node.attrib["name"]
            for group in self.root.findall("enums")
            if group.attrib.get("name") == "ErrorCodes.0"
            for node in group.findall("enum")
            if node.get("value") is not None
        ]
        error_names.append("CL_PLATFORM_NOT_FOUND_KHR")
        sections = ["\n".join(self.constant(name, "ErrorCode") for name in error_names)]
        for v_type, names in TYPED_CONSTANTS.items():
            sections.append("\n".join(self.constant(name, v_type) for name in names))
        return "\n\n".join(sections)

    def write(self, output: Path) -> None:
        self.validate_registry()
        generated = HEADER.replace("// __REGISTRY_CONSTANTS__", self.render_constants())
        output.write_text(generated, encoding="utf-8")
