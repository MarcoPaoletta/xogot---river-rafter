class_name HeartPickup
extends Node3D
## Floating heart: restores one heart to the raft, with a pop and a fade-out.

@export var spin_speed: float = 1.8
@export var bob_height: float = 0.22

var _t: float = 0.0
var _taken: bool = false

@onready var model: Node3D = $Model
@onready var area: Area3D = $Area3D


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	model.rotation = Vector3(0.0, _t * spin_speed, 0.0)
	model.position = Vector3(0.0, sin(_t * 2.6) * bob_height, 0.0)
	var pulse: float = 1.0 + sin(_t * 6.0) * 0.06
	model.scale = Vector3.ONE * pulse


func on_raft_touch(raft: Raft) -> void:
	if _taken:
		return
	_taken = true
	area.set_deferred(&"monitorable", false)
	raft.heal()
	var tw: Tween = create_tween()
	tw.tween_property(model, ^"scale", Vector3.ONE * 1.8, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, ^"scale", Vector3.ONE * 0.001, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
