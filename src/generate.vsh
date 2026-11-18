// Deterministic OpenCL XML-to-V generator.
import encoding.xml
import flag
import os
import strings

struct Callback {
	name      string
	signature string
}

const required_commands = ['clGetPlatformIDs', 'clGetPlatformInfo', 'clGetDeviceIDs',
	'clGetDeviceInfo', 'clCreateContext', 'clReleaseContext', 'clCreateCommandQueue',
	'clReleaseCommandQueue', 'clCreateBuffer', 'clReleaseMemObject', 'clCreateProgramWithSource',
	'clBuildProgram', 'clGetProgramBuildInfo', 'clReleaseProgram', 'clCreateKernel', 'clSetKernelArg',
	'clReleaseKernel', 'clEnqueueNDRangeKernel', 'clEnqueueReadBuffer', 'clFinish']
// OpenCL 3.0 remains the supported link-time ABI.
const linked_core_limit = FeatureVersion{3, 0}
// Apple's framework exposes linked OpenCL symbols through version 1.2.
const apple_framework_limit = FeatureVersion{1, 2}

struct FeatureVersion {
	major int
	minor int
}

fn (version FeatureVersion) above(limit FeatureVersion) bool {
	return version.major > limit.major
		|| (version.major == limit.major && version.minor > limit.minor)
}

const portable_extensions = ['cl_khr_il_program', 'cl_khr_create_command_queue', 'cl_khr_subgroups',
	'cl_khr_suggested_local_work_size', 'cl_khr_semaphore', 'cl_khr_external_semaphore',
	'cl_khr_external_semaphore_opaque_fd', 'cl_khr_external_semaphore_sync_fd',
	'cl_khr_external_memory', 'cl_khr_external_memory_dma_buf', 'cl_khr_external_memory_opaque_fd',
	'cl_khr_device_uuid']
const typed_constants = {
	'PlatformInfo':     ['CL_PLATFORM_PROFILE', 'CL_PLATFORM_VERSION', 'CL_PLATFORM_NAME',
		'CL_PLATFORM_VENDOR', 'CL_PLATFORM_EXTENSIONS', 'CL_PLATFORM_HOST_TIMER_RESOLUTION',
		'CL_PLATFORM_NUMERIC_VERSION', 'CL_PLATFORM_EXTENSIONS_WITH_VERSION']
	'DeviceType':       ['CL_DEVICE_TYPE_DEFAULT', 'CL_DEVICE_TYPE_CPU', 'CL_DEVICE_TYPE_GPU',
		'CL_DEVICE_TYPE_ACCELERATOR', 'CL_DEVICE_TYPE_CUSTOM', 'CL_DEVICE_TYPE_ALL']
	'DeviceInfo':       ['CL_DEVICE_NAME', 'CL_DEVICE_VENDOR', 'CL_DRIVER_VERSION',
		'CL_DEVICE_VERSION', 'CL_DEVICE_IL_VERSION', 'CL_DEVICE_MAX_NUM_SUB_GROUPS',
		'CL_DEVICE_SUB_GROUP_INDEPENDENT_FORWARD_PROGRESS', 'CL_DEVICE_NUMERIC_VERSION',
		'CL_DEVICE_EXTENSIONS_WITH_VERSION']
	'MemFlags':         ['CL_MEM_READ_ONLY', 'CL_MEM_WRITE_ONLY', 'CL_MEM_COPY_HOST_PTR']
	'ProgramBuildInfo': ['CL_PROGRAM_BUILD_LOG']
	'EventInfo':        ['CL_EVENT_COMMAND_EXECUTION_STATUS']
	'i32':              ['CL_COMPLETE', 'CL_RUNNING', 'CL_SUBMITTED', 'CL_QUEUED']
	'Bool':             ['CL_FALSE', 'CL_TRUE']
	'u32':              ['CL_VERSION_MAJOR_BITS', 'CL_VERSION_MINOR_BITS', 'CL_VERSION_PATCH_BITS',
		'CL_NAME_VERSION_MAX_NAME_SIZE']
}
const primitive_types = {
	'char':          'i8'
	'int':           'int'
	'unsigned char': 'u8'
	'unsigned int':  'u32'
	'intptr_t':      'isize'
	'size_t':        'usize'
	'float':         'f32'
	'double':        'f64'
	'int8_t':        'i8'
	'int16_t':       'i16'
	'int32_t':       'i32'
	'int64_t':       'i64'
	'uint8_t':       'u8'
	'uint16_t':      'u16'
	'uint32_t':      'u32'
	'uint64_t':      'u64'
}
const abi_scalar_types = ['cl_char', 'cl_double', 'cl_float', 'cl_int', 'cl_long', 'cl_short',
	'cl_uchar', 'cl_uint', 'cl_ulong', 'cl_ushort']
const v_keywords = ['as', 'atomic', 'break', 'const', 'continue', 'defer', 'else', 'enum', 'false',
	'fn', 'for', 'global', 'go', 'if', 'import', 'in', 'interface', 'is', 'lock', 'map', 'match',
	'module', 'mut', 'none', 'or', 'pub', 'return', 'rlock', 'select', 'shared', 'spawn', 'struct',
	'true', 'union', 'unsafe']
