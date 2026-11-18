// Assemble and check the OpenCL distribution using the canonical file list.
import flag
import os
import rand

const distribution_file = 'DISTRIBUTION_FILES'
const provenance_files = ['GENERATOR_COMMIT', 'REGISTRY_COMMIT', 'HEADERS_COMMIT']
const manifest_header = '# Managed by antono2/v_opencl_bindings. Edit the canonical generator, not this file.\n'
const source_files = {
	'.gitignore':                    '.gitignore'
	'src/opencl.v':                  'opencl.v'
	'src/convenience.v':             'convenience.v'
	'src/ownership.v':               'ownership.v'
	'src/program.v':                 'program.v'
	'src/event.v':                   'event.v'
	'src/capabilities.v':            'capabilities.v'
	'src/external_interop.v':        'external_interop.v'
	'src/image.v':                   'image.v'
	'src/svm.v':                     'svm.v'
	'src/session.v':                 'session.v'
	'src/runtime.v':                 'runtime.v'
	'src/scratch.v':                 'scratch.v'
	'src/transfer.v':                'transfer.v'
	'src/program_cache.v':           'program_cache.v'
	'test/convenience_test.v':       'convenience_test.v'
	'test/helpers_test.v':           'test/helpers_test.v'
	'test/test_dynamic_runtime.vsh': 'test/test_dynamic_runtime.vsh'
	'tools/check_docs.vsh':          'tools/check_docs.vsh'
	'test/pointer_abi_test.v':       'test/pointer_abi_test.v'
	'test/pointer_abi_shim.c':       'test/pointer_abi_shim.c'
	'API_DESIGN.md':                 'API_DESIGN.md'
	'OWNERSHIP.md':                  'OWNERSHIP.md'
	'LICENSE':                       'LICENSE'
	'VERSION':                       'VERSION'
	'REGISTRY_COMMIT':               'REGISTRY_COMMIT'
	'HEADERS_COMMIT':                'HEADERS_COMMIT'
	'packaging/published_setup.vsh': 'setup.vsh'
}

struct SyncOptions {
	check     bool
	assemble  bool
	refresh   bool
	generator string
}

fn git(root string, args string) !string {
	result := os.execute('git -C ${os.quoted_path(root)} ${args}')
	if result.exit_code != 0 {
		return error(result.output.trim_space())
	}
	return result.output
}

fn path_is_safe(path string) bool {
	return path != '' && !path.contains_any('\\:\r\n') && path.split('/').all(it != '' && it != '.'
		&& it != '..')
}

fn checked_destination(target string, relative string) !string {
	if !path_is_safe(relative) {
		return error('unsafe distribution path: ${relative}')
	}
	// Follow only real directories under the selected checkout.
	mut directory := target
	parts := relative.split('/')
	for component in parts[..parts.len - 1] {
		directory = os.join_path(directory, component)
		if os.is_link(directory) || (os.exists(directory) && !os.is_dir(directory)) {
			return error('invalid distribution directory: ${directory}')
		}
	}
	return os.join_path(directory, parts.last())
}

fn previous_paths(target string) ![]string {
	path := os.join_path(target, distribution_file)
	if os.is_link(path) {
		return error('linked distribution manifest: ${path}')
	}
	if !os.is_file(path) {
		return []
	}
	lines := os.read_file(path)!.split_into_lines().filter(it != '' && !it.starts_with('#'))
	for line in lines {
		if !path_is_safe(line) {
			return error('unsafe path in ${distribution_file}: ${line}')
		}
	}
	return lines
}

fn commit_is_valid(commit string) bool {
	return commit.len == 40 && commit.bytes().all(it.is_digit() || (it >= `a` && it <= `f`))
}

fn source_version(root string) !string {
	version := os.read_file(os.join_path(root, 'VERSION'))!.trim_space()
	parts := version.split('.')
	if parts.len != 3 || !parts.all(it.len > 0 && it.bytes().all(it.is_digit())) {
		return error('VERSION must contain a semantic version')
	}
	if !os.read_file(os.join_path(root, 'v.mod'))!.contains("version: '${version}'") {
		return error('VERSION and v.mod disagree')
	}
	return version
}

fn updated_module(module_file string, version string) !string {
	if !module_file.contains("name: 'antono2.opencl'") {
		return error('not an antono2.opencl checkout')
	}
	mut lines := module_file.replace('\r\n', '\n').split('\n')
	mut replacements := 0
	for i, line in lines {
		if line.trim_space().starts_with('version:') {
			start := line.index("'") or { continue }
			end := line.index_after("'", start + 1) or { continue }
			if line[..start].trim_space() != 'version:' || start + 1 == end {
				continue
			}
			lines[i] = line[..start + 1] + version + line[end..]
			replacements++
		}
	}
	if replacements != 1 {
		return error('published v.mod must contain exactly one version field')
	}
	return lines.join('\n')
}

