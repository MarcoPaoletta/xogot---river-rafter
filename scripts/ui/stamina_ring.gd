@tool
class_name StaminaRing
extends Control
## Round paddle button face: disc, paddle glyph and a stamina ring around it.

@export_range(0.0, 1.0) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
@export var cost: float = 0.34
@export var disc_color: Color = Color(1.0, 0.71, 0.2, 1.0)
@export var empty_color: Color = Color(0.55, 0.52, 0.47, 1.0)
@export var ring_color: Color = Color(0.4, 0.95, 1.0, 1.0)
@export var dark: Color = Color(0.23, 0.13, 0.06, 1.0)


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 8.0
	var can_paddle: bool = value >= cost
	draw_circle(c + Vector2(0, 5), r, Color(0, 0, 0, 0.35))
	draw_circle(c, r, dark)
	draw_circle(c, r - 5.0, disc_color if can_paddle else empty_color)
	draw_arc(c, r + 2.0, -PI * 0.5, -PI * 0.5 + TAU * value, 48, ring_color, 10.0, true)
	draw_circle(c, r * 0.72, Color(1, 1, 1, 0.12))
