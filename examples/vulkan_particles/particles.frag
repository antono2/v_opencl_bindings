#version 450

layout(location = 0) in vec3 color;
layout(location = 0) out vec4 out_color;

void main() {
	vec2 offset = gl_PointCoord * 2.0 - 1.0;
	float radius_squared = dot(offset, offset);
	if (radius_squared > 1.0) {
		discard;
	}
	float core = exp(-5.5 * radius_squared);
	float halo = exp(-1.8 * radius_squared) * 0.32;
	out_color = vec4(color * (core + halo), core + halo);
}
