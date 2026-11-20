// Run the OpenCL generator, ABI, and particle checks in isolated CI directories.
import opencltest
import os

const self_tests = ['src/generate.vsh', 'tools/sync_published_module.vsh',
	'tools/publish_generated_branch.vsh', 'tools/check_input_payload.vsh',
	'tools/propose_khronos_inputs.vsh', 'tools/propose_published_module.vsh',
	'tools/release_opencl.vsh']
const strict_sources = ['test/main.c.v', 'examples/vector_add/main.v',
	'examples/getting_started/main.v', 'examples/algorithms/main.v', 'abi/main.c.v', opencltest.particle_example]

fn report_pins(headers bool) ! {
	registry := opencltest.pin('REGISTRY_COMMIT')!
	header := if headers { opencltest.pin('HEADERS_COMMIT')! } else { '' }
	mut output := os.open_append(os.getenv('GITHUB_OUTPUT'))!
	defer { output.close() }
	output.writeln('registry=${registry}')!
	if headers {
		output.writeln('headers=${header}')!
	}
}

fn verify_checkout(directory string, metadata string) ! {
	actual := opencltest.checked(['git', '-C', directory, 'rev-parse', 'HEAD'])!
	if actual != opencltest.pin(metadata)! {
		return error('${directory} does not match ${metadata}')
	}
}

fn generate(mode string) ! {
	verify_checkout('opencldocs', 'REGISTRY_COMMIT')!
	match mode {
		'stable' {
			opencltest.self_test()!
			verify_checkout('openclheaders', 'HEADERS_COMMIT')!
			for script in self_tests {
				opencltest.compiler(@VEXE, ['run', script, '--self-test'])!
			}
		}
		'macos', 'master' {
			opencltest.compiler(@VEXE, ['run', 'src/generate.vsh', '--self-test'])!
		}
		else {}
	}

	opencltest.compiler(@VEXE, ['run', 'src/generate.vsh', '--registry', 'opencldocs/xml/cl.xml'])!
	if mode in ['stable', 'macos'] {
		opencltest.compiler(@VEXE, ['fmt', '-w', 'src/opencl.v'])!
		opencltest.checked(['git', 'diff', '--exit-code', '--', 'src/opencl.v'])!
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
	opencltest.compiler(@VEXE,
		['run', 'tools/sync_published_module.vsh', '--assemble', module_path])!
	return module_path
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
			opencltest.build_compiler('.ci-v-master', false)!
			return
		}
		['build-strict'] {
			opencltest.build_compiler('.ci-v3', true)!
			return
		}
		['--self-test'] {
			opencltest.self_test()!
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
			opencltest.smoke(@VEXE, true, 'test/convenience_test.v')!
		}
		'particles' {
			assemble(stage)!
			opencltest.stage_dependencies(stage, true)!
			opencltest.particles(@VEXE, stage)!
		}
		'macos-abi' {
			opencltest.compiler(@VEXE, ['run', 'packaging/published_setup.vsh', '--check'])!
			assemble(stage)!
			opencltest.compiler(@VEXE, ['-cc', 'clang', '-o', os.join_path(stage, 'opencl-abi-probe'),
				'abi/main.c.v'])!
			opencltest.compiler(@VEXE, ['-cc', 'clang', '-d', 'opencl_dynamic', '-o',
				os.join_path(stage, 'opencl-dynamic-probe'), 'examples/getting_started'])!
		}
		'windows-abi' {
			module_path := assemble(stage)!
			vcpkg := os.getenv('VCPKG_INSTALLATION_ROOT')
			if vcpkg == '' { return error('VCPKG_INSTALLATION_ROOT is missing') }
			os.setenv('OPENCL_SDK', os.join_path(vcpkg, 'installed', 'x64-windows'), true)
			opencltest.compiler(@VEXE, ['run', os.join_path(module_path, 'setup.vsh'),
				'--install'])!
			opencltest.compiler(@VEXE, ['-cc', 'msvc', '-o', os.join_path(stage,
				'opencl-abi-probe.exe'),
				'abi/main.c.v'])!
			opencltest.compiler(@VEXE, ['-cc', 'msvc', '-d', 'opencl_dynamic', '-o',
				os.join_path(stage, 'opencl-dynamic-probe.exe'), 'examples/getting_started'])!
		}
		'generate-master' {
			// Only the pinned stable lane checks formatting determinism.
			generate('master')!
			assemble(stage)!
		}
		'smoke-master' {
			opencltest.smoke(os.abs_path('.ci-v-master/v'), false, 'test/convenience_test.v')!
		}
		'strict-frontend' {
			generate('strict')!
			assemble(stage)!
			opencltest.stage_dependencies(stage, true)!
			for path in strict_sources {
				opencltest.compiler(os.abs_path('.ci-v3/v'), ['-new-compiler', '-check', path])!
			}
		}
		'strict-smoke' {
			for path in ['test', 'examples/vector_add', 'examples/getting_started',
				'examples/algorithms'] {
				opencltest.compiler(os.abs_path('.ci-v3/v'), ['-new-compiler', '-n', '-cc', 'tcc',
					'run', path])!
			}
		}
		'dependency-master' {
			assemble(stage)!
			opencltest.stage_dependencies(stage, false)!
			opencltest.compiler(@VEXE, ['-cc', 'gcc', '-o', os.join_path(stage, 'vulkan-particles'),
				opencltest.particle_example])!
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
