shader_type canvas_item;
// Mood overlay: permanent soft vignette + animated film grain; 'intensity' drives the
// damage / boost flash tinted by 'tint'. One draw call for the whole screen.
uniform vec4 tint : source_color = vec4(0.95, 0.12, 0.18, 1.0);
uniform float intensity = 0.0;
uniform float base_vignette = 0.28;
uniform float grain = 0.035;

float rand(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV - 0.5;
	float d = length(uv * vec2(1.0, 0.8));
	float v = smoothstep(0.32, 0.78, d);
	float k = clamp(intensity, 0.0, 1.0);
	vec3 col = mix(vec3(0.02, 0.04, 0.06), tint.rgb, k);
	float a = v * (base_vignette + k * 0.75);
	float n = (rand(SCREEN_UV * 900.0 + vec2(TIME * 37.0, TIME * 11.0)) - 0.5) * grain;
	COLOR = vec4(col + n, clamp(a + abs(n), 0.0, 1.0));
}
