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

CORE_FEATURES = (
    "CL_VERSION_1_0", "CL_VERSION_1_1", "CL_VERSION_1_2", "CL_VERSION_2_0",
    "CL_VERSION_2_1", "CL_VERSION_2_2", "CL_VERSION_3_0",
)

PORTABLE_EXTENSIONS = (
    "cl_khr_il_program",
    "cl_khr_create_command_queue",
    "cl_khr_subgroups",
    "cl_khr_suggested_local_work_size",
    "cl_khr_semaphore",
    "cl_khr_external_semaphore",
    "cl_khr_external_semaphore_opaque_fd",
    "cl_khr_external_semaphore_sync_fd",
    "cl_khr_external_memory",
    "cl_khr_external_memory_dma_buf",
    "cl_khr_external_memory_opaque_fd",
    "cl_khr_device_uuid",
)

TYPED_CONSTANTS = {
    "PlatformInfo": (
        "CL_PLATFORM_PROFILE", "CL_PLATFORM_VERSION", "CL_PLATFORM_NAME",
        "CL_PLATFORM_VENDOR", "CL_PLATFORM_EXTENSIONS",
        "CL_PLATFORM_HOST_TIMER_RESOLUTION",
        "CL_PLATFORM_NUMERIC_VERSION", "CL_PLATFORM_EXTENSIONS_WITH_VERSION",
    ),
    "DeviceType": (
        "CL_DEVICE_TYPE_DEFAULT", "CL_DEVICE_TYPE_CPU", "CL_DEVICE_TYPE_GPU",
        "CL_DEVICE_TYPE_ACCELERATOR", "CL_DEVICE_TYPE_CUSTOM", "CL_DEVICE_TYPE_ALL",
    ),
    "DeviceInfo": (
        "CL_DEVICE_NAME", "CL_DEVICE_VENDOR", "CL_DRIVER_VERSION", "CL_DEVICE_VERSION",
        "CL_DEVICE_IL_VERSION", "CL_DEVICE_MAX_NUM_SUB_GROUPS",
        "CL_DEVICE_SUB_GROUP_INDEPENDENT_FORWARD_PROGRESS",
        "CL_DEVICE_NUMERIC_VERSION", "CL_DEVICE_EXTENSIONS_WITH_VERSION",
    ),
    "MemFlags": ("CL_MEM_READ_ONLY", "CL_MEM_WRITE_ONLY", "CL_MEM_COPY_HOST_PTR"),
    "ProgramBuildInfo": ("CL_PROGRAM_BUILD_LOG",),
    "EventInfo": ("CL_EVENT_COMMAND_EXECUTION_STATUS",),
    "i32": ("CL_COMPLETE", "CL_RUNNING", "CL_SUBMITTED", "CL_QUEUED"),
    "Bool": ("CL_FALSE", "CL_TRUE"),
    "u32": (
        "CL_VERSION_MAJOR_BITS", "CL_VERSION_MINOR_BITS", "CL_VERSION_PATCH_BITS",
        "CL_NAME_VERSION_MAX_NAME_SIZE",
    ),
}

PRIMITIVE_TYPES = {
    "char": "i8", "int": "int", "unsigned char": "u8",
    "unsigned int": "u32", "intptr_t": "isize", "size_t": "usize",
    "float": "f32", "double": "f64", "int8_t": "i8", "int16_t": "i16",
    "int32_t": "i32", "int64_t": "i64", "uint8_t": "u8",
    "uint16_t": "u16", "uint32_t": "u32", "uint64_t": "u64",
}

# Keep C arithmetic typedefs convenient for ordinary V values and pointers,
# while preserving semantic OpenCL typedefs in public command signatures.
ABI_SCALAR_TYPES = {
    "cl_char", "cl_uchar", "cl_short", "cl_ushort", "cl_int", "cl_uint",
    "cl_long", "cl_ulong", "cl_float", "cl_double",
}

V_KEYWORDS = {
    "as", "atomic", "break", "const", "continue", "defer", "else", "enum",
    "false", "fn", "for", "global", "go", "if", "import", "in", "interface",
    "is", "lock", "map", "match", "module", "mut", "none", "or", "pub",
    "return", "rlock", "select", "shared", "spawn", "struct", "true", "union",
    "unsafe",
}

