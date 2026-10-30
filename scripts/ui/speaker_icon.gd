@tool
class_name SpeakerIcon
extends Control
## Speaker glyph: waves when sound is on, a cross when muted.

@export var muted: bool = true:
	set(value):
		muted = value
		queue_redraw()
@export var color: Color = Color(0.23, 0.14, 0.07, 1.0)


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var o: Vector2 = (size - Vector2(s, s)) * 0.5
	var body: PackedVector2Array = PackedVector2Array([
		o + Vector2(0.12, 0.38) * s, o + Vector2(0.3, 0.38) * s, o + Vector2(0.52, 0.18) * s,
		o + Vector2(0.52, 0.82) * s, o + Vector2(0.3, 0.62) * s, o + Vector2(0.12, 0.62) * s])
	draw_colored_polygon(body, color)
	var w: float = s * 0.07
	if muted:
		draw_line(o + Vector2(0.62, 0.36) * s, o + Vector2(0.88, 0.64) * s, color, w, true)
		draw_line(o + Vector2(0.88, 0.36) * s, o + Vector2(0.62, 0.64) * s, color, w, true)
	else:
		draw_arc(o + Vector2(0.5, 0.5) * s, s * 0.2, -0.9, 0.9, 12, color, w, true)
		draw_arc(o + Vector2(0.5, 0.5) * s, s * 0.34, -0.9, 0.9, 16, color, w, true)
