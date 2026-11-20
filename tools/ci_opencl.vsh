// Run the OpenCL generator, ABI, and particle checks in isolated CI directories.
import os

const particle_example = 'examples/vulkan_particles'
const particle_frames = 16
const particle_count = 1024
const validation_layer = 'VK_LAYER_KHRONOS_validation'
const self_tests = ['src/generate.vsh', 'tools/sync_published_module.vsh',
	'tools/publish_generated_branch.vsh', 'tools/check_input_payload.vsh',
	'tools/propose_khronos_inputs.vsh', 'tools/propose_published_module.vsh',
	'tools/release_opencl.vsh']
const strict_sources = ['test/main.c.v', 'examples/vector_add/main.v',
	'examples/getting_started/main.v', 'examples/algorithms/main.v', 'abi/main.c.v', particle_example]

fn checked(args []string) !string {
	result := os.exec(args)
	if result.output != '' {
		print(result.output)
	}
	if result.exit_code != 0 {
		return error('${args.join(' ')} failed (exit ${result.exit_code})')
	}
	return result.output.trim_space()
}

fn compiler(executable string, args []string) ! {
	mut command := [executable]
	command << args
	checked(command)!
}

fn build_compiler(directory string, local bool) ! {
	// V run exports VEXE. The Makefile uses it as its output path.
	mut command := ['make', '-C', directory, 'VEXE=./v']
	if local {
		command << 'local=1'
	}
	checked(command)!
	compiler(os.abs_path(os.join_path(directory, 'v')), ['version'])!
}

fn pin(file string) !string {
	value := os.read_file(file)!.trim_space()
	if value.len != 40 || !value.bytes().all((it >= `0` && it <= `9`) || (it >= `a` && it <= `f`)) {
		return error('${file} must contain a full Git commit ID')
	}
	return value
}

fn report_pins(headers bool) ! {
	registry := pin('REGISTRY_COMMIT')!
	header := if headers { pin('HEADERS_COMMIT')! } else { '' }
	mut output := os.open_append(os.getenv('GITHUB_OUTPUT'))!
	defer { output.close() }
	output.writeln('registry=${registry}')!
	if headers {
		output.writeln('headers=${header}')!
	}
}

fn verify_checkout(directory string, metadata string) ! {
	actual := checked(['git', '-C', directory, 'rev-parse', 'HEAD'])!
	if actual != pin(metadata)! {
		return error('${directory} does not match ${metadata}')
	}
}

fn generate(mode string) ! {
	verify_checkout('opencldocs', 'REGISTRY_COMMIT')!
	match mode {
		'stable' {
			self_test()!
			verify_checkout('openclheaders', 'HEADERS_COMMIT')!
			for script in self_tests {
				compiler(@VEXE, ['run', script, '--self-test'])!
			}
		}
		'macos', 'master' {
			compiler(@VEXE, ['run', 'src/generate.vsh', '--self-test'])!
		}
		else {}
	}

	compiler(@VEXE, ['run', 'src/generate.vsh', '--registry', 'opencldocs/xml/cl.xml'])!
	if mode in ['stable', 'macos'] {
		compiler(@VEXE, ['fmt', '-w', 'src/opencl.v'])!
		checked(['git', 'diff', '--exit-code', '--', 'src/opencl.v'])!
	}
}

fn stage_root() !string {
	temporary := os.getenv('RUNNER_TEMP')
	if temporary == '' || !os.is_dir(temporary) {
		return error('Set RUNNER_TEMP to an existing scratch directory')
	}
	stage := os.join_path(temporary, 'opencl-ci')
	os.mkdir_all(stage)!
	os.setenv('VMODULES', os.join_path(stage, 'modules'), true)
	return stage
}

fn assemble(stage string) !string {
	module_path := os.join_path(stage, 'modules', 'antono2', 'opencl')
	os.mkdir_all(module_path)!
	compiler(@VEXE, ['run', 'tools/sync_published_module.vsh', '--assemble', module_path])!
	return module_path
}

fn stage_dependencies(stage string, pinned bool) ! {
	for name, variable in {
		'vulkan': 'VULKAN_REF'
		'glfw':   'GLFW_REF'
	} {
		source := os.real_path(os.join_path('.ci-modules', name))
		if !os.is_dir(source) {
			return error('Missing dependency checkout: ${source}')
		}
		if pinned
			&& checked(['git', '-C', source, 'describe', '--tags', '--exact-match'])! != os.getenv(variable) {
			return error('${name} checkout does not match ${variable}')
		}
		link := os.join_path(stage, 'modules', 'antono2', name)
		if os.is_link(link) && os.real_path(link) == source {
			continue
		}
		os.symlink(source, link)!
	}
}

