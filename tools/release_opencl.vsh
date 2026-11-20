// Validate a generator release and tag its matching published OpenCL module.
import encoding.base64
import os
import rand
import semver
import v.vmod

const module_repo = 'repos/antono2/opencl'
const module_remote = 'https://github.com/antono2/opencl.git'

type Runner = fn ([]string) os.Result

fn checked(run Runner, args []string) !string {
	result := run(args)
	if result.exit_code != 0 {
		return error('${args[0]} failed (exit ${result.exit_code}): ${result.output.trim_space()}')
	}
	return result.output.trim_space()
}

fn commit_hash(value string) !string {
	if value.len != 40 || !value.bytes().all((it >= `0` && it <= `9`) || (it >= `a` && it <= `f`)) {
		return error('Expected a full Git object ID: ${value}')
	}
	return value
}

fn validate(version string, manifest string, tag string) ! {
	parsed := semver.from(version)!
	if parsed.str() != version || parsed.prerelease != '' || parsed.metadata != ''
		|| 'v${version}' != tag || vmod.decode(manifest)!.version != version {
		return error('VERSION, v.mod and the release tag must agree: ${version}, ${tag}')
	}
}

fn publish_release(run Runner, tag string) ! {
	result := run(['gh', 'release', 'view', tag])
	if result.exit_code == 0 {
		println('Release ${tag} already exists.')
		return
	}
	if !result.output.contains('release not found') && !result.output.contains('HTTP 404') {
		return error('Could not check release ${tag}: ${result.output.trim_space()}')
	}
	println(checked(run, ['gh', 'release', 'create', tag, '--verify-tag', '--generate-notes',
		'--title', 'v_opencl_bindings ${tag}'])!)
}

fn read_module_file(run Runner, path string, revision string) !string {
	encoded := checked(run, ['gh', 'api', '${module_repo}/contents/${path}?ref=${revision}', '--jq',
		'.content'])!
	return base64.decode_str(encoded.replace('\n', '').replace('\r', '')).trim_right('\n')
}

fn existing_commit(reply string, ref string) !string {
	mut direct := ''
	mut peeled := ''
	for line in reply.split_into_lines() {
		if line == '' {
			continue
		}
		value, name := line.split_once('\t') or { return error('Malformed tag response') }
		match name {
			ref { direct = commit_hash(value)! }
			ref + '^{}' { peeled = commit_hash(value)! }
			else { return error('Unexpected ref in tag lookup: ${name}') }
		}
	}
	if peeled != '' && direct == '' {
		return error('Peeled tag is missing its direct ref')
	}
	return if peeled != '' { peeled } else { direct }
}

fn tag_module(run Runner, tag string, version string, generator string) ! {
	commit_hash(generator)!
	module_commit := commit_hash(checked(run, ['gh', 'api', '${module_repo}/git/ref/heads/master',
		'--jq', '.object.sha'])!)!
	module_version := read_module_file(run, 'VERSION', module_commit)!
	module_generator := read_module_file(run, 'GENERATOR_COMMIT', module_commit)!
	manifest := read_module_file(run, 'v.mod', module_commit)!
	validate(module_version, manifest, tag)!
	if module_version != version || module_generator != generator {
		return error('Published OpenCL module does not match generator ${generator} for ${tag}')
	}
	ref := 'refs/tags/' + tag
	reply := checked(run, ['git', 'ls-remote', module_remote, ref, ref + '^{}'])!
	existing := existing_commit(reply, ref)!
	if existing != '' {
		if existing != module_commit {
			return error('opencl ${tag} already resolves to ${existing}, expected ${module_commit}')
		}
		println('opencl ${tag} already points to ${module_commit}')
		return
	}
	tag_object := commit_hash(checked(run, ['gh', 'api', '--method', 'POST',
		'${module_repo}/git/tags', '-f', 'tag=${tag}', '-f',
		'message=Release ${tag} synchronized from v_opencl_bindings', '-f',
		'object=${module_commit}', '-f', 'type=commit', '--jq', '.sha'])!)!
	checked(run, ['gh', 'api', '--method', 'POST', '${module_repo}/git/refs', '-f', 'ref=${ref}',
		'-f', 'sha=${tag_object}'])!
}

