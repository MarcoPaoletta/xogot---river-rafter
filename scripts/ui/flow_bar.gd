@tool
class_name FlowBar
extends Control
## FLOW meter: fills with near misses; glows and pulses while FLOW mode is active.

@export_range(0.0, 1.0) var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
@export var active: bool = false:
	set(v):
		active = v
		queue_redraw()
@export var fill_color: Color = Color(0.35, 0.92, 1.0, 1.0)
@export var active_color: Color = Color(0.75, 1.0, 1.0, 1.0)
@export var track_color: Color = Color(0.04, 0.12, 0.16, 0.75)
@export var outline_color: Color = Color(0.97, 0.94, 0.85, 1.0)

var _t: float = 0.0


func _process(delta: float) -> void:
	if active:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var r: float = size.y * 0.5
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = track_color
	sb.set_corner_radius_all(int(r))
	sb.border_color = outline_color
	sb.set_border_width_all(3)
	draw_style_box(sb, Rect2(Vector2.ZERO, size))
	if value > 0.001:
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		var pulse: float = 0.5 + 0.5 * sin(_t * 10.0)
		fill.bg_color = fill_color.lerp(active_color, pulse) if active else fill_color
		fill.set_corner_radius_all(int(r))
		if active:
			fill.shadow_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.7)
			fill.shadow_size = int(6 + pulse * 6)
		draw_style_box(fill, Rect2(Vector2(4, 4), Vector2(maxf(size.y - 8.0, (size.x - 8.0) * value), size.y - 8.0)))
