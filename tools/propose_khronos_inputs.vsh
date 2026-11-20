// Prepare and publish review proposals for changes to the Khronos OpenCL inputs.
import os
import rand

const branch = 'automation/update-khronos-inputs'
const title = 'Update pinned Khronos OpenCL inputs'
const docs_url = 'https://github.com/KhronosGroup/OpenCL-Docs.git'
const headers_url = 'https://github.com/KhronosGroup/OpenCL-Headers.git'

struct Pins {
	registry string
	headers  string
}

struct ProposalContext {
	repository string
	run_url    string
	outcome    string
}

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

fn hash(value string) !string {
	if value.len != 40 || !value.bytes().all((it >= `0` && it <= `9`) || (it >= `a` && it <= `f`)) {
		return error('Expected a full Git commit hash: ${value}')
	}
	return value
}

fn read_pins() !Pins {
	return Pins{hash(os.read_file('REGISTRY_COMMIT')!.trim_space())!, hash(os.read_file('HEADERS_COMMIT')!.trim_space())!}
}

fn upstream_commit(url string) !string {
	reply := command(['git', 'ls-remote', '--exit-code', '--heads', url, 'refs/heads/main'])!
	value, ref := reply.split_once('\t') or { return error('Missing main revision from ${url}') }
	if ref != 'refs/heads/main' {
		return error('Unexpected main revision response from ${url}')
	}
	return hash(value)
}

fn report_updates(current Pins, upstream Pins, path string) ! {
	changed := current != upstream
	mut output := os.open_append(path)!
	defer { output.close() }
	output.writeln('registry=${upstream.registry}\nheaders=${upstream.headers}\nprevious_headers=${current.headers}\nchanged=${changed}')!
	if !changed {
		println('Pinned Khronos inputs are current.')
	}
}

fn checkout(directory string, url string, commit string) ! {
	command(['git', 'init', '-q', directory])!
	command(['git', '-C', directory, 'remote', 'add', 'origin', url])!
	command(['git', '-C', directory, 'fetch', '-q', '--depth', '1', 'origin', commit])!
	command(['git', '-C', directory, 'checkout', '-q', '--detach', 'FETCH_HEAD'])!
}

fn prepare(upstream Pins, previous_headers string, docs_remote string, headers_remote string) ! {
	for directory in ['opencldocs', 'openclheaders'] {
		if os.exists(directory) || os.is_link(directory) {
			return error('Expected a fresh upstream checkout at ${directory}')
		}
	}
	command(['git', 'checkout', '-B', branch, 'origin/master'])!
	checkout('opencldocs', docs_remote, upstream.registry)!
	checkout('openclheaders', headers_remote, upstream.headers)!
	if previous_headers != upstream.headers {
		command(['git', '-C', 'openclheaders', 'fetch', '-q', '--depth', '1', 'origin',
			previous_headers])!
	}
	os.write_file('REGISTRY_COMMIT', upstream.registry + '\n')!
	os.write_file('HEADERS_COMMIT', upstream.headers + '\n')!
}

fn generate() ! {
	command([@VEXE, 'run', 'src/generate.vsh', '--self-test'])!
	command([@VEXE, 'run', 'src/generate.vsh', '--registry', 'opencldocs/xml/cl.xml'])!
	command([@VEXE, 'fmt', '-w', 'src/opencl.v'])!
	command(['git', 'diff', '--check'])!
}

fn update_pr(gh Github, repository string, body_file string, pushed bool) ! {
	number := gh(['pr', 'list', '--repo', repository, '--state', 'open', '--head', branch, '--json',
		'number', '--jq', '.[0].number // empty'])!
	if number == '' {
		println(gh(['pr', 'create', '--repo', repository, '--base', 'master', '--head', branch,
			'--title', title, '--body-file', body_file])!)
	} else if pushed {
		gh(['pr', 'edit', number, '--repo', repository, '--body-file', body_file])!
	}
	// PRs created with GITHUB_TOKEN need an explicit workflow dispatch.
	if pushed || number == '' {
		gh(['workflow', 'run', 'generate-and-test.yml', '--repo', repository, '--ref', branch])!
	}
}

