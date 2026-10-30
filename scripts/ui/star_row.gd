@tool
class_name StarRow
extends Control
## Row of vector stars: count stars, the first 'filled' are gold. pop_star(i) animates one.

@export var count: int = 3:
	set(value):
		count = value
		queue_redraw()
@export var filled: int = 0:
	set(value):
		filled = value
		queue_redraw()
@export var fill_color: Color = Color(1.0, 0.82, 0.22, 1.0)
@export var empty_color: Color = Color(0.05, 0.08, 0.1, 0.4)
@export var outline_color: Color = Color(0.22, 0.12, 0.03, 1.0)

var _scales: Array[float] = [1.0, 1.0, 1.0, 1.0, 1.0]


func pop_star(index: int) -> void:
	if index < 0 or index >= _scales.size():
		return
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void:
		_scales[index] = v
		queue_redraw(), 1.8, 1.0, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	if count <= 0:
		return
	var cell: float = size.x / count
	var radius: float = minf(cell, size.y) * 0.42
	for i in count:
		var center: Vector2 = Vector2(cell * (i + 0.5), size.y * 0.5)
		var rr: float = radius * _scales[mini(i, _scales.size() - 1)]
		var pts: PackedVector2Array = PackedVector2Array()
		for k in 10:
			var a: float = -PI * 0.5 + TAU * k / 10.0
			var rad: float = rr if k % 2 == 0 else rr * 0.45
			pts.append(center + Vector2(cos(a), sin(a)) * rad)
		draw_colored_polygon(pts, fill_color if i < filled else empty_color)
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, outline_color, maxf(2.0, rr * 0.09), true)