const callback_types = {
	'const char* errinfo':    Callback{'ContextNotifyCallback', 'fn (errinfo &char, private_info voidptr, cb usize, user_data voidptr)'}
	'cl_context context':     Callback{'ContextDestructorCallback', 'fn (context Context, user_data voidptr)'}
	'cl_mem memobj':          Callback{'MemObjectDestructorCallback', 'fn (memobj Mem, user_data voidptr)'}
	'cl_program program':     Callback{'ProgramCallback', 'fn (program Program, user_data voidptr)'}
	'cl_event event':         Callback{'EventCallback', 'fn (event Event, event_command_status i32, user_data voidptr)'}
	'cl_command_queue queue': Callback{'SvmFreeCallback', 'fn (queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, user_data voidptr)'}
	')(void*)':               Callback{'NativeKernelCallback', 'fn (args voidptr)'}
}
const header = '// Code generated from the Khronos OpenCL XML API Registry. DO NOT EDIT.
// Raw OpenCL constants, types and entry points; resource lifetimes follow the C API.
// Regenerate in antono2/v_opencl_bindings with python3 src/main.py.
module opencl

$if opencl_dynamic ? {
	#flag linux -ldl -pthread
	#include "@VMODROOT/include/opencl_runtime.h"
} $else {
	#flag linux -lOpenCL
	#flag windows -lOpenCL
	#flag darwin -framework OpenCL
}
#flag windows -I@VMODROOT/include
#flag windows -L@VMODROOT/lib
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

// __REGISTRY_COMMANDS__
'

struct Registry {
	root     xml.XMLNode
	enums    map[string]xml.XMLNode
	types    map[string]xml.XMLNode
	commands map[string]xml.XMLNode
	core     []xml.XMLNode
	sections []xml.XMLNode
	later    []string
}

fn children(node xml.XMLNode, tag string) []xml.XMLNode {
	mut result := []xml.XMLNode{}
	for item in node.children {
		if item is xml.XMLNode && item.name == tag {
			result << item
		}
	}
	return result
}

fn first(node xml.XMLNode, tag string) ?xml.XMLNode {
	for item in node.children {
		if item is xml.XMLNode && item.name == tag {
			return item
		}
	}
	return none
}

fn text_content(node xml.XMLNode) string {
	mut text := ''
	for item in node.children {
		match item {
			string { text += item }
			xml.XMLNode { text += text_content(item) }
			xml.XMLCData { text += item.text }
			else {}
		}
	}
	return text
}

fn child_text(node xml.XMLNode, tag string) string {
	item := first(node, tag) or { return '' }
	return text_content(item)
}

fn feature_version(feature xml.XMLNode) !FeatureVersion {
	number := feature.attributes['number']
	parts := number.split('.')
	if parts.len != 2 || !parts.all(it != '' && it.bytes().all(it.is_digit())) {
		return error('Invalid OpenCL feature version: ${feature.attributes['name']}: ${number}')
	}
	return FeatureVersion{parts[0].int(), parts[1].int()}
}

// The oldest supported V XML reader expects compact attribute separators.
fn compact_attribute_separators(input string) string {
	mut output := strings.new_builder(input.len)
	mut in_tag := false
	mut quote := u8(0)
	for i := 0; i < input.len; {
		byte := input[i]
		if !in_tag && byte == `<` && i + 1 < input.len {
			mut terminator := ''
			for delimiter in [['<!--', '-->'], ['<![CDATA[', ']]>']] {
				if i + delimiter[0].len <= input.len
					&& input[i..i + delimiter[0].len] == delimiter[0] {
					terminator = delimiter[1]
					break
				}
			}
			if terminator != '' {
				end := input.index_after(terminator, i + 2) or { input.len - terminator.len }
				last := end + terminator.len
				output.write_string(input[i..last])
				i = last
				continue
			}
			in_tag = input[i + 1].is_letter() || input[i + 1] == `_` || input[i + 1] == `?`
		}
		if in_tag {
			if quote != 0 {
				if byte == quote {
					quote = 0
				}
			} else if byte == `"` || byte == 39 {
				quote = byte
			} else if byte == `>` {
				in_tag = false
			} else if byte in [u8(32), 9, 10, 13] {
				start := i
				for i < input.len && input[i] in [u8(32), 9, 10, 13] {
					i++
				}
				if (i >= input.len || input[i] != `=`) && (start == 0 || input[start - 1] != `=`) {
					output.write_string(input[start..i])
				}
				continue
			}
		}
		output.write_u8(byte)
		i++
	}
	return output.str()
}

