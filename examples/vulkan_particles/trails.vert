#version 450

layout(location = 0) in vec4 in_position;
layout(location = 1) in vec4 in_velocity;

layout(push_constant) uniform Frame {
	vec2 viewport;
	float point_scale;
	float time;
} frame;

layout(location = 0) out vec3 color;
layout(location = 1) out float brightness;

vec3 palette(float value) {
	vec3 phase = vec3(0.00, 0.33, 0.67);
	return 0.55 + 0.45 * cos(6.2831853 * (value + phase));
}

void main() {
	float speed = length(in_velocity.xy);
	float tail = clamp(0.075 + speed * 0.16, 0.08, 0.24);
	vec2 position = in_position.xy;
	if (gl_VertexIndex == 0) {
		position -= in_velocity.xy * tail;
	}
	gl_Position = vec4(position, 0.0, 1.0);
	color = palette(in_velocity.w + speed * 0.35 + frame.time * 0.025);
	brightness = gl_VertexIndex == 0 ? 0.035 : 0.24;
}
