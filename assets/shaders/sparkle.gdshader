shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

// Four-point sparkle with a hot core, camera-facing (particle scale kept). Additive, so
// it reads as light and feeds the glow pass. Colour and fade come from particle COLOR.

uniform float intensity = 2.2;

void vertex() {
	mat4 bb = mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	bb = bb * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * bb;
}

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	float d = length(uv);
	float core = exp(-d * d * 14.0);
	float rays = max(exp(-abs(uv.x) * 26.0) * (1.0 - abs(uv.y)), exp(-abs(uv.y) * 26.0) * (1.0 - abs(uv.x)));
	float a = clamp(core + rays * 0.85, 0.0, 1.0) * COLOR.a;
	ALBEDO = COLOR.rgb * intensity * a;
	ALPHA = a;
}
