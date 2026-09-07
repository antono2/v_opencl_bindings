module main

import os

struct AppOptions {
mut:
	particle_count usize = 32768
	window         bool
	force_staged   bool
	frame_limit    int
	help           bool
}

fn options_from_environment() !AppOptions {
	count_text := os.getenv_opt('PARTICLE_COUNT') or { '32768' }
	count := count_text.parse_uint(10, 32) or { return error('invalid PARTICLE_COUNT: ${err}') }
	frames_text := os.getenv_opt('PARTICLES_FRAMES') or { '0' }
	frames := frames_text.int()
	if count == 0 {
		return error('particle count must be greater than zero')
	}
	if frames < 0 {
		return error('frame limit cannot be negative')
	}
	return AppOptions{
		particle_count: usize(count)
		window: os.getenv('PARTICLES_WINDOW') == '1'
		force_staged: os.getenv('PARTICLES_FORCE_STAGED') == '1'
		frame_limit: frames
	}
}

fn parse_options(base AppOptions, arguments []string) !AppOptions {
	mut options := base
	for argument in arguments {
		if argument == '--' {
			continue
		} else if argument == '--window' {
			options.window = true
		} else if argument == '--staged' {
			options.window = true
			options.force_staged = true
		} else if argument == '--help' || argument == '-h' {
			options.help = true
		} else if argument.starts_with('--particles=') {
			value := argument.all_after('=')
			count := value.parse_uint(10, 32) or { return error('invalid --particles value: ${value}') }
			if count == 0 {
				return error('particle count must be greater than zero')
			}
			options.particle_count = usize(count)
		} else if argument.starts_with('--frames=') {
			value := argument.all_after('=')
			frames := value.int()
			if frames < 0 || (frames == 0 && value != '0') {
				return error('invalid --frames value: ${value}')
			}
			options.frame_limit = frames
			options.window = true
		} else {
			return error('unknown option: ${argument}')
		}
	}
	return options
}

fn usage() string {
	return 'Usage: vulkan-particles [options]\n\n' + '  --window           open the interactive Vulkan renderer\n' + '  --staged           open the renderer and force host-staged transfers\n' + '  --particles=N      simulate N particles (default: 32768)\n' + '  --frames=N         render N frames, or 0 until closed\n' + '  -h, --help         show this help\n'
}
