extends Label3D
## Floating "+1" style number: pops in, rises and fades out, then frees itself.

@export var rise: float = 1.6
@export var duration: float = 0.9


func setup(value: String, color: Color) -> void:
	text = value
	modulate = color


func _ready() -> void:
	scale = Vector3.ONE * 0.2
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, ^"scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, ^"position:y", position.y + rise, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, ^"modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	tw.chain().tween_callback(queue_free)