fn read_registry(path string) !Registry {
	if !os.is_file(path) {
		return error('OpenCL registry not found: ${path}')
	}
	doc := xml.XMLDocument.from_string(compact_attribute_separators(os.read_file(path)!))!
	root := doc.root
	mut enums := map[string]xml.XMLNode{}
	mut types := map[string]xml.XMLNode{}
	mut commands := map[string]xml.XMLNode{}
	mut declared_commands := map[string]bool{}
	for group in children(root, 'enums') {
		for node in children(group, 'enum') {
			name := node.attributes['name']
			if name != '' && ('value' in node.attributes || 'bitpos' in node.attributes) {
				enums[name] = node
			}
		}
	}
	for group in children(root, 'types') {
		for node in children(group, 'type') {
			name := node.attributes['name']
			c_name := if name != '' { name } else { child_text(node, 'name') }
			if c_name != '' {
				types[c_name] = node
			}
		}
	}
	for group in children(root, 'commands') {
		for node in children(group, 'command') {
			if name := node.attributes['name'] {
				declared_commands[name] = true
			}
			if proto := first(node, 'proto') {
				name := child_text(proto, 'name')
				commands[name] = node
				declared_commands[name] = true
			}
		}
	}
	missing_commands := required_commands.filter(it !in declared_commands).sorted()
	mut missing_enums := []string{}
	for names in typed_constants.values() {
		missing_enums << names.filter(it !in enums)
	}
	if 'CL_PLATFORM_NOT_FOUND_KHR' !in enums {
		missing_enums << 'CL_PLATFORM_NOT_FOUND_KHR'
	}
	if missing_commands.len > 0 || missing_enums.len > 0 {
		return error('Registry is missing commands=${missing_commands}, enums=${missing_enums.sorted()}')
	}

	mut core := []xml.XMLNode{}
	mut later := []string{}
	for feature in children(root, 'feature') {
		if feature.attributes['api'] != 'opencl' {
			continue
		}
		version := feature_version(feature)!
		if !version.above(linked_core_limit) {
			core << feature
		} else {
			later << (feature.attributes['name'] or { feature.attributes['number'] })
		}
	}
	if core.len == 0 {
		return error('Registry has no supported OpenCL core features')
	}
	mut extensions := map[string]xml.XMLNode{}
	for group in children(root, 'extensions') {
		for node in children(group, 'extension') {
			extensions[node.attributes['name']] = node
		}
	}
	mut sections := core.clone()
	for name in portable_extensions {
		sections << (extensions[name] or { return error('Registry is missing API section ${name}') })
	}
	return Registry{
		root:     root
		enums:    enums
		types:    types
		commands: commands
		core:     core
		sections: sections
		later:    later
	}
}

fn v_name(c_name string) string {
	name := if c_name.starts_with('CL_') {
		c_name[3..].to_lower_ascii()
	} else {
		c_name.to_lower_ascii()
	}
	return if name in v_keywords { '_' + name } else { name }
}

fn is_lower(byte u8) bool {
	return byte >= `a` && byte <= `z`
}

fn is_word(byte u8) bool {
	return byte.is_letter() || byte.is_digit() || byte == `_`
}

fn v_value(input string) string {
	mut value := input.trim_space()
	for suffix in ['ull', 'llu', 'ul', 'lu', 'u', 'l'] {
		if value.to_lower_ascii().ends_with(suffix) {
			value = value[..value.len - suffix.len]
			break
		}
	}
	if value.starts_with('(') && value.ends_with(')') {
		value = value[1..value.len - 1].trim_space()
	}
	mut output := ''
	for i := 0; i < value.len; {
		start := i
		if is_word(value[i]) {
			for i < value.len && is_word(value[i]) {
				i++
			}
			word := value[start..i]
			output += if word.len > 3 && word.starts_with('CL_') && word.bytes().all(!is_lower(it)) {
				v_name(word)
			} else {
				word
			}
		} else {
			i++
			output += value[start..i]
		}
	}
	return output
}

fn type_name(c_name string) string {
	bare := if c_name.starts_with('cl_') { c_name[3..] } else { c_name }
	return bare.split('_').filter(it != '').map(it[..1].to_upper_ascii() + it[1..]).join('')
}

fn (registry Registry) resolve_type(c_name string, seen []string) !string {
	if primitive := primitive_types[c_name] {
		return primitive
	}
	if c_name in seen {
		return error('Cyclic OpenCL type alias: ${c_name}')
	}
	node := registry.types[c_name] or { return error('Unknown OpenCL type: ${c_name}') }
	declaration := text_content(node)
	base := child_text(node, 'type')
	if declaration.contains('*') && (declaration.contains('struct ') || base == 'void') {
		return 'voidptr'
	}
	if base == '' {
		return error('Unsupported OpenCL typedef: ${c_name}: ${declaration}')
	}
	mut next := seen.clone()
	next << c_name
	return registry.resolve_type(base, next)
}

fn ordered_names(sections []xml.XMLNode, tag string) []string {
	mut names := map[string]bool{}
	for section in sections {
		for field in section.get_elements_by_tag(tag) {
			names[field.attributes['name']] = true
		}
	}
	return names.keys()
}

fn (registry Registry) error_names() []string {
	mut names := map[string]bool{}
	for group in children(registry.root, 'enums') {
		if group.attributes['name'] == 'ErrorCodes.0' {
			for node in children(group, 'enum') {
				if 'value' in node.attributes {
					names[node.attributes['name']] = true
				}
			}
		}
	}
	names['CL_PLATFORM_NOT_FOUND_KHR'] = true
	for section in registry.sections {
		for requirement in children(section, 'require') {
			if requirement.attributes['comment'] != 'Error codes' {
				continue
			}
			for reference in children(requirement, 'enum') {
				name := reference.attributes['name']
				if name in registry.enums {
					names[name] = true
				}
			}
		}
	}
	return names.keys()
}