fn self_test() ! {
	root := os.join_path(os.temp_dir(), 'opencl-release-fixture-' + rand.uuid_v4())
	os.mkdir(root)!
	defer { os.rmdir_all(root) or {} }
	tag := 'v1.2.3'
	version := '1.2.3'
	generator := 'a'.repeat(40)
	module_commit := 'b'.repeat(40)
	object := 'c'.repeat(40)
	ref := 'refs/tags/' + tag
	manifest := "Module { name: 'antono2.opencl', version: '${version}' }"
	validate(version, manifest, tag)!
	for scenario in ['present', 'missing', 'unavailable'] {
		journal := os.join_path(root, scenario)
		fake := fn [scenario, journal] (args []string) os.Result {
			mut stream := os.open_append(journal) or { panic(err) }
			defer { stream.close() }
			stream.writeln(args[2]) or { panic(err) }
			if args[2] == 'create' {
				assert scenario == 'missing' && '--verify-tag' in args
				return os.Result{}
			}
			return match scenario {
				'missing' {
					os.Result{
						exit_code: 1
						output:    'release not found'
					}
				}
				'unavailable' {
					os.Result{
						exit_code: 1
						output:    'authentication failed'
					}
				}
				else {
					os.Result{}
				}
			}
		}
		mut failed := false
		publish_release(fake, tag) or { failed = true }
		assert failed == (scenario == 'unavailable')
		assert os.read_lines(journal)! == if scenario == 'missing' {
			['view', 'create']
		} else {
			['view']
		}
	}
	assert existing_commit('${module_commit}\t${ref}', ref)! == module_commit
	assert existing_commit('${object}\t${ref}\n${module_commit}\t${ref}^{}', ref)! == module_commit
	if _ := validate(version, manifest, 'v1.2.4') {
		return error('Accepted a mismatched generator release tag')
	}
	for scenario in ['new', 'exists', 'collision', 'provenance', 'network'] {
		journal := os.join_path(root, scenario)
		fake := fn [scenario, journal, ref, generator, module_commit, version, manifest, object] (args []string) os.Result {
			payload := args.join(' ')
			if args[..2] == ['git', 'ls-remote'] {
				return match scenario {
					'exists' {
						os.Result{
							output: '${object}\t${ref}\n${module_commit}\t${ref}^{}'
						}
					}
					'collision' {
						os.Result{
							output: '${generator}\t${ref}'
						}
					}
					'network' {
						os.Result{
							exit_code: 128
							output:    'network unavailable'
						}
					}
					else {
						os.Result{}
					}
				}
			}
			if args[2..4] == ['--method', 'POST'] {
				assert scenario == 'new', payload
				mut stream := os.open_append(journal) or { panic(err) }
				defer { stream.close() }
				stream.writeln(args[4]) or { panic(err) }
				if args[4].ends_with('/git/tags') {
					assert 'object=${module_commit}' in args
					return os.Result{
						output: object
					}
				}
				assert 'ref=${ref}' in args && 'sha=${object}' in args
				return os.Result{}
			}
			if args[2].ends_with('/git/ref/heads/master') {
				return os.Result{
					output: module_commit
				}
			}
			assert args[2].ends_with('?ref=${module_commit}')
			value := if args[2].contains('/VERSION?') {
				version
			} else if args[2].contains('/GENERATOR_COMMIT?') {
				if scenario == 'provenance' { object } else { generator }
			} else {
				manifest
			}
			return os.Result{
				output: base64.encode_str(value + '\n')
			}
		}
		mut failed := false
		tag_module(fake, tag, version, generator) or { failed = true }
		assert failed == (scenario in ['collision', 'provenance', 'network'])
		if scenario == 'new' {
			assert os.read_lines(journal)! == ['${module_repo}/git/tags', '${module_repo}/git/refs']
		} else {
			assert !os.exists(journal)
		}
	}
	println('Release tag, immutable provenance, and duplicate-tag fixtures passed.')
}

fn run_cli(args []string) ! {
	if args == ['--self-test'] {
		self_test()!
		return
	}
	if args.len != 1 || args[0] !in ['release', 'tag-module'] {
		return error('Usage: release_opencl.vsh release|tag-module|--self-test')
	}
	tag := os.getenv('GITHUB_REF_NAME')
	version := os.read_file('VERSION')!.trim_right('\n')
	validate(version, os.read_file('v.mod')!, tag)!
	if args[0] == 'release' {
		publish_release(os.exec, tag)!
	} else {
		generator :=
			checked(os.exec, ['git', 'rev-parse', '--verify', 'refs/tags/${tag}^{commit}'])!
		tag_module(os.exec, tag, version, generator)!
	}
}

run_cli(os.args[1..]) or {
	eprintln(err)
	exit(1)
}