fn render_readme(template string, version string) !string {
	if !template.contains('@VERSION@') {
		return error('published README template must contain @VERSION@')
	}
	rendered := template.replace('@VERSION@', version)
	pieces := rendered.split('@')
	for i in 1 .. pieces.len - 1 {
		name := pieces[i]
		if name.len > 0 && name.bytes().all((it >= `A` && it <= `Z`) || it == `_`) {
			return error('unknown published README placeholder: @${name}@')
		}
	}
	return rendered
}

fn assemble_contents(root string, target string, options SyncOptions) !map[string][]u8 {
	version := source_version(root)!
	mut contents := map[string][]u8{}
	mut mappings := source_files.clone()
	tracked := git(root, 'ls-files -z -- abi examples include algorithms docs')!
	for relative in tracked.split('\x00').filter(it != '') {
		if !path_is_safe(relative) {
			return error('unsafe tracked distribution path: ${relative}')
		}
		mappings[relative] = relative
	}
	for source, destination in mappings {
		contents[destination] = os.read_bytes(os.join_path(root, source))!
	}

	commit := if options.generator == '' {
		git(root, 'rev-parse HEAD')!.trim_space().to_lower_ascii()
	} else {
		options.generator.trim_space().to_lower_ascii()
	}
	if !commit_is_valid(commit) {
		return error('generator commit must be a full 40-character Git SHA')
	}
	contents['GENERATOR_COMMIT'] = (commit + '\n').bytes()

	module_path := os.join_path(target, 'v.mod')
	if os.is_link(module_path) {
		return error('linked published v.mod: ${module_path}')
	}
	module_file := if options.assemble && !os.exists(module_path) {
		"Module {\n name: 'antono2.opencl'\n version: '${version}'\n}\n"
	} else {
		os.read_file(module_path) or { return error('not an antono2.opencl checkout: ${target}') }
	}
	contents['v.mod'] = updated_module(module_file, version)!.bytes()
	readme := os.read_file(os.join_path(root, 'packaging', 'published_README.md'))!
	contents['README.md'] = render_readme(readme.replace('\r\n', '\n'), version)!.bytes()
	contents[distribution_file] =
		(manifest_header + contents.keys().sorted().join('\n') + '\n').bytes()
	return contents
}

fn remove_empty_parents(file string, target string) {
	mut parent := os.dir(file)
	for parent != target {
		os.rmdir(parent) or { return }
		parent = os.dir(parent)
	}
}

fn synchronize(root string, target string, options SyncOptions) ![]string {
	mut contents := assemble_contents(root, target, options)!
	stale :=
		previous_paths(target)!.filter(it !in contents.keys() || it == distribution_file).sorted()
	mut different := map[string]bool{}
	mut destinations := map[string]string{}
	for relative in contents.keys() {
		destination := checked_destination(target, relative)!
		if os.is_link(destination) || os.is_dir(destination) {
			return error('invalid distribution file: ${destination}')
		}
		destinations[relative] = destination
		different[relative] = !os.is_file(destination)
			|| os.read_bytes(destination)! != contents[relative]
	}
	for relative in stale {
		if relative == distribution_file {
			return error('${distribution_file} cannot list itself')
		}
		destinations[relative] = checked_destination(target, relative)!
	}

	// Preserve valid provenance when the distribution payload already agrees.
	payload_changed := stale.len != 0 || different.keys().any(it !in provenance_files
		&& different[it])
	if !options.refresh && !payload_changed {
		for name in provenance_files {
			if different[name] && os.is_file(destinations[name]) {
				previous := os.read_file(destinations[name])!
				if previous.len == 41 && previous.ends_with('\n') && commit_is_valid(previous[..40]) {
					different[name] = false
				}
			}
		}
	}

	mut changed := []string{}
	for relative in stale {
		changed << relative + ' (remove)'
		destination := destinations[relative]
		if !options.check && (os.is_file(destination) || os.is_link(destination)) {
			os.rm(destination)!
			remove_empty_parents(destination, target)
		}
	}
	for relative in contents.keys().sorted() {
		if !different[relative] {
			continue
		}
		changed << relative
		if !options.check {
			destination := destinations[relative]
			os.mkdir_all(os.dir(destination))!
			os.write_file_array(destination, contents[relative])!
		}
	}
	return changed
}