fn (registry Registry) constant(c_name string, v_type string) string {
	node := registry.enums[c_name]
	value := if bit := node.attributes['bitpos'] {
		'1 << ${bit}'
	} else {
		v_value(node.attributes['value'])
	}
	return 'pub const ${v_name(c_name)} = ${v_type}(${value})'
}

fn (registry Registry) render_constants() string {
	mut emitted := map[string]bool{}
	mut sections := []string{}
	error_names := registry.error_names()
	for name in error_names {
		emitted[name] = true
	}
	sections << error_names.map(registry.constant(it, 'ErrorCode')).join('\n')
	for v_type, names in typed_constants {
		for name in names {
			emitted[name] = true
		}
		sections << names.map(registry.constant(it, v_type)).join('\n')
	}
	mut core := []string{}
	for section in registry.sections {
		for requirement in children(section, 'require') {
			comment := requirement.attributes['comment']
			mut value_type := ''
			if comment == 'Size Constants' {
				value_type = 'u32'
			} else if comment !in ['Error codes', 'Constants'] {
				mut c_type := ''
				for word in comment.split_any(' \t(),:;') {
					if word.starts_with('cl_') && word.bytes().all(is_lower(it)
						|| it.is_digit() || it == `_`) {
						c_type = word
						break
					}
				}
				if c_type !in registry.types && c_type + '_khr' in registry.types {
					c_type += '_khr'
				}
				if c_type in registry.types {
					value_type = type_name(c_type)
				}
			}
			if value_type == '' {
				continue
			}
			for reference in children(requirement, 'enum') {
				name := reference.attributes['name']
				if name !in emitted && name in registry.enums {
					emitted[name] = true
					core << registry.constant(name, value_type)
				}
			}
		}
	}
	sections << core.join('\n')
	return sections.join('\n\n')
}

fn (registry Registry) render_error_names() string {
	mut lines := [
		'// error_code_name returns the canonical registry name for an OpenCL status code.',
		'pub fn error_code_name(status ErrorCode) string {',
		'\treturn match status {',
	]
	for c_name in registry.error_names() {
		name := v_name(c_name)
		lines << "\t\t${name} { '${name}' }"
	}
	lines << ["\t\telse { 'opencl_error' }", '\t}', '}']
	return lines.join('\n')
}

fn platform_types(items []string) string {
	return '\$if windows {\n' + items.map('\t@[callconv: stdcall]\n\t' + it).join('\n') +
		'\n} \$else {\n' + items.map('\t' + it).join('\n') + '\n}'
}

fn (registry Registry) render_types() !string {
	mut aliases := []string{}
	mut structs := []string{}
	for c_name in ordered_names(registry.sections, 'type') {
		node := registry.types[c_name] or { continue }
		category := node.attributes['category']
		if category == 'include' {
			continue
		}
		if category == 'struct' {
			mut fields := []string{}
			for member in children(node, 'member') {
				member_type := child_text(member, 'type')
				member_name := child_text(member, 'name')
				if member_type == '' || member_name == '' {
					if c_name == 'cl_image_desc' && text_content(member).contains('union') {
						fields << '\tbuffer Mem'
						continue
					}
					return error('Unsupported member in ${c_name}')
				}
				mut field_type := if member_type.starts_with('cl_') {
					type_name(member_type)
				} else {
					registry.resolve_type(member_type, [])!
				}
				array_size := child_text(member, 'enum')
				if array_size != '' {
					field_type = '[${v_name(array_size)}]${field_type}'
				}
				fields << '\t${member_name} ${field_type}'
			}
			structs << 'pub struct ${type_name(c_name)} {\npub mut:\n' + fields.join('\n') + '\n}'
		} else if !text_content(node).trim_space().starts_with('#define') {
			aliases << 'pub type ${type_name(c_name)} = ${registry.resolve_type(c_name, [])!}'
		}
	}
	callbacks := callback_types.values().map('pub type ${it.name} = ${it.signature}')
	return aliases.join('\n') + '\n\n' + platform_types(callbacks) + '\n\n' + structs.join('\n\n')
}

fn (registry Registry) command_type(decl xml.XMLNode, is_return bool) !string {
	c_type := child_text(decl, 'type')
	name := child_text(decl, 'name')
	if c_type == '' {
		text := text_content(decl)
		if text.contains('(*') || text.contains('CL_CALLBACK*') {
			for marker, callback in callback_types {
				if text.contains(marker) {
					return callback.name
				}
			}
			return error('Unsupported OpenCL callback: ${text}')
		}
		return error('Unsupported command declaration: ${text}')
	}
	mut depth := 0
	mut after_name := false
	for item in decl.children {
		match item {
			xml.XMLNode {
				if item.name == 'name' {
					after_name = true
				}
			}
			string {
				if !after_name {
					depth += item.count('*')
				} else if item.contains('[') {
					depth++
				}
			}
			else {}
		}
	}
	if c_type == 'void' {
		if is_return && depth == 0 {
			return ''
		}
		return '&'.repeat(if depth > 0 { depth - 1 } else { 0 }) + 'voidptr'
	}
	base := match true {
		c_type == 'cl_int' && (is_return || name == 'errcode_ret') { 'ErrorCode' }
		c_type == 'char' { 'char' }
		c_type.starts_with('cl_') && c_type !in abi_scalar_types { type_name(c_type) }
		else { registry.resolve_type(c_type, [])! }
	}

	return '&'.repeat(depth) + base
}

