@tool
class_name CoinIcon
extends Control
## Gold star-coin glyph for the HUD counter.

func _draw() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	draw_circle(c, s * 0.48, Color(0.45, 0.28, 0.05))
	draw_circle(c, s * 0.42, Color(1.0, 0.78, 0.2))
	draw_circle(c, s * 0.33, Color(1.0, 0.88, 0.4))
	var pts: PackedVector2Array = PackedVector2Array()
	for k in 10:
		var a: float = -PI * 0.5 + TAU * k / 10.0
		var rad: float = s * 0.26 if k % 2 == 0 else s * 0.11
		pts.append(c + Vector2(cos(a), sin(a)) * rad)
	draw_colored_polygon(pts, Color(0.95, 0.62, 0.1))
