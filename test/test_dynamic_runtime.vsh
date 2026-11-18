// Verify that a dynamically loaded build diagnoses a missing OpenCL runtime.
import os
import rand

fn check_dynamic_runtime() ! {
	work := os.join_path(os.temp_dir(), 'opencl missing runtime ${rand.uuid_v4()}')
	os.mkdir(work)!
	defer { os.rmdir_all(work) or {} }
	suffix := if os.user_os() == 'windows' { '.exe' } else { '' }
	binary := os.join_path(work, 'first' + suffix)
	example := os.join_path(os.dir(@DIR), 'examples', 'getting_started')
	os.execute_opt('${os.quoted_path(@VEXE)} -d opencl_dynamic -o ${os.quoted_path(binary)} ${os.quoted_path(example)}')!
	previous := os.getenv_opt('OPENCL_LIBRARY')
	os.setenv('OPENCL_LIBRARY', os.join_path(work, 'missing-opencl-runtime'), true)
	defer {
		if value := previous {
			os.setenv('OPENCL_LIBRARY', value, true)
		} else {
			os.unsetenv('OPENCL_LIBRARY')
		}
	}
	result := os.execute(os.quoted_path(binary))
	if result.exit_code == 0 || !result.output.contains('OpenCL runtime unavailable') {
		return error('expected a missing-runtime diagnostic, got exit ${result.exit_code}: ${result.output}')
	}
	$if linux {
		linked := os.execute_opt('ldd ${os.quoted_path(binary)}')!
		if linked.output.contains('libOpenCL') {
			return error('dynamic build links against OpenCL: ${linked.output}')
		}
	}
}

check_dynamic_runtime() or {
	eprintln(err)
	exit(1)
}
println('Missing-runtime behavior verified.')