fn (registry Registry) public_parameter(decl xml.XMLNode, abi_type string) string {
	// Keep C/PFN pointer types. Public handle arrays accept nil or slice.data
	// as pointer values without V introducing an additional address-of.
	if !abi_type.starts_with('&') {
		return abi_type
	}
	c_type := child_text(decl, 'type')
	resolved := if c_type == 'void' {
		'voidptr'
	} else {
		registry.resolve_type(c_type, []) or { return abi_type }
	}
	return if resolved == 'voidptr' { 'voidptr' } else { abi_type }
}

fn command_name(c_name string) string {
	mut bare := if c_name.starts_with('cl') { c_name[2..] } else { c_name }
	for pair in [['IDs', 'Ids'], ['NDRange', 'NdRange'], ['SVM', 'Svm'],
		['IL', 'Il']] {
		bare = bare.replace(pair[0], pair[1])
	}
	mut output := ''
	for i, byte in bare.bytes() {
		if i > 0 && byte.is_capital() {
			previous := bare[i - 1]
			if is_lower(previous)
				|| (previous.is_capital() && i + 1 < bare.len && is_lower(bare[i + 1])) {
				output += '_'
			}
		}
		output += byte.ascii_str().to_lower_ascii()
	}
	return output
}

fn call_line(indent string, return_type string, expression string) string {
	return indent + (if return_type != '' {
		'return '
	} else {
		''
	}) + expression
}

fn unavailable_return(return_type string, args []string) []string {
	mut lines := []string{}
	if 'errcode_ret' in args {
		lines << ['\t\t\tif !isnil(errcode_ret) {',
			'\t\t\t\tunsafe { *errcode_ret = invalid_operation }', '\t\t\t}']
	}
	lines << match return_type {
		'ErrorCode' { '\t\t\treturn invalid_operation' }
		'' { '\t\t\treturn' }
		else { '\t\t\treturn ${return_type}(unsafe { nil })' }
	}

	return lines
}

fn linked_wrapper(c_name string, return_type string, args []string, cast_args string, unavailable_on_macos bool) string {
	unavailable := unavailable_return(return_type, args).join('\n')
	dynamic_lines := [
		"\t\tcommand := unsafe { PFN_${c_name}(C.vcl_symbol(c'${c_name}')) }",
		'\t\tif isnil(command) {',
		unavailable,
		'\t\t}',
		call_line('\t\t', return_type, 'command(${cast_args})'),
	]
	linked := call_line('\t\t', return_type, 'C.${c_name}(${cast_args})')
	linked_body := if unavailable_on_macos {
		'\t\t\$if macos {\n${unavailable}\n\t\t} \$else {\n\t${linked}\n\t\t}'
	} else {
		linked
	}
	return '\t\$if opencl_dynamic ? {\n' + dynamic_lines.join('\n') +
		'\n\t} \$else {\n${linked_body}\n\t}'
}

fn (registry Registry) extension_wrapper(c_name string, proto xml.XMLNode, return_type string, args []string, cast_args string) !string {
	mut lines := [
		"\textension_fn := unsafe { PFN_${c_name}(get_extension_function_address(c'${c_name}')) }",
		'\tif isnil(extension_fn) {',
	]
	if return_type == 'ErrorCode' {
		lines << '\t\treturn invalid_operation'
	} else if return_type != ''
		&& registry.resolve_type(child_text(proto, 'type'), [])! == 'voidptr' {
		if 'errcode_ret' in args {
			lines << ['\t\tif !isnil(errcode_ret) {',
				'\t\t\tunsafe { *errcode_ret = invalid_operation }', '\t\t}']
		}
		lines << '\t\treturn ${return_type}(unsafe { nil })'
	} else {
		return error('Unsupported extension fallback return type for ${c_name}')
	}
	lines << '\t}'
	lines << call_line('\t', return_type, 'extension_fn(${cast_args})')
	return lines.join('\n')
}

