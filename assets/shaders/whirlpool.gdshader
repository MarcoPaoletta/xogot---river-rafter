shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

// Whirlpool surface: spiral foam arms twisting into a dark eye. Rotated by its node too.

uniform vec4 foam_color : source_color = vec4(0.95, 0.99, 1.0, 1.0);
uniform vec4 deep_color : source_color = vec4(0.02, 0.12, 0.18, 1.0);
uniform float arms = 3.0;
uniform float twist = 7.5;
uniform float speed = 2.4;
uniform float opacity = 0.95;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 uv = UV - 0.5;
	float r = length(uv) * 2.0;
	float a = atan(uv.y, uv.x);
	float spiral = sin(a * arms + r * twist - TIME * speed);
	float n = vnoise(vec2(a * 2.5 + r * 4.0, r * 9.0 - TIME * 1.5));
	float foam = smoothstep(0.45, 0.8, spiral * 0.65 + n * 0.55) * (1.0 - smoothstep(0.65, 1.0, r)) * smoothstep(0.08, 0.3, r);
	float dark = (1.0 - smoothstep(0.0, 0.75, r)) * 0.8;
	ALBEDO = mix(deep_color.rgb, foam_color.rgb, foam);
	ALPHA = clamp(max(foam * 0.9, dark) * (1.0 - smoothstep(0.8, 1.0, r)) * opacity, 0.0, 1.0);
}
