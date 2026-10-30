shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Soft broken-up foam on the water surface. ring_mode 0 = round patch (wake particles,
// splashes), 1 = ring (around rocks, logs and the hull). Particle COLOR drives fade;
// INSTANCE_CUSTOM gives each particle its own noise seed.

uniform vec4 foam_color : source_color = vec4(0.96, 0.99, 1.0, 1.0);
uniform float ring_mode = 0.0;
uniform float ring_inner = 0.42;
uniform float ring_outer = 0.7;
uniform float breakup = 0.5;
uniform float noise_scale = 6.0;
uniform float scroll = 0.35;
uniform float opacity = 0.9;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

varying float v_seed;

void vertex() {
	v_seed = INSTANCE_CUSTOM.x;
}

void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float seed = v_seed * 31.0;
	vec2 p = uv * noise_scale + vec2(seed, seed * 0.7);
	float n = vnoise(p + vec2(0.0, TIME * scroll)) * 0.55 + vnoise(p * 2.3 - vec2(TIME * scroll * 0.7, 0.0)) * 0.3 + vnoise(p * 5.1) * 0.15;
	float shape;
	if (ring_mode > 0.5) {
		shape = smoothstep(ring_inner - 0.1, ring_inner, r) * (1.0 - smoothstep(ring_outer, ring_outer + 0.18, r));
	} else {
		shape = 1.0 - smoothstep(0.1, 1.0, r);
	}
	float lace = smoothstep(breakup, breakup + 0.1, n + (shape - 0.5) * 0.35);
	float mask = lace * shape;
	ALBEDO = mix(foam_color.rgb * 0.85, foam_color.rgb, smoothstep(0.2, 0.8, mask)) * COLOR.rgb;
	ALPHA = clamp(mask * opacity * COLOR.a, 0.0, 1.0);
}