fn (registry Registry) render_commands() !string {
	core := ordered_names(registry.core, 'command')
	mut post_apple := []string{}
	for feature in registry.core {
		version := feature_version(feature)!
		if version.above(apple_framework_limit) {
			post_apple << ordered_names([feature], 'command')
		}
	}
	mut declarations := []string{}
	mut extension_types := []string{}
	mut wrappers := []string{}
	for c_name in ordered_names(registry.sections, 'command') {
		node := registry.commands[c_name] or { return error('Missing command ${c_name}') }
		proto := first(node, 'proto') or { return error('Missing prototype for ${c_name}') }
		return_type := registry.command_type(proto, true)!
		return_suffix := if return_type == '' { '' } else { ' ' + return_type }
		mut abi_params := []string{}
		mut public_params := []string{}
		mut args := []string{}
		mut cast_args := []string{}
		for param in children(node, 'param') {
			name := child_text(param, 'name')
			if name == '' {
				return error('Unnamed parameter in ${c_name}')
			}
			abi_type := registry.command_type(param, false)!
			public_type := registry.public_parameter(param, abi_type)
			args << name
			abi_params << abi_type
			public_params << '${name} ${public_type}'
			cast_args << if public_type == 'voidptr' && abi_type.starts_with('&') {
				'unsafe { ${abi_type}(${name}) }'
			} else {
				name
			}
		}
		signature := '(' + abi_params.join(', ') + ')' + return_suffix
		extension_types << 'pub type PFN_${c_name} = fn ${signature}'
		body := if c_name in core {
			declarations << 'fn C.${c_name}${signature}'
			linked_wrapper(c_name, return_type, args, cast_args.join(', '), c_name in post_apple)
		} else {
			registry.extension_wrapper(c_name, proto, return_type, args, cast_args.join(', '))!
		}
		wrappers << '@[inline]\npub fn ${command_name(c_name)}(' + public_params.join(', ') + ')' +
			return_suffix + ' {\n${body}\n}'
	}
	return declarations.join('\n') + '\n\n' + platform_types(extension_types) + '\n\n' +
		wrappers.join('\n\n')
}

fn (registry Registry) render() !string {
	return header.replace('// __REGISTRY_TYPES__', registry.render_types()!)
		.replace('// __REGISTRY_CONSTANTS__', registry.render_constants())
		.replace('// __REGISTRY_ERROR_NAMES__', registry.render_error_names())
		.replace('// __REGISTRY_COMMANDS__', registry.render_commands()!)
}

