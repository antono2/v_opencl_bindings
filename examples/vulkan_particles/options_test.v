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

fn test_zero_copy_requires_window_and_conflicts_with_staging() {
	options := parse_options(AppOptions{}, ['--zero-copy', '--frames=4'])!
	assert options.window
	assert options.require_zero_copy
	if _ := parse_options(AppOptions{}, ['--zero-copy', '--staged']) {
		assert false
	}
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

fn test_headless_mode_is_explicitly_explained() {
	assert headless_mode_notice().contains('no window')
	assert headless_mode_notice().contains('--window')
	assert usage().contains('headless smoke test without opening a window')
}

fn test_cursor_coordinates_match_vulkan_viewport_coordinates() {
	top_left_x, top_left_y := cursor_to_particle_position(0, 0, 960, 640)
	assert top_left_x == -1
	assert top_left_y == -1

	center_x, center_y := cursor_to_particle_position(480, 320, 960, 640)
	assert center_x == 0
	assert center_y == 0

	bottom_right_x, bottom_right_y := cursor_to_particle_position(960, 640, 960, 640)
	assert bottom_right_x == 1
	assert bottom_right_y == 1

	invalid_x, invalid_y := cursor_to_particle_position(10, 20, 0, 0)
	assert invalid_x == 0
	assert invalid_y == 0
}
