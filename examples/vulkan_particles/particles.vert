#version 450

layout(location = 0) in vec4 in_position;
layout(location = 1) in vec4 in_velocity;

layout(push_constant) uniform Frame {
	vec2 viewport;
	float point_scale;
	float time;
} frame;

layout(location = 0) out vec3 color;

vec3 palette(float value) {
	vec3 phase = vec3(0.00, 0.33, 0.67);
	return 0.55 + 0.45 * cos(6.2831853 * (value + phase));
}

void main() {
	float speed = length(in_velocity.xy);
	float depth = clamp(1.0 + in_position.z * 0.8, 0.35, 1.65);
	gl_Position = vec4(in_position.xy, 0.0, 1.0);
	gl_PointSize = clamp(frame.point_scale * depth, 1.25, 9.0);
	color = palette(in_velocity.w + speed * 0.35 + frame.time * 0.025);
}
