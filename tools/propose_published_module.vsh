// Synchronize a reviewed generator checkout with the published OpenCL module.
import os
import rand

const repository = 'antono2/opencl'
const branch = 'automation/v-opencl-bindings'
const title = 'Synchronize published OpenCL module'

type Github = fn ([]string) !string

fn command(args []string) !string {
	result := os.exec(args)
	if result.exit_code != 0 {
		return error('${args[0]} failed (exit ${result.exit_code}): ${result.output.trim_space()}')
	}
	return result.output.trim_space()
}

fn github(args []string) !string {
	mut full := ['gh']
	full << args
	return command(full)
}

fn update_pr(gh Github, changed bool, generator string) ! {
	number := gh(['pr', 'list', '--repo', repository, '--state', 'open', '--head', branch, '--json',
		'number', '--jq', '.[0].number // empty'])!
	if number != '' && !number.bytes().all(it >= `0` && it <= `9`) {
		return error('Invalid publication PR number: ${number}')
	}
	if !changed {
		println('The published module is already synchronized')
		if number != '' {
			files := gh(['pr', 'view', number, '--repo', repository, '--json', 'files', '--jq',
				'.files[].path'])!
			if files == 'GENERATOR_COMMIT' {
				gh(['pr', 'close', number, '--repo', repository, '--delete-branch'])!
			}
		}
		return
	}
	if number != '' {
		println('Existing PR #${number} is left unchanged.')
		return
	}
	body := 'Automated synchronization from antono2/v_opencl_bindings at ${generator}. Version metadata is synchronized automatically. Merge this PR before tagging the synchronized generator commit for release.'
	println(gh(['pr', 'create', '--repo', repository, '--base', 'master', '--head', branch, '--title',
		title, '--body', body])!)
}

fn propose(refresh bool, gh Github) ! {
	generator := command(['git', 'rev-parse', 'HEAD'])!
	mut sync := [@VEXE, 'run', 'tools/sync_published_module.vsh', 'published', '--generator-commit',
		generator]
	if refresh {
		sync << '--refresh-provenance'
	}
	println(command(sync)!)
	command(['git', '-C', 'published', 'add', '--all'])!
	diff := os.exec(['git', '-C', 'published', 'diff', '--cached', '--quiet'])
	match diff.exit_code {
		0 {}
		1 {
			root := os.getwd()
			os.chdir('published')!
			defer { os.chdir(root) or {} }
			command(['git', 'checkout', '-B', branch])!
			println(command([@VEXE, 'run', '../tools/publish_generated_branch.vsh', branch, title])!)
		}
		else {
			return error('Could not compare staged OpenCL distribution: ${diff.output.trim_space()}')
		}
	}

	update_pr(gh, diff.exit_code == 1, generator)!
}

struct PrCase {
	existing string
	files    string
	changed  bool
	expected []string
}

fn self_test() ! {
	root := os.join_path(os.temp_dir(), 'opencl-module-proposal-' + rand.uuid_v4())
	os.mkdir(root)!
	defer { os.rmdir_all(root) or {} }
	cases := [
		PrCase{'', '', false, ['pr list']},
		PrCase{'', '', true, ['pr list', 'pr create']},
		PrCase{'57', 'opencl.v', true, ['pr list']},
		PrCase{'57', 'GENERATOR_COMMIT', false, ['pr list', 'pr view', 'pr close']},
		PrCase{'57', 'GENERATOR_COMMIT\nopencl.v', false, ['pr list', 'pr view']},
	]
	for index, fixture in cases {
		log_path := os.join_path(root, '${index}.log')
		fake := fn [fixture, log_path] (args []string) !string {
			mut log := os.open_append(log_path)!
			defer { log.close() }
			log.writeln(args[..2].join(' '))!
			return match args[1] {
				'list' { fixture.existing }
				'view' { fixture.files }
				else { '' }
			}
		}
		update_pr(fake, fixture.changed, 'a'.repeat(40))!
		assert os.read_lines(log_path)! == fixture.expected
	}
	println('Quiet OpenCL module publication fixtures passed.')
}

fn run(args []string) ! {
	if args == ['--self-test'] {
		self_test()!
		return
	}
	if args.len != 0 {
		return error('Usage: propose_published_module.vsh [--self-test]')
	}
	propose(os.getenv('REFRESH_PROVENANCE') == 'true', github)!
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
