// OpenCL kernels for deterministic particle initialization and time-step updates.
typedef struct {
	float4 position;
	float4 velocity;
} Particle;

// Fixed integer-mixing constants scramble particle indices into deterministic seeds.
uint hash(uint value) {
	value ^= value >> 16;
	value *= 0x7feb352du;
	value ^= value >> 15;
	value *= 0x846ca68bu;
	return value ^ (value >> 16);
}

float random01(uint value) {
	// Use 24 random bits, scaled by 2^24, to produce a value in [0, 1).
	return (float)(hash(value) & 0x00ffffffu) / 16777216.0f;
}

__kernel void reset_particles(__global Particle *particles, uint seed) {
	const uint i = get_global_id(0);
	// Four samples per particle: angle (2*pi), radius, depth jitter and speed.
	// The remaining coefficients tune the appearance, not OpenCL dispatch limits.
	const float angle = random01(i * 4u + seed) * 6.28318530718f;
	const float radius = 0.08f + 0.82f * sqrt(random01(i * 4u + seed + 1u));
	const float jitter = random01(i * 4u + seed + 2u) - 0.5f;
	const float speed = 0.22f + 0.18f * random01(i * 4u + seed + 3u);
	const float2 radial = (float2)(cos(angle), sin(angle));
	particles[i].position = (float4)(radial * radius, jitter * 0.08f, 1.0f);
	particles[i].velocity = (float4)(-radial.y * speed, radial.x * speed, 0.0f,
		0.25f + 0.75f * random01(i + seed));
}

__kernel void step_particles(__global Particle *particles, float dt, float time,
	float2 pointer, float attraction) {
	const uint i = get_global_id(0);
	Particle particle = particles[i];
	float2 position = particle.position.xy;
	float2 velocity = particle.velocity.xy;

	// Two animated attractors plus the pointer; coefficients set orbit size and rate.
	const float2 orbiters[3] = {
		(float2)(0.34f * cos(time * 0.71f), 0.25f * sin(time * 0.93f)),
		(float2)(0.28f * cos(time * -0.53f + 2.1f), 0.34f * sin(time * 0.61f)),
		pointer
	};
	const float strengths[3] = { 0.075f, -0.052f, attraction };

	for (int attractor = 0; attractor < 3; ++attractor) {
		const float2 delta = orbiters[attractor] - position;
		// Softening avoids a singular force when a particle reaches an attractor.
		const float distance_squared = dot(delta, delta) + 0.0035f;
		velocity += delta * native_rsqrt(distance_squared) *
			(strengths[attractor] / distance_squared) * dt;
	}

	// Exponential drag; particles beyond radius 1.8 (squared: 3.24) bounce inward.
	velocity *= native_exp(-0.16f * dt);
	position += velocity * dt;
	if (dot(position, position) > 3.24f) {
		position *= 0.35f;
		velocity *= -0.3f;
	}

	particle.position.xy = position;
	particle.position.z = 0.12f * sin(time * 0.8f + (float)i * 0.013f);
	particle.velocity.xy = velocity;
	particles[i] = particle;
}
