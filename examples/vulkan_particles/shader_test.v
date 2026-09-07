module main

import os

fn test_particle_shader_binaries_are_valid() {
	shader_dir := os.dir(@FILE)
	vertex := os.read_bytes(os.join_path(shader_dir, 'particles.vert.spv'))!
	fragment := os.read_bytes(os.join_path(shader_dir, 'particles.frag.spv'))!
	trail_vertex := os.read_bytes(os.join_path(shader_dir, 'trails.vert.spv'))!
	trail_fragment := os.read_bytes(os.join_path(shader_dir, 'trails.frag.spv'))!
	assert vertex.len > 20
	assert fragment.len > 20
	assert spirv_magic(vertex)
	assert spirv_magic(fragment)
	assert trail_vertex.len > 20
	assert trail_fragment.len > 20
	assert spirv_magic(trail_vertex)
	assert spirv_magic(trail_fragment)
	assert particle_stride == 32
}

fn spirv_magic(bytes []u8) bool {
	return bytes.len >= 4 && bytes[0] == 0x03 && bytes[1] == 0x02 && bytes[2] == 0x23
		&& bytes[3] == 0x07
}
