shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Expanding pickup ring (one particle): thin bright circle, camera-facing.

uniform float intensity = 1.8;
uniform float thickness = 0.12;

void vertex() {
	mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	bb = bb * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float a = smoothstep(0.82 - thickness, 0.82, d) * (1.0 - smoothstep(0.82, 0.82 + thickness, d));
	a *= COLOR.a;
	ALBEDO = COLOR.rgb * intensity * a;
	ALPHA = a;
}