fn test_generator(registry Registry) ! {
	generated := registry.render()!
	assert generated == registry.render()!

	// Values are read from registry.
	assert generated.contains('pub const invalid_value = ErrorCode(-30)')
	assert generated.contains('pub const device_type_gpu = DeviceType(1 << 2)')
	assert generated.contains('pub const platform_name = PlatformInfo(0x0902)')

	// Platform link and header flags are generated.
	assert generated.contains('#flag linux -lOpenCL')
	assert generated.contains('#flag windows -lOpenCL')
	assert generated.contains('#flag windows -I@VMODROOT/include')
	assert generated.contains('#flag windows -L@VMODROOT/lib')
	assert generated.contains('#flag darwin -framework OpenCL')
	assert generated.contains('#flag darwin -I@VMODROOT/include')
	assert generated.contains('#include <CL/opencl.h>')

	// Complete core error range is emitted.
	assert generated.contains('pub const success = ErrorCode(0)')
	assert generated.contains('pub const max_size_restriction_exceeded = ErrorCode(-72)')
	assert generated.contains('pub const platform_not_found_khr = ErrorCode(-1001)')

	// Error names are generated from the registry.
	assert generated.contains("invalid_event_wait_list { 'invalid_event_wait_list' }")
	assert generated.contains("invalid_semaphore_khr { 'invalid_semaphore_khr' }")
	assert generated.contains("else { 'opencl_error' }")

	// Complete core api constants are emitted.
	assert generated.contains('pub const device_max_compute_units = DeviceInfo(0x1002)')
	assert generated.contains('pub const mem_read_write = MemFlags(1 << 0)')
	assert generated.contains('pub const rgba = ChannelOrder(0x10B5)')
	assert generated.contains('pub const command_svm_migrate_mem = CommandType(0x120E)')
	assert generated.contains('pub const blocking = Bool(_true)')
	assert generated.contains('pub const non_blocking = Bool(_false)')
	assert generated.contains('pub const _global = DeviceLocalMemType(0x2)')
	assert generated.contains('pub const _none = DeviceMemCacheType(0x0)')
	assert generated.count('pub const ') == 503

	// Opencl 1 0 types and structs are emitted.
	assert generated.contains('pub type PlatformId = voidptr')
	assert generated.contains('pub type ContextProperties = isize')
	assert generated.contains('pub type DeviceType = u64')
	assert generated.contains('pub struct ImageFormat')
	assert generated.contains('image_channel_data_type ChannelType')
	assert generated.contains('pub struct BufferRegion')

	// Core callback types are emitted and used.
	assert generated.contains('$if windows {')
	assert generated.count('@[callconv: stdcall]') == 135
	assert generated.contains('pub type ContextNotifyCallback = fn (errinfo &char, private_info voidptr, cb usize, user_data voidptr)')
	assert generated.contains('pub type EventCallback = fn (event Event, event_command_status i32, user_data voidptr)')
	assert generated.contains('pub type SvmFreeCallback = fn (queue CommandQueue, num_svm_pointers u32, svm_pointers &voidptr, user_data voidptr)')
	assert generated.contains('fn C.clCreateContext(&ContextProperties, u32, &DeviceId, ContextNotifyCallback')
	assert generated.contains('pub fn set_event_callback(event Event, command_exec_callback_type i32, pfn_notify EventCallback')
	assert generated.contains('pub fn enqueue_native_kernel(command_queue CommandQueue, user_func NativeKernelCallback')

	// Opencl 1 0 commands are generated from xml.
	assert generated.contains('fn C.clCreateContext(&ContextProperties, u32, &DeviceId, ContextNotifyCallback')
	assert generated.contains('pub fn get_platform_ids(')
	assert generated.contains('pub fn enqueue_nd_range_kernel(')
	assert generated.contains('pub fn get_supported_image_formats(')
	assert generated.count('@[inline]\npub fn ') == 128

	// Command signatures preserve semantic typedefs.
	assert generated.contains('fn C.clGetDeviceIDs(PlatformId, DeviceType, u32')
	assert generated.contains('pub fn get_device_info(device DeviceId, param_name DeviceInfo')
	assert generated.contains('pub fn create_buffer(context Context, flags MemFlags')
	assert generated.contains('pub fn enqueue_read_buffer(command_queue CommandQueue, buffer Mem, blocking_read Bool')
	assert generated.contains('pub fn create_semaphore_with_properties_khr(context Context, sema_props &SemaphorePropertiesKhr')
	assert generated.contains('handle_type ExternalSemaphoreHandleTypeKhr')

	// Opaque handle arrays use voidptr at public boundary.
	assert generated.contains('fn C.clGetPlatformIDs(u32, &PlatformId, &u32) ErrorCode')
	assert generated.contains('pub fn get_platform_ids(num_entries u32, platforms voidptr')
	assert generated.contains('unsafe { &PlatformId(platforms) }')
	assert generated.contains('pub fn wait_for_events(num_events u32, event_list voidptr)')
	assert generated.contains('unsafe { &Event(event_list) }')
	assert generated.contains('pub fn enqueue_svm_free(command_queue CommandQueue, num_svm_pointers u32, svm_pointers voidptr')
	assert generated.contains('unsafe { &voidptr(svm_pointers) }')

	// Scalar pointer parameters remain typed.
	assert generated.contains('global_work_size &usize')
	assert generated.contains('param_value_size_ret &usize')

	// Extension pfn abi remains typed while wrapper is pointer safe.
	assert generated.contains('pub type PFN_clEnqueueWaitSemaphoresKHR = fn (CommandQueue, u32, &SemaphoreKhr')
	assert generated.contains('pub fn enqueue_wait_semaphores_khr(command_queue CommandQueue, num_sema_objects u32, sema_objects voidptr')
	assert generated.contains('unsafe { &SemaphoreKhr(sema_objects) }')

	// Opencl 1 1 types constants and commands are generated.
	assert generated.contains('pub type BufferCreateType = u32')
	assert generated.contains('pub const complete = i32(0x0)')
	assert generated.contains('pub fn create_user_event(')
	assert generated.contains('pub fn enqueue_copy_buffer_rect(')

	// Opencl 1 2 types structs and commands are generated.
	assert generated.contains('pub type DevicePartitionProperty = isize')
	assert generated.contains('pub type MemMigrationFlags = u64')
	assert generated.contains('pub struct ImageDesc')
	assert generated.contains('buffer Mem')
	assert generated.contains('pub fn create_sub_devices(')
	assert generated.contains('pub fn enqueue_marker_with_wait_list(')

	// Opencl 2 0 types and commands are generated.
	assert generated.contains('pub type DeviceSvmCapabilities = u64')
	assert generated.contains('pub type QueueProperties = u64')
	assert generated.contains('pub fn create_command_queue_with_properties(')
	assert generated.contains('pub fn svm_alloc(')
	assert generated.contains('pub fn enqueue_svm_memcpy(')
	assert generated.contains('svm_pointers &voidptr')

	// Opencl 2 1 types constants and commands are generated.
	assert generated.contains('pub type KernelSubGroupInfo = u32')
	assert generated.contains('pub const platform_host_timer_resolution = PlatformInfo(0x0905)')
	assert generated.contains('pub fn get_device_and_host_timer(')
	assert generated.contains('pub fn create_program_with_il(')
	assert generated.contains('pub fn enqueue_svm_migrate_mem(')

	// Opencl 2 2 commands are generated.
	assert generated.contains('pub fn set_program_specialization_constant(')
	assert generated.contains('pub fn set_program_release_callback(')

	// Opencl 3 0 types constants and commands are generated.
	assert generated.contains('pub type Version = u32')
	assert generated.contains('pub struct NameVersion')
	assert generated.contains('name [name_version_max_name_size]i8')
	assert generated.contains('pub const platform_numeric_version = PlatformInfo(0x0906)')
	assert generated.contains('pub fn set_context_destructor_callback(')
	assert generated.contains('pub fn create_buffer_with_properties(')

	// Portable khr extension entry points are generated.
	assert generated.contains('pub type QueuePropertiesKhr = u64')
	assert generated.contains('pub const device_il_version_khr = DeviceInfo(0x105B)')
	assert generated.contains('pub const kernel_max_sub_group_size_for_ndrange_khr = KernelSubGroupInfo(0x2033)')
	assert generated.contains('pub fn create_program_with_il_khr(')
	assert generated.contains('pub fn create_command_queue_with_properties_khr(')
	assert generated.contains('pub fn get_kernel_sub_group_info_khr(')
	assert generated.contains('pub fn get_kernel_suggested_local_work_size_khr(')

	// Extension commands are resolved at runtime.
	assert generated.contains('pub type PFN_clGetKernelSubGroupInfoKHR = fn (')
	assert generated.contains("PFN_clGetKernelSubGroupInfoKHR(get_extension_function_address(c'clGetKernelSubGroupInfoKHR'))")
	assert !generated.contains('fn C.clGetKernelSubGroupInfoKHR(')
	assert generated.contains('if isnil(extension_fn) {\n\t\treturn invalid_operation')
	assert generated.contains('unsafe { *errcode_ret = invalid_operation }')
	assert generated.contains('return Program(unsafe { nil })')

	// External memory and semaphore extensions are generated.
	assert generated.contains('pub type SemaphoreKhr = voidptr')
	assert generated.contains('pub type ExternalSemaphoreHandleTypeKhr = u32')
	assert generated.contains('pub type ExternalMemoryHandleTypeKhr = u32')
	assert generated.contains('pub const invalid_semaphore_khr = ErrorCode(-1142)')
	assert generated.contains('pub const semaphore_handle_opaque_fd_khr = ExternalSemaphoreHandleTypeKhr(0x2055)')
	assert generated.contains('pub const semaphore_handle_sync_fd_khr = ExternalSemaphoreHandleTypeKhr(0x2058)')
	assert generated.contains('pub const external_memory_handle_dma_buf_khr = ExternalMemoryHandleTypeKhr(0x2067)')
	assert generated.contains('pub const external_memory_handle_opaque_fd_khr = ExternalMemoryHandleTypeKhr(0x2060)')
	assert generated.contains('pub fn create_semaphore_with_properties_khr(')
	assert generated.contains('pub fn get_semaphore_handle_for_type_khr(')
	assert generated.contains('pub fn re_import_semaphore_sync_fd_khr(')
	assert generated.contains('pub fn enqueue_acquire_external_mem_objects_khr(')
	assert generated.contains('pub fn enqueue_release_external_mem_objects_khr(')

	// Device uuid extension is generated.
	assert generated.contains('pub const uuid_size_khr = u32(16)')
	assert generated.contains('pub const luid_size_khr = u32(8)')
	assert generated.contains('pub const device_uuid_khr = DeviceInfo(0x106A)')
	assert generated.contains('pub const driver_uuid_khr = DeviceInfo(0x106B)')
	assert generated.contains('pub const device_luid_valid_khr = DeviceInfo(0x106C)')
	assert generated.contains('pub const device_luid_khr = DeviceInfo(0x106D)')
	assert generated.contains('pub const device_node_mask_khr = DeviceInfo(0x106E)')

	assert registry.core.map(it.attributes['number']) == ['1.0', '1.1', '1.2', '2.0', '2.1', '2.2',
		'3.0']
	assert 'CL_VERSION_3_1' in registry.later
	assert !generated.contains('fn C.clGetKernelSuggestedLocalWorkSize(')
	for name in ['create_buffer_with_properties', 'svm_alloc', 'enqueue_svm_map'] {
		wrapper := generated.all_after('pub fn ${name}(').all_before('\n@[inline]')
		assert wrapper.contains('$if opencl_dynamic ?')
		assert wrapper.contains('$if macos {')
	}
	legacy := generated.all_after('pub fn create_buffer(').all_before('\n@[inline]')
	assert !legacy.contains('$if macos {')
	assert compact_attribute_separators('<item key = "a = b"> c = d </item>') == '<item key="a = b"> c = d </item>'
	println('OpenCL generator determinism, ABI, and registry fixtures passed.')
}

fn run_cli() ! {
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('generate_opencl')
	parser.description('Generate the public V bindings from the Khronos OpenCL XML registry.')
	registry_arg := parser.string('registry', 0, 'opencldocs/xml/cl.xml', 'registry XML input')
	output := parser.string('output', 0, os.join_path(@DIR, 'opencl.v'), 'generated V source')
	test := parser.bool('self-test', 0, false, 'validate the pinned registry and generated ABI')
	later_only := parser.bool('later-core', 0, false, 'list core features beyond the linked ABI')
	if parser.bool('help', `h`, false, 'show help') {
		println(parser.usage())
		return
	}
	if parser.finalize()!.len != 0 {
		return error('unexpected positional arguments')
	}
	path := if os.is_abs_path(registry_arg) {
		registry_arg
	} else {
		os.join_path(os.dir(@DIR), registry_arg)
	}
	registry := read_registry(path)!
	if test {
		test_generator(registry)!
		return
	}
	if later_only {
		println(if registry.later.len == 0 { 'none' } else { registry.later.join(', ') })
		return
	}
	os.write_file(output, registry.render()!)!
}

run_cli() or {
	eprintln(err)
	exit(1)
}