fn smoke(executable string, full bool) ! {
	compiler(executable, ['-cc', 'gcc', 'run', 'test'])!
	for path in ['test/convenience_test.v', 'test/pointer_abi_test.v'] {
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

fn particles(stage string) ! {
	assemble(stage)!
	stage_dependencies(stage, true)!
	compiler(@VEXE, ['run', os.join_path(particle_example, 'compile_shaders.vsh')])!
	gcc := os.join_path(stage, 'vulkan-particles')
	tcc := os.join_path(stage, 'vulkan-particles-tcc')
	startup := os.join_path(stage, 'window-startup-check')
	compiler(@VEXE, ['-cc', 'gcc', '-o', gcc, particle_example])!
	compiler(@VEXE, ['-cc', 'tcc', '-o', tcc, particle_example])!
	particle_smokes([gcc, tcc])!
	compiler(@VEXE, ['-cc', 'tcc', '-o', startup,
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
		compiler(@VEXE, ['test', os.join_path(particle_example, test)])!
	}
}

fn self_test() ! {
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

fn run(args []string) ! {
	// Child compiler commands select their own executable explicitly.
	os.unsetenv('VEXE')
	match args {
		['pins'] {
			report_pins(false)!
			return
		}
		['pins-all'] {
			report_pins(true)!
			return
		}
		['generate-stable'] {
			generate('stable')!
			return
		}
		['generate-macos'] {
			generate('macos')!
			return
		}
		['build-master'] {
			build_compiler('.ci-v-master', false)!
			return
		}
		['build-strict'] {
			build_compiler('.ci-v3', true)!
			return
		}
		['--self-test'] {
			self_test()!
			return
		}
		else {}
	}

	if args.len != 1 {
		return error('Expected a CI stage')
	}
	stage := stage_root()!
	match args[0] {
		'smoke-stable' {
			assemble(stage)!
			smoke(@VEXE, true)!
		}
		'particles' {
			particles(stage)!
		}
		'macos-abi' {
			compiler(@VEXE, ['run', 'packaging/published_setup.vsh', '--check'])!
			assemble(stage)!
			compiler(@VEXE, ['-cc', 'clang', '-o', os.join_path(stage, 'opencl-abi-probe'),
				'abi/main.c.v'])!
			compiler(@VEXE, ['-cc', 'clang', '-d', 'opencl_dynamic', '-o',
				os.join_path(stage, 'opencl-dynamic-probe'), 'examples/getting_started'])!
		}
		'windows-abi' {
			module_path := assemble(stage)!
			vcpkg := os.getenv('VCPKG_INSTALLATION_ROOT')
			if vcpkg == '' { return error('VCPKG_INSTALLATION_ROOT is missing') }
			os.setenv('OPENCL_SDK', os.join_path(vcpkg, 'installed', 'x64-windows'), true)
			compiler(@VEXE, ['run', os.join_path(module_path, 'setup.vsh'), '--install'])!
			compiler(@VEXE, ['-cc', 'msvc', '-o', os.join_path(stage, 'opencl-abi-probe.exe'),
				'abi/main.c.v'])!
			compiler(@VEXE, ['-cc', 'msvc', '-d', 'opencl_dynamic', '-o',
				os.join_path(stage, 'opencl-dynamic-probe.exe'), 'examples/getting_started'])!
		}
		'generate-master' {
			// Only the pinned stable lane checks formatting determinism.
			generate('master')!
			assemble(stage)!
		}
		'smoke-master' {
			smoke(os.abs_path('.ci-v-master/v'), false)!
		}
		'strict-frontend' {
			generate('strict')!
			assemble(stage)!
			stage_dependencies(stage, true)!
			for path in strict_sources {
				compiler(os.abs_path('.ci-v3/v'), ['-new-compiler', '-check', path])!
			}
		}
		'strict-smoke' {
			for path in ['test', 'examples/vector_add', 'examples/getting_started',
				'examples/algorithms'] {
				compiler(os.abs_path('.ci-v3/v'), ['-new-compiler', '-n', '-cc', 'tcc', 'run',
					path])!
			}
		}
		'dependency-master' {
			assemble(stage)!
			stage_dependencies(stage, false)!
			compiler(@VEXE, ['-cc', 'gcc', '-o', os.join_path(stage, 'vulkan-particles'),
				particle_example])!
		}
		else {
			return error('Unknown OpenCL CI stage: ${args[0]}')
		}
	}
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
