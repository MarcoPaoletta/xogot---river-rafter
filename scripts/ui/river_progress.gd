@tool
class_name RiverProgress
extends Control
## River progress track: rounded bar, filled share, raft marker and a chequered finish flag.

@export_range(0.0, 1.0) var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()
@export var track_color: Color = Color(0.05, 0.14, 0.18, 0.7)
@export var fill_color: Color = Color(0.36, 0.85, 0.95, 1.0)
@export var marker_color: Color = Color(1.0, 0.8, 0.2, 1.0)
@export var outline_color: Color = Color(0.97, 0.94, 0.85, 1.0)


func _draw() -> void:
	var h: float = size.y * 0.42
	var y: float = (size.y - h) * 0.5
	var r: float = h * 0.5
	var track: Rect2 = Rect2(Vector2(r, y), Vector2(size.x - r * 4.0, h))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = track_color
	sb.set_corner_radius_all(int(r))
	sb.border_color = outline_color
	sb.set_border_width_all(3)
	draw_style_box(sb, track)
	if value > 0.001:
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = fill_color
		fill.set_corner_radius_all(int(r))
		draw_style_box(fill, Rect2(track.position + Vector2(3, 3), Vector2(maxf(h, track.size.x * value) - 6.0, h - 6.0)))
	var fx: float = track.end.x + r * 0.8
	var cell: float = h * 0.32
	for i in 3:
		for j in 3:
			var c: Color = Color.WHITE if (i + j) % 2 == 0 else Color(0.1, 0.1, 0.12)
			draw_rect(Rect2(Vector2(fx + i * cell, y - cell * 0.5 + j * cell), Vector2(cell, cell)), c)
	var mx: float = track.position.x + track.size.x * value
	draw_circle(Vector2(mx, size.y * 0.5), size.y * 0.42, outline_color)
	draw_circle(Vector2(mx, size.y * 0.5), size.y * 0.34, marker_color)
