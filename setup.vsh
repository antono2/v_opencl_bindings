#!/usr/bin/env -S v run

// Prepares the pinned Khronos registries and verifies reproducible generation.

import os

fn run(command string) ! {
	println('\n> ${command}')
	result := os.execute(command)
	if result.output.trim_space() != '' {
		println(result.output.trim_right('\r\n'))
	}
	if result.exit_code != 0 {
		return error('command failed with exit code ${result.exit_code}')
	}
}

fn python_command() string {
	for candidate in ['python3', 'python'] {
		if os.exists_in_system_path(candidate) {
			return candidate
		}
	}
	$if windows {
		if os.exists_in_system_path('py') {
			return 'py -3'
		}
	}
	return ''
}

fn checkout_pinned(url string, directory string, commit string) ! {
	if !os.is_dir(os.join_path(directory, '.git')) {
		run('git init ${os.quoted_path(directory)}')!
		run('git -C ${os.quoted_path(directory)} remote add origin ${url}')!
	} else {
		changed := os.execute('git -c core.fileMode=false -C ${os.quoted_path(directory)} status --porcelain')
		if changed.exit_code != 0 || changed.output.trim_space() != '' {
			return error('${directory} contains local changes; refusing to replace its revision')
		}
	}
	run('git -C ${os.quoted_path(directory)} fetch --depth 1 origin ${commit}')!
	run('git -C ${os.quoted_path(directory)} checkout --quiet --detach FETCH_HEAD')!
}

fn checked_out(directory string, commit string) bool {
	if !os.is_dir(os.join_path(directory, '.git')) {
		return false
	}
	result := os.execute('git -C ${os.quoted_path(directory)} rev-parse HEAD')
	return result.exit_code == 0 && result.output.trim_space() == commit
}

fn main() {
	if os.args.len > 2 || (os.args.len == 2 && os.args[1] !in ['--install', '--check', '-h', '--help']) {
		eprintln('Usage: v run setup.vsh [--install|--check]')
		exit(2)
	}
	if os.args.len == 2 && os.args[1] in ['-h', '--help'] {
		println('Usage: v run setup.vsh [--install|--check]\n\nDefault: fetch pinned Khronos inputs and validate the generator.\n--check: only verify tools and pinned checkouts.')
		return
	}
	project_dir := os.dir(os.real_path(@FILE))
	python := python_command()
	if python == '' || !os.exists_in_system_path('git') || !os.exists_in_system_path('v') {
		eprintln('Git, Python 3, and V must be available on PATH.')
		exit(1)
	}
	registry_commit := os.read_file(os.join_path(project_dir, 'REGISTRY_COMMIT')) or { panic(err) }
	headers_commit := os.read_file(os.join_path(project_dir, 'HEADERS_COMMIT')) or { panic(err) }
	registry := registry_commit.trim_space()
	headers := headers_commit.trim_space()
	docs_dir := os.join_path(project_dir, 'opencldocs')
	headers_dir := os.join_path(project_dir, 'openclheaders')
	install := os.args.len == 1 || os.args[1] == '--install'
	if install {
		checkout_pinned('https://github.com/KhronosGroup/OpenCL-Docs.git', docs_dir, registry) or {
			panic(err)
		}
		checkout_pinned('https://github.com/KhronosGroup/OpenCL-Headers.git', headers_dir, headers) or { panic(err) }
	} else if !checked_out(docs_dir, registry) || !checked_out(headers_dir, headers) {
		eprintln('Pinned Khronos checkouts are missing or at the wrong revisions. Run without --check to prepare them.')
		exit(1)
	}
	if install {
		run('${python} ${os.quoted_path(os.join_path(project_dir, 'test', 'test_generator.py'))}') or {
			panic(err)
		}
	}
	println('\nOpenCL generator prerequisites and pinned inputs are ready.')
}