fn self_test(root string) ! {
	target := os.join_path(os.temp_dir(), 'opencl distribution ' + rand.uuid_v4())
	os.mkdir(target)!
	defer { os.rmdir_all(target) or {} }
	first := 'a'.repeat(40)
	second := 'b'.repeat(40)
	assert synchronize(root, target, SyncOptions{ assemble: true, generator: first })!.len > 0
	marker := os.join_path(target, 'GENERATOR_COMMIT')
	assert os.read_file(marker)! == first + '\n'
	assert synchronize(root, target, SyncOptions{ check: true, generator: second })!.len == 0
	assert synchronize(root, target, SyncOptions{ check: true, refresh: true, generator: second })! == [
		'GENERATOR_COMMIT',
	]
	assert os.read_file(marker)! == first + '\n'
	synchronize(root, target, SyncOptions{ refresh: true, generator: second })!
	assert os.read_file(marker)! == second + '\n'
	for name in provenance_files {
		path := os.join_path(target, name)
		os.write_file(path, 'invalid\n')!
		assert synchronize(root, target, SyncOptions{ check: true, generator: first })!.contains(name)
		synchronize(root, target, SyncOptions{ generator: first })!
	}
	readme := os.join_path(target, 'README.md')
	expected := os.read_bytes(readme)!
	os.write_file(readme, 'stale\n')!
	assert synchronize(root, target, SyncOptions{ check: true, generator: first })!.contains('README.md')
	assert os.read_file(readme)! == 'stale\n'
	os.write_file(os.join_path(target, 'REGISTRY_COMMIT'), second + '\n')!
	synchronize(root, target, SyncOptions{ generator: first })!
	assert os.read_bytes(readme)! == expected
	assert os.read_bytes(os.join_path(target, 'REGISTRY_COMMIT'))! == os.read_bytes(os.join_path(root,
		'REGISTRY_COMMIT'))!
	assert expected.bytestr().contains('v install antono2.opencl\n')
	assert !expected.bytestr().contains('v install antono2.opencl@')

	manifest := os.join_path(target, distribution_file)
	before := os.read_file(manifest)!
	stale := 'examples/obsolete/old.txt'
	stale_file := os.join_path(target, stale)
	os.mkdir_all(os.dir(stale_file))!
	os.write_file(stale_file, 'obsolete\n')!
	os.write_file(manifest, before + stale + '\n')!
	assert synchronize(root, target, SyncOptions{ check: true, generator: first })!.contains(
		stale + ' (remove)')
	assert os.is_file(stale_file)
	synchronize(root, target, SyncOptions{ generator: first })!
	assert !os.exists(stale_file) && !os.exists(os.dir(stale_file))
	assert os.read_file(manifest)! == before
	for invalid in ['../outside.txt', 'examples//file', 'examples/./file', 'C:/outside.txt'] {
		os.write_file(manifest, before + invalid + '\n')!
		mut refused := false
		synchronize(root, target, SyncOptions{ generator: second }) or {
			assert err.msg().contains('unsafe path')
			refused = true
			[]string{}
		}
		assert refused
		assert os.read_file(marker)! == first + '\n'
	}
	println('OpenCL distribution synchronization fixtures passed.')
}

fn run_cli() !int {
	mut parser := flag.new_flag_parser(os.args[1..])
	parser.application('sync_published_module')
	parser.description('Assemble or check the canonical OpenCL distribution.')
	options := SyncOptions{
		check:     parser.bool('check', 0, false, 'report drift without writing files')
		assemble:  parser.bool('assemble', 0, false, 'allow a fresh target without v.mod for tests')
		refresh:   parser.bool('refresh-provenance', 0, false, 'record the exact generator commit')
		generator: parser.string('generator-commit', 0, '', 'full generator commit SHA')
	}
	test := parser.bool('self-test', 0, false, 'run the distribution fixtures')
	if parser.bool('help', `h`, false, 'show help') {
		println(parser.usage())
		return 0
	}
	positional := parser.finalize()!
	root := os.dir(@DIR)
	if test && positional.len == 0 {
		self_test(root)!
		return 0
	}
	if positional.len != 1 || (options.check && options.assemble) || test {
		return error('expected exactly one distribution directory. See --help.')
	}
	changed := synchronize(root, os.real_path(positional[0]), options)!
	if changed.len == 0 {
		println('published module is synchronized')
		return 0
	}
	println('published module differs:')
	for path in changed {
		println('  ${path}')
	}
	return if options.check { 1 } else { 0 }
}

code := run_cli() or {
	eprintln(err)
	exit(2)
}
exit(code)