CALLBACK_TYPES = {
    "const char* errinfo": (
        "ContextNotifyCallback",
        "fn (errinfo &char, private_info voidptr, cb usize, user_data voidptr)",
    ),
    "cl_context context": (
        "ContextDestructorCallback",
        "fn (context Context, user_data voidptr)",
    ),
    "cl_mem memobj": (
        "MemObjectDestructorCallback",
        "fn (memobj Mem, user_data voidptr)",
    ),
    "cl_program program": (
        "ProgramCallback",
        "fn (program Program, user_data voidptr)",
    ),
    "cl_event event": (
        "EventCallback",
        "fn (event Event, event_command_status i32, user_data voidptr)",
    ),
    "cl_command_queue queue": (
        "SvmFreeCallback",
        "fn (queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, user_data voidptr)",
    ),
    ")(void*)": (
        "NativeKernelCallback",
        "fn (args voidptr)",
    ),
}


HEADER = """// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
module opencl

#flag linux -lOpenCL
#flag windows -lOpenCL
#flag darwin -framework OpenCL
#flag darwin -I@VMODROOT/include
#include <CL/opencl.h>

pub fn make_version(major u32, minor u32, patch u32) u32 {
	return (major << 22) | (minor << 12) | patch
}

pub fn version_major(version u32) u32 {
	return version >> 22
}

pub fn version_minor(version u32) u32 {
	return (version >> 12) & 0x3ff
}

pub fn version_patch(version u32) u32 {
	return version & 0xfff
}

// __REGISTRY_TYPES__
pub type ErrorCode = i32

// __REGISTRY_CONSTANTS__

// __REGISTRY_ERROR_NAMES__

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

# Command declarations and wrappers below the type/constant preamble are
# generated from XML. Keeping the preamble as a readable template makes the
# emitted module easy to review while the registry remains authoritative.
HEADER = HEADER.split("fn C.clGetPlatformIDs", 1)[0] + "// __REGISTRY_COMMANDS__\n"


class OpenCLGenerator:
    def __init__(self, registry: Path):
        self.registry = registry
        self.root: ET.Element | None = None
        self.enums: dict[str, ET.Element] = {}
        self.types: dict[str, ET.Element] = {}

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
        self.types = {
            node.get("name") or node.findtext("name"): node
            for node in self.root.findall("types/type")
            if node.get("name") or node.findtext("name")
        }
        missing_commands = sorted(set(REQUIRED_COMMANDS) - commands)
        required_enums = {name for names in TYPED_CONSTANTS.values() for name in names}
        required_enums.add("CL_PLATFORM_NOT_FOUND_KHR")
        missing_enums = sorted(required_enums - self.enums.keys())
        if missing_commands or missing_enums:
            raise RuntimeError(
                f"Registry is missing commands={missing_commands}, enums={missing_enums}"
            )

    def registry_sections(self) -> list[ET.Element]:
        assert self.root is not None
        names = CORE_FEATURES + PORTABLE_EXTENSIONS
        sections = []
        for name in names:
            path = f"feature[@name='{name}']" if name.startswith("CL_VERSION_") else f"extensions/extension[@name='{name}']"
            section = self.root.find(path)
            if section is None:
                raise RuntimeError(f"Registry is missing API section {name}")
            sections.append(section)
        return sections

    @staticmethod
    def v_name(c_name: str) -> str:
        name = c_name.removeprefix("CL_").lower()
        return f"_{name}" if name in V_KEYWORDS else name

    @classmethod
    def v_value(cls, value: str) -> str:
        value = re.sub(r"(?i)(ull|llu|ul|lu|u|l)$", "", value.strip())
        if value.startswith("(") and value.endswith(")"):
            value = value[1:-1].strip()
        value = re.sub(r"\bCL_[A-Z0-9_]+\b", lambda match: cls.v_name(match.group()), value)
        return value

    def constant(self, c_name: str, v_type: str) -> str:
        node = self.enums[c_name]
        value = (f"1 << {node.attrib['bitpos']}" if "bitpos" in node.attrib
                 else self.v_value(node.attrib["value"]))
        return f"pub const {self.v_name(c_name)} = {v_type}({value})"

    def render_constants(self) -> str:
        assert self.root is not None
        error_names = self.error_code_names()
        emitted = set(error_names)
        sections = ["\n".join(self.constant(name, "ErrorCode") for name in error_names)]
        for v_type, names in TYPED_CONSTANTS.items():
            sections.append("\n".join(self.constant(name, v_type) for name in names))
            emitted.update(names)
        core_constants = []
        for section in self.registry_sections():
            for requirement in section.findall("require"):
                comment = requirement.attrib.get("comment", "")
                if comment == "Error codes":
                    continue
                if comment == "Size Constants":
                    for reference in requirement.findall("enum"):
                        name = reference.attrib["name"]
                        if name in emitted or name not in self.enums:
                            continue
                        core_constants.append(self.constant(name, "u32"))
                        emitted.add(name)
                    continue
                match = re.search(r"\b(cl_[a-z0-9_]+)\b", comment)
                if match is None or comment == "Constants":
                    continue
                c_type = match.group(1)
                if c_type not in self.types and f"{c_type}_khr" in self.types:
                    c_type = f"{c_type}_khr"
                if c_type not in self.types:
                    continue
                v_type = self.type_name(c_type)
                for reference in requirement.findall("enum"):
                    name = reference.attrib["name"]
                    if name in emitted or name not in self.enums:
                        continue
                    core_constants.append(self.constant(name, v_type))
                    emitted.add(name)
        sections.append("\n".join(core_constants))
        return "\n\n".join(sections)

    def error_code_names(self) -> list[str]:
        assert self.root is not None
        names = [
            node.attrib["name"]
            for group in self.root.findall("enums")
            if group.attrib.get("name") == "ErrorCodes.0"
            for node in group.findall("enum")
            if node.get("value") is not None
        ]
        names.append("CL_PLATFORM_NOT_FOUND_KHR")
        for section in self.registry_sections():
            for requirement in section.findall("require"):
                if requirement.attrib.get("comment", "") != "Error codes":
                    continue
                for reference in requirement.findall("enum"):
                    name = reference.attrib["name"]
                    if name in self.enums:
                        names.append(name)
        return list(dict.fromkeys(names))

    def render_error_code_names(self) -> str:
        arms = "\n".join(
            f"\t\t{self.v_name(name)} {{ '{self.v_name(name)}' }}"
            for name in self.error_code_names()
        )
        return (
            "// error_code_name returns the canonical registry name for an OpenCL status code.\n"
            "pub fn error_code_name(status ErrorCode) string {\n"
            "\treturn match status {\n"
            f"{arms}\n"
            "\t\telse { 'opencl_error' }\n"
            "\t}\n"
            "}"
        )

    @staticmethod
    def type_name(c_name: str) -> str:
        name = c_name.removeprefix("cl_")
        return "".join(part[:1].upper() + part[1:] for part in name.split("_"))

    def resolve_type(self, c_name: str, seen: set[str] | None = None) -> str:
        if c_name in PRIMITIVE_TYPES:
            return PRIMITIVE_TYPES[c_name]
        seen = set() if seen is None else seen
        if c_name in seen:
            raise RuntimeError(f"Cyclic OpenCL type alias: {c_name}")
        seen.add(c_name)
        node = self.types.get(c_name)
        if node is None:
            raise RuntimeError(f"Unknown OpenCL type: {c_name}")
        declaration = "".join(node.itertext())
        if "struct " in declaration and "*" in declaration:
            return "voidptr"
        base = node.findtext("type")
        if base is None:
            raise RuntimeError(f"Unsupported OpenCL typedef: {c_name}: {declaration}")
        if base == "void" and "*" in declaration:
            return "voidptr"
        return self.resolve_type(base, seen)

    def render_types(self) -> str:
        assert self.root is not None
        required = list(dict.fromkeys(
            node.attrib["name"]
            for section in self.registry_sections()
            for node in section.findall(".//type")
        ))
        aliases = []
        structs = []
        for c_name in required:
            node = self.types.get(c_name)
            if node is None or node.attrib.get("category") == "include":
                continue
            if node.attrib.get("category") == "struct":
                fields = []
                for member in node.findall("member"):
                    member_type = member.findtext("type")
                    member_name = member.findtext("name")
                    if member_type is None or member_name is None:
                        if c_name == "cl_image_desc" and "union" in "".join(member.itertext()):
                            fields.append("\tbuffer Mem")
                            continue
                        raise RuntimeError(f"Unsupported member in {c_name}")
                    field_type = (self.type_name(member_type)
                                  if member_type.startswith("cl_")
                                  else self.resolve_type(member_type))
                    array_size = member.findtext("enum")
                    if array_size is not None:
                        field_type = f"[{self.v_name(array_size)}]{field_type}"
                    fields.append(f"\t{member_name} {field_type}")
                structs.append(
                    f"pub struct {self.type_name(c_name)} {{\npub mut:\n"
                    + "\n".join(fields) + "\n}"
                )
                continue
            if "".join(node.itertext()).lstrip().startswith("#define"):
                continue
            aliases.append(
                f"pub type {self.type_name(c_name)} = {self.resolve_type(c_name)}"
            )
        windows_callbacks = "\n".join(
            f"\t@[callconv: stdcall]\n\tpub type {name} = {signature}"
            for name, signature in CALLBACK_TYPES.values()
        )
        other_callbacks = "\n".join(
            f"\tpub type {name} = {signature}"
            for name, signature in CALLBACK_TYPES.values()
        )
        callbacks = f"$if windows {{\n{windows_callbacks}\n}} $else {{\n{other_callbacks}\n}}"
        return "\n".join(aliases) + "\n\n" + callbacks + "\n\n" + "\n\n".join(structs)

    def command_type(self, declaration: ET.Element, *, is_return: bool = False) -> str:
        c_type = declaration.findtext("type")
        text = "".join(declaration.itertext())
        name = declaration.findtext("name") or declaration.findtext("proto/name") or ""
        if c_type is None:
            if "(*" in text or "CL_CALLBACK*" in text:
                for marker, (callback_name, _) in CALLBACK_TYPES.items():
                    if marker in text:
                        return callback_name
                raise RuntimeError(f"Unsupported OpenCL callback: {text}")
            raise RuntimeError(f"Unsupported command declaration: {text}")
        type_node = declaration.find("type")
        before_name = (declaration.text or "") + ((type_node.tail or "") if type_node is not None else "")
        pointer_depth = before_name.count("*")
        name_node = declaration.find("name")
        if name_node is not None and "[" in (name_node.tail or ""):
            pointer_depth += 1
        if c_type == "void":
            if is_return and pointer_depth == 0:
                return ""
            return "&" * max(0, pointer_depth - 1) + "voidptr"
        if c_type == "cl_int" and (is_return or name == "errcode_ret"):
            base = "ErrorCode"
        elif c_type == "char":
            base = "char"
        elif c_type.startswith("cl_") and c_type not in ABI_SCALAR_TYPES:
            base = self.type_name(c_type)
        else:
            base = self.resolve_type(c_type)
        return "&" * pointer_depth + base

    def public_command_type(self, declaration: ET.Element) -> str:
        """Return the safe-to-call V type for a generated wrapper parameter.

        OpenCL handles are C pointers represented as ``voidptr`` in V. A C
        pointer to one of those handles therefore has an ABI type such as
        ``&Event`` (``void **`` in C). Exposing that ABI type directly in V is
        unsafe for ordinary ``nil`` and ``slice.data`` arguments: V may take
        the address of the argument expression instead of passing its pointer
        value. Keep the typed pointer in the C/PFN declaration, but accept a
        ``voidptr`` at the public wrapper boundary and cast internally.
        """
        abi_type = self.command_type(declaration)
        if not abi_type.startswith("&"):
            return abi_type
        c_type = declaration.findtext("type")
        if c_type is None:
            return abi_type
        try:
            resolved = "voidptr" if c_type == "void" else self.resolve_type(c_type)
        except RuntimeError:
            return abi_type
        return "voidptr" if resolved == "voidptr" else abi_type

    @staticmethod
    def public_call_argument(name: str, abi_type: str, public_type: str) -> str:
        if public_type == "voidptr" and abi_type.startswith("&"):
            return f"unsafe {{ {abi_type}({name}) }}"
        return name

    @staticmethod
    def command_name(c_name: str) -> str:
        bare = c_name.removeprefix("cl")
        for acronym, normalized in (
            ("IDs", "Ids"), ("NDRange", "NdRange"), ("SVM", "Svm"), ("IL", "Il"),
        ):
            bare = bare.replace(acronym, normalized)
        first = re.sub(r"(.)([A-Z][a-z]+)", r"\1_\2", bare)
        snake = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", first).lower()
        return re.sub(r"(?<=\d)_([a-z])", r"\1", snake)

    def render_commands(self) -> str:
        assert self.root is not None
        by_name = {
            node.findtext("proto/name"): node
            for node in self.root.findall("commands/command")
            if node.find("proto") is not None
        }
        declarations = []
        extension_types = []
        wrappers = []
        core_command_names = {
            node.attrib["name"]
            for feature_name in CORE_FEATURES
            for node in self.root.find(f"feature[@name='{feature_name}']").findall(".//command")
        }
        command_names = list(dict.fromkeys(
            node.attrib["name"]
            for section in self.registry_sections()
            for node in section.findall(".//command")
        ))
        for c_name in command_names:
            command = by_name[c_name]
            return_type = self.command_type(command.find("proto"), is_return=True)
            params = []
            param_names = []
            for param in command.findall("param"):
                param_name = param.findtext("name")
                if param_name is None:
                    raise RuntimeError(f"Unnamed parameter in {c_name}")
                abi_type = self.command_type(param)
                public_type = self.public_command_type(param)
                params.append((param_name, abi_type, public_type))
                param_names.append(param_name)
            c_signature = ", ".join(abi_type for _, abi_type, _ in params)
            signature = f"fn ({c_signature})" + (f" {return_type}" if return_type else "")
            is_extension = c_name not in core_command_names
            if is_extension:
                extension_types.append((f"PFN_{c_name}", signature))
            else:
                declarations.append(
                    f"fn C.{c_name}({c_signature})" + (f" {return_type}" if return_type else "")
                )
            v_params = ", ".join(
                f"{name} {public_type}" for name, _, public_type in params
            )
            call_arguments = [
                self.public_call_argument(name, abi_type, public_type)
                for name, abi_type, public_type in params
            ]
            if is_extension:
                pointer_type = f"PFN_{c_name}"
                lines = [
                    f"\textension_fn := unsafe {{ {pointer_type}(C.clGetExtensionFunctionAddress(c'{c_name}')) }}",
                    "\tif isnil(extension_fn) {",
                ]
                if return_type == "ErrorCode":
                    lines.append("\t\treturn invalid_operation")
                elif return_type and self.resolve_type(command.findtext("proto/type")) == "voidptr":
                    if "errcode_ret" in param_names:
                        lines.extend([
                            "\t\tif !isnil(errcode_ret) {",
                            "\t\t\tunsafe { *errcode_ret = invalid_operation }",
                            "\t\t}",
                        ])
                    lines.append(f"\t\treturn {return_type}(unsafe {{ nil }})")
                else:
                    raise RuntimeError(f"Unsupported extension fallback return type for {c_name}")
                lines.append("\t}")
                call = f"extension_fn({', '.join(call_arguments)})"
                lines.append(f"\treturn {call}" if return_type else f"\t{call}")
                body = "\n".join(lines)
            else:
                call = f"C.{c_name}({', '.join(call_arguments)})"
                body = f"\treturn {call}" if return_type else f"\t{call}"
            wrappers.append(
                f"@[inline]\npub fn {self.command_name(c_name)}({v_params})"
                + (f" {return_type}" if return_type else "")
                + f" {{\n{body}\n}}"
            )
        windows_extension_types = "\n".join(
            f"\t@[callconv: stdcall]\n\tpub type {name} = {signature}"
            for name, signature in extension_types
        )
        other_extension_types = "\n".join(
            f"\tpub type {name} = {signature}"
            for name, signature in extension_types
        )
        extension_type_block = (
            f"$if windows {{\n{windows_extension_types}\n}} $else {{\n{other_extension_types}\n}}"
        )
        return ("\n".join(declarations) + "\n\n" + extension_type_block
                + "\n\n" + "\n\n".join(wrappers))

    def write(self, output: Path) -> None:
        self.validate_registry()
        generated = HEADER.replace("// __REGISTRY_TYPES__", self.render_types())
        generated = generated.replace("// __REGISTRY_CONSTANTS__", self.render_constants())
        generated = generated.replace("// __REGISTRY_ERROR_NAMES__", self.render_error_code_names())
        generated = generated.replace("// __REGISTRY_COMMANDS__", self.render_commands())
        output.write_text(generated, encoding="utf-8")
