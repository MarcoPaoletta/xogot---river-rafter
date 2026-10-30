@tool
class_name HeartIcon
extends Control
## Vector heart for the HUD. filled=false draws an empty socket. pop() punches the scale.

@export var filled: bool = true:
	set(value):
		filled = value
		queue_redraw()
@export var fill_color: Color = Color(1.0, 0.33, 0.42, 1.0)
@export var empty_color: Color = Color(0.1, 0.12, 0.16, 0.45)
@export var outline_color: Color = Color(0.16, 0.06, 0.08, 1.0)


func _ready() -> void:
	pivot_offset = size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func pop(amount: float = 0.35) -> void:
	scale = Vector2.ONE * (1.0 + amount)
	var tw: Tween = create_tween()
	tw.tween_property(self, ^"scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	var r: float = minf(size.x, size.y) / 36.0
	var c: Vector2 = size * 0.5 + Vector2(0.0, -1.5 * r)
	for i in 48:
		var t: float = TAU * i / 48.0
		var x: float = 16.0 * pow(sin(t), 3.0)
		var y: float = 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		pts.append(c + Vector2(x, -y) * r)
	draw_colored_polygon(pts, fill_color if filled else empty_color)
	var closed: PackedVector2Array = pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, outline_color, maxf(2.0, r * 1.6), true)
	if filled:
		draw_circle(c + Vector2(-7.0, -5.0) * r, 2.6 * r, Color(1, 1, 1, 0.55))
