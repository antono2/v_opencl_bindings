// Ignore upstream metadata churn unless the generated bindings or C headers changed.
import flag
import os
import rand

fn git(root string, arguments []string) os.Result {
	mut args := ['-C', root]
	args << arguments
	command := 'git ' + args.map(os.quoted_path(it)).join(' ')
	return os.execute(command)
}

fn checked_git(root string, arguments []string) !string {
	result := git(root, arguments)
	if result.exit_code != 0 {
		return error('git ${arguments.join(' ')} failed: ${result.output.trim_space()}')
	}
	return result.output.trim_space()
}

fn should_propose(root string, headers string, previous string, outcome string) !bool {
	// A failed generation needs review even if there is no output to diff.
	if outcome == 'failure' {
		return true
	}
	if outcome != 'success' {
		return error('Generation must have completed before proposing inputs')
	}
	diff := git(root, ['diff', '--quiet', 'HEAD', '--', 'src/opencl.v'])
	match diff.exit_code {
		0 {}
		1 { return true }
		else { return error('Could not compare generated bindings: ${diff.output.trim_space()}') }
	}

	// Compare the complete C header subtree, including file names and modes.
	old_tree := checked_git(headers,
		['rev-parse', '--verify', '--end-of-options', previous + ':CL'])!
	new_tree := checked_git(headers, ['rev-parse', '--verify', 'HEAD:CL'])!
	return old_tree != new_tree
}

fn commit(root string, path string) ! {
	checked_git(root, ['add', '--', path])!
	checked_git(root, ['-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
		'commit', '-qm', 'fixture'])!
}

fn self_test() ! {
	root := os.join_path(os.temp_dir(), 'opencl payload ' + rand.uuid_v4())
	os.mkdir(root)!
	defer { os.rmdir_all(root) or {} }
	headers := os.join_path(root, 'headers')
	os.mkdir(headers)!
	for checkout in [root, headers] {
		checked_git(checkout, ['init', '-q'])!
	}
	os.mkdir(os.join_path(root, 'src'))!
	generated := os.join_path(root, 'src', 'opencl.v')
	os.write_file(generated, 'generated binding\n')!
	commit(root, 'src')!
	os.mkdir(os.join_path(headers, 'CL'))!
	header := os.join_path(headers, 'CL', 'cl.h')
	os.write_file(header, 'C API\n')!
	commit(headers, 'CL')!
	previous := checked_git(headers, ['rev-parse', 'HEAD'])!
	assert !should_propose(root, headers, previous, 'success')!

	os.write_file(os.join_path(headers, 'README.md'), 'upstream documentation change\n')!
	commit(headers, 'README.md')!
	assert checked_git(headers, ['rev-parse', 'HEAD'])! != previous
	assert !should_propose(root, headers, previous, 'success')!
	assert should_propose(root, headers, previous, 'failure')!
	mut missing_revision := false
	should_propose(root, headers, 'unavailable-header-commit', 'success') or {
		assert err.msg().contains('rev-parse')
		missing_revision = true
		false
	}
	assert missing_revision
	os.write_file(generated, 'changed binding\n')!
	assert should_propose(root, headers, previous, 'success')!
	os.write_file(generated, 'generated binding\n')!
	os.write_file(header, 'changed C API or portability fix\n')!
	commit(headers, 'CL')!
	assert should_propose(root, headers, previous, 'success')!
	println('OpenCL input payload checks passed.')
}

fn run_cli() ! {
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('check_input_payload')
	parser.description('Print whether generated OpenCL bindings or headers justify a proposal.')
	previous := parser.string('previous-headers', 0, '', 'previous OpenCL-Headers revision')
	outcome := parser.string('generation-outcome', 0, '', 'success or failure')
	headers := parser.string('headers', 0, 'openclheaders', 'OpenCL-Headers checkout')
	test := parser.bool('self-test', 0, false, 'run the proposal decision fixtures')
	if parser.bool('help', `h`, false, 'show help') {
		println(parser.usage())
		return
	}
	if parser.finalize()!.len != 0 {
		return error('unexpected positional arguments')
	}
	if test {
		self_test()!
		return
	}
	if previous == '' {
		return error('--previous-headers is required')
	}
	println(should_propose(os.getwd(), headers, previous, outcome)!)
}

run_cli() or {
	eprintln(err)
	exit(1)
}
