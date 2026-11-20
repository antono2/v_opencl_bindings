// Shared build and runtime checks for the generator and its installed OpenCL module.
module opencltest

import os

pub const particle_example = 'examples/vulkan_particles'
const particle_frames = 16
const particle_count = 1024
const validation_layer = 'VK_LAYER_KHRONOS_validation'

pub fn checked(args []string) !string {
	result := os.exec(args)
	if result.output != '' {
		print(result.output)
	}
	if result.exit_code != 0 {
		return error('${args.join(' ')} failed (exit ${result.exit_code})')
	}
	return result.output.trim_space()
}

pub fn compiler(executable string, args []string) ! {
	mut command := [executable]
	command << args
	checked(command)!
}

pub fn build_compiler(directory string, local bool) ! {
	// V run exports VEXE. The Makefile uses it as its output path.
	mut command := ['make', '-C', directory, 'VEXE=./v']
	if local {
		command << 'local=1'
	}
	checked(command)!
	compiler(os.abs_path(os.join_path(directory, 'v')), ['version'])!
}

pub fn pin(file string) !string {
	value := os.read_file(file)!.trim_space()
	if value.len != 40 || !value.bytes().all((it >= `0` && it <= `9`) || (it >= `a` && it <= `f`)) {
		return error('${file} must contain a full Git commit ID')
	}
	return value
}

pub fn stage_dependencies(stage string, pinned bool) ! {
	for name, variable in {
		'vulkan': 'VULKAN_REF'
		'glfw':   'GLFW_REF'
	} {
		source := os.real_path(os.join_path('.ci-modules', name))
		if !os.is_dir(source) {
			return error('Missing dependency checkout: ${source}')
		}
		if pinned {
			tag := os.getenv(variable)
			if tag == '' {
				return error('Set ${variable} to the expected ${name} tag.')
			}
			actual := checked(['git', '-C', source, 'rev-parse', 'HEAD'])!
			expected := checked(['git', '-C', source, 'rev-parse', '--verify',
				'refs/tags/${tag}^{commit}'])!
			if actual != expected {
				return error('${name} checkout does not match ${variable} (${tag}).')
			}
		}
		link := os.join_path(stage, 'modules', 'antono2', name)
		if os.is_link(link) && os.real_path(link) == source {
			continue
		}
		os.symlink(source, link)!
	}
}

pub fn smoke(executable string, full bool, convenience string) ! {
	compiler(executable, ['-cc', 'gcc', 'run', 'test'])!
	for path in [convenience, 'test/pointer_abi_test.v'] {
		compiler(executable, ['test', path])!
	}
	if full {
		compiler(executable, ['run', 'tools/check_docs.vsh'])!
		compiler(executable, ['-cc', 'gcc', 'run', 'examples/getting_started'])!
		compiler(executable, ['-cc', 'gcc', 'test', 'test/helpers_test.v'])!
		compiler(executable, ['-cc', 'gcc', '-d', 'opencl_dynamic', 'test', 'test/helpers_test.v'])!
		compiler(executable, ['run', 'test/test_dynamic_runtime.vsh'])!
	}
	for path in ['examples/vector_add', 'examples/image_svm'] {
		compiler(executable, ['-cc', 'gcc', 'run', path])!
	}
}

fn check_window(result os.Result) ! {
	if result.exit_code != 0 {
		return error('The particle window exited with status ${result.exit_code}')
	}
	if result.output.contains('Validation Error') || result.output.contains('Validation Warning') {
		return error('Vulkan validation reported a particle renderer error or warning')
	}
	if !result.output.contains('Particle loop: rendered ${particle_frames} frames') {
		return error('The staged particle window did not report ${particle_frames} rendered frames')
	}
}

fn particle_smokes(binaries []string) ! {
	previous := os.getenv_opt('PARTICLE_COUNT')
	os.setenv('PARTICLE_COUNT', particle_count.str(), true)
	defer {
		if value := previous {
			os.setenv('PARTICLE_COUNT', value, true)
		} else {
			os.unsetenv('PARTICLE_COUNT')
		}
	}
	for binary in binaries {
		checked([binary])!
	}
}

pub fn particles(executable string, stage string) ! {
	compiler(executable, ['run', os.join_path(particle_example, 'compile_shaders.vsh')])!
	gcc := os.join_path(stage, 'vulkan-particles')
	tcc := os.join_path(stage, 'vulkan-particles-tcc')
	startup := os.join_path(stage, 'window-startup-check')
	compiler(executable, ['-cc', 'gcc', '-o', gcc, particle_example])!
	compiler(executable, ['-cc', 'tcc', '-o', tcc, particle_example])!
	particle_smokes([gcc, tcc])!
	compiler(executable, ['-cc', 'tcc', '-o', startup,
		os.join_path(particle_example, 'tests', 'window_startup.v')])!
	checked([startup, gcc, os.join_path(stage, 'window-startup-logs'), '--staged', '--frames=3',
		'--particles=128'])!
	os.setenv('VK_INSTANCE_LAYERS', validation_layer, true)
	result := os.exec(['xvfb-run', '-a', gcc, '--staged', '--frames=${particle_frames}',
		'--particles=${particle_count}'])
	print(result.output)
	os.write_file(os.join_path(stage, 'vulkan-particles-window.log'), result.output)!
	check_window(result)!
	for test in ['options_test.v', 'shader_test.v', 'interop_probe_test.v'] {
		compiler(executable, ['test', os.join_path(particle_example, test)])!
	}
}

pub fn self_test() ! {
	valid := 'Particle loop: rendered ${particle_frames} frames'
	check_window(os.Result{ output: valid })!
	for result in [os.Result{ exit_code: 1, output: valid }, os.Result{
		output: valid + '\nValidation Warning'
	}, os.Result{ output: 'window started' }] {
		if _ := check_window(result) {
			return error('Accepted an incomplete or failed particle window check')
		}
	}
	println('OpenCL window exit status, validation, and frame checks passed.')
}
