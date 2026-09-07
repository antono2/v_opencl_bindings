module main

fn test_command_line_options_override_defaults() {
	options := parse_options(AppOptions{}, ['--staged', '--particles=4096', '--frames=12']) or {
		assert false, err.msg()
		return
	}
	assert options.window
	assert options.force_staged
	assert options.particle_count == 4096
	assert options.frame_limit == 12
}

fn test_invalid_command_line_options_are_rejected() {
	if _ := parse_options(AppOptions{}, ['--particles=0']) {
		assert false
	}
	if _ := parse_options(AppOptions{}, ['--frames=nope']) {
		assert false
	}
	if _ := parse_options(AppOptions{}, ['--unknown']) {
		assert false
	}
}