fn propose(pins Pins, previous_headers string, context ProposalContext, gh Github) ! {
	decision := command([@VEXE, 'run', 'tools/check_input_payload.vsh', '--previous-headers',
		previous_headers, '--generation-outcome', context.outcome])!
	if decision == 'false' {
		println('No binding or C-header payload changed; upstream documentation revisions need no proposal.')
		return
	}
	if decision != 'true' || read_pins()! != pins {
		return error('Unexpected payload decision or mismatched input pins')
	}
	if context.repository == '' || context.run_url == '' {
		return error('Expected GitHub repository and run information')
	}
	command(['git', 'add', '--', 'REGISTRY_COMMIT', 'HEADERS_COMMIT', 'src/opencl.v'])!
	before := command(['git', 'rev-parse', 'HEAD'])!
	println(command([@VEXE, 'run', 'tools/publish_generated_branch.vsh', branch, title])!)
	pushed := command(['git', 'rev-parse', 'HEAD'])! != before
	result := os.exec([@VEXE, 'run', 'src/generate.vsh', '--later-core'])
	later_core := if result.exit_code == 0 {
		result.output.trim_space()
	} else {
		'unavailable: ' + result.output.trim_space()
	}
	folder := os.join_path(os.temp_dir(), 'opencl-proposal-' + rand.uuid_v4())
	os.mkdir(folder)!
	defer { os.rmdir_all(folder) or {} }
	body := os.join_path(folder, 'proposal.md')
	tick := '`'
	os.write_file(body, 'Weekly proposal to refresh immutable Khronos inputs.\n\n' +
		'- OpenCL-Docs: ${tick}${pins.registry}${tick}\n' +
		'- OpenCL-Headers: ${tick}${pins.headers}${tick}\n' +
		'- Generation outcome: **${context.outcome}** ([run](${context.run_url}))\n' + '- Core registry features beyond the current link compatibility ceiling: ${later_core}\n\n' + 'Review generated ABI changes and CI before merging. If generation failed, fix the generator on this branch before merging. New core commands require a loader compatibility review before the ceiling can advance.\n')!
	update_pr(gh, context.repository, body, pushed)!
}

fn self_test() ! {
	root := os.join_path(os.temp_dir(), 'opencl-inputs-' + rand.uuid_v4())
	os.mkdir(root)!
	defer { os.rmdir_all(root) or {} }
	a := 'a'.repeat(40)
	b := 'b'.repeat(40)
	c := 'c'.repeat(40)
	output := os.join_path(root, 'outputs')
	report_updates(Pins{a, b}, Pins{a, b}, output)!
	report_updates(Pins{a, b}, Pins{a, c}, output)!
	assert os.read_lines(output)!.filter(it.starts_with('changed=')) == [
		'changed=false',
		'changed=true',
	]
	for previous, pushed in {
		'':   false
		'57': true
		'58': false
	} {
		journal := os.join_path(root, 'calls-${previous}')
		gh := fn [journal, previous] (args []string) !string {
			mut calls := os.open_append(journal)!
			defer { calls.close() }
			calls.writeln(args[..2].join(' '))!
			return if args[..2] == ['pr', 'list'] { previous } else { '' }
		}
		update_pr(gh, 'example/opencl', 'proposal.md', pushed)!
		expected := match previous {
			'' { ['pr list', 'pr create', 'workflow run'] }
			'57' { ['pr list', 'pr edit', 'workflow run'] }
			else { ['pr list'] }
		}

		assert os.read_lines(journal)! == expected
	}
	println('Khronos input and quiet pull request fixtures passed.')
}

fn run(args []string) ! {
	match args {
		['--self-test'] {
			self_test()!
		}
		['check'] {
			report_updates(read_pins()!, Pins{upstream_commit(docs_url)!, upstream_commit(headers_url)!},
				os.getenv('GITHUB_OUTPUT'))!
		}
		['generate'] {
			generate()!
		}
		['prepare'], ['propose'] {
			pins := Pins{hash(os.getenv('REGISTRY_SHA'))!, hash(os.getenv('HEADERS_SHA'))!}
			previous_headers := hash(os.getenv('PREVIOUS_HEADERS'))!
			if args[0] == 'prepare' {
				prepare(pins, previous_headers, docs_url, headers_url)!
			} else {
				repository := os.getenv('GITHUB_REPOSITORY')
				propose(pins, previous_headers, ProposalContext{repository, '${os.getenv('GITHUB_SERVER_URL')}/${repository}/actions/runs/${os.getenv('GITHUB_RUN_ID')}', os.getenv('GENERATE_OUTCOME')},
					github)!
			}
		}
		else {
			return error('Usage: propose_khronos_inputs.vsh check|prepare|generate|propose|--self-test')
		}
	}
}

run(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
