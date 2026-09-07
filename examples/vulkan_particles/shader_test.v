module main

fn test_particle_shader_binaries_are_embedded_and_valid() {
	vertex := $embed_file('particles.vert.spv').to_bytes()
	fragment := $embed_file('particles.frag.spv').to_bytes()
	trail_vertex := $embed_file('trails.vert.spv').to_bytes()
	trail_fragment := $embed_file('trails.frag.spv').to_bytes()
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
