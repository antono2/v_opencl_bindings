// Compile the particle and trail shaders embedded by the Vulkan example.
import os

fn compile_shaders() ! {
	sdk := os.getenv('VULKAN_SDK')
	suffix := if os.user_os() == 'windows' { '.exe' } else { '' }
	sdk_compiler := os.join_path(sdk, 'bin', 'glslc' + suffix)
	compiler := if sdk != '' && os.is_file(sdk_compiler) {
		sdk_compiler
	} else {
		os.find_abs_path_of_executable('glslc') or {
			return error('install glslc or set VULKAN_SDK to an SDK containing it')
		}
	}
	for shader in ['particles.vert', 'particles.frag', 'trails.vert', 'trails.frag'] {
		source := os.join_path(@DIR, shader)
		output := source + '.spv'
		os.execute_opt('${os.quoted_path(compiler)} -O ${os.quoted_path(source)} -o ${os.quoted_path(output)}')!
	}
}

compile_shaders() or {
	eprintln(err)
	exit(1)
}
