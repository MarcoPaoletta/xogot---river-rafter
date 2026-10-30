shader_type spatial;
render_mode specular_schlick_ggx;

// River water: flowing foam lines along the ribbon (UV.y = metres downstream), foam at the
// banks and around fork islands (UV2 = half width, island half width), white water on
// waterfall faces (COLOR.g), gentle waves, fresnel sky tint, and a FLOW glow.

uniform vec4 deep_color : source_color = vec4(0.05, 0.33, 0.42, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.22, 0.62, 0.62, 1.0);
uniform vec4 foam_color : source_color = vec4(0.94, 0.98, 1.0, 1.0);
uniform vec4 sky_tint : source_color = vec4(0.7, 0.86, 0.95, 1.0);
uniform vec4 flow_color : source_color = vec4(0.35, 0.95, 1.0, 1.0);
uniform float flow_speed = 12.0;
uniform float half_width = 9.0;
uniform float ribbon_margin = 1.2;
uniform float streak_amount = 0.55;
uniform float bank_foam = 1.3;
uniform float wave_height = 0.07;
uniform float flow_glow = 0.0;

varying float v_half_width;
varying float v_island;
varying float v_steep;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	v_half_width = UV2.x > 0.5 ? UV2.x : half_width;
	v_island = UV2.y;
	v_steep = COLOR.g;
	float s = UV.y;
	VERTEX.y += (sin(s * 0.33 - TIME * 2.6 + UV.x * 7.0) * wave_height
		+ sin(UV.x * 23.0 + s * 0.11 + TIME * 1.9) * wave_height * 0.6) * (1.0 - v_steep);
}

void fragment() {
	float width = v_half_width * 2.0 + ribbon_margin * 2.0;
	float lateral = (UV.x - 0.5) * width;
	float to_bank = v_half_width - abs(lateral);
	float to_island = v_island > 0.1 ? abs(lateral) - v_island - 0.3 : 99.0;
	float to_edge = min(to_bank, to_island);
	float speed = flow_speed * (1.0 + v_steep * 2.5);
	float s = UV.y - TIME * speed;
	vec2 p = vec2(lateral * 1.7, s * 0.075);
	float n = vnoise(p) * 0.6 + vnoise(p * 2.7 + vec2(3.1, 7.7)) * 0.4;
	float streak = smoothstep(0.66, 0.74, n) * (1.0 - smoothstep(0.8, 0.9, n)) * streak_amount;
	float ripple = vnoise(vec2(lateral * 2.2, s * 0.6));
	float edge = 1.0 - smoothstep(0.0, bank_foam, to_edge + (ripple - 0.5) * 1.2);
	float fall = v_steep * smoothstep(0.25, 0.6, vnoise(vec2(lateral * 1.3, s * 0.5)) * 0.7 + 0.45);
	float center = clamp(to_bank / v_half_width, 0.0, 1.0);
	vec3 col = mix(shallow_color.rgb, deep_color.rgb, smoothstep(0.05, 0.7, center));
	col += (ripple - 0.5) * 0.05;
	float foam = clamp(max(max(streak, edge), fall), 0.0, 1.0);
	vec3 foam_rgb = mix(foam_color.rgb, flow_color.rgb * 1.4, flow_glow * 0.6);
	col = mix(col, foam_rgb, foam);
	col += flow_color.rgb * flow_glow * 0.18 * (0.6 + 0.4 * sin(UV.y * 0.4 - TIME * 6.0));
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	ALBEDO = mix(col, sky_tint.rgb, fres * 0.45 * (1.0 - foam));
	EMISSION = flow_color.rgb * flow_glow * (0.25 + streak * 1.5);
	ROUGHNESS = mix(0.08, 0.6, foam);
	SPECULAR = 0.7;
	vec3 nrm = vec3((vnoise(p * 4.0) - 0.5) * 0.35, 1.0, (vnoise(p * 4.0 + 5.0) - 0.5) * 0.35);
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(normalize(nrm), 0.0)).xyz, 0.5));
}
