class_name Coin
extends Node3D
## Floating star coin (value 1) or treasure coin (higher value). Spins and bobs; on touch it
## pops, bursts and fades out. The raft multiplies the value by its crew and FLOW.

@export var value: int = 1
@export var spin_speed: float = 2.6
@export var bob_height: float = 0.18
@export var burst_scene: PackedScene

var _t: float = 0.0
var _taken: bool = false

@onready var model: Node3D = $Model
@onready var area: Area3D = $Area3D


func _ready() -> void:
	_t = randf() * TAU


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	model.rotation = Vector3(0.0, _t * spin_speed, 0.0)
	model.position = Vector3(0.0, sin(_t * 2.2) * bob_height, 0.0)


func on_raft_touch(raft: Raft) -> void:
	if _taken:
		return
	_taken = true
	area.set_deferred(&"monitorable", false)
	area.set_deferred(&"monitoring", false)
	raft.add_coin(global_position + Vector3.UP * 1.3, value)
	if burst_scene != null:
		var fx: Node3D = burst_scene.instantiate() as Node3D
		get_parent().add_child(fx)
		fx.global_position = global_position
		fx.scale = Vector3.ONE * (1.0 if value <= 1 else 1.8)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(model, ^"scale", Vector3.ONE * 1.7, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, ^"position:y", model.position.y + 1.6, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, ^"rotation:y", model.rotation.y + TAU * 1.5, 0.35)
	tw.chain().tween_property(model, ^"scale", Vector3.ONE * 0.001, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)
