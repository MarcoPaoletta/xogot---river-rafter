class_name Booster
extends Node3D
## Turbo booster gem: hovering, glowing pickup. Touching it gives the raft TURBO
## (high speed, smash through rocks) with a burst and fade-out.

@export var spin_speed: float = 2.0
@export var burst_scene: PackedScene

var _t: float = 0.0
var _taken: bool = false

@onready var model: Node3D = $Model
@onready var area: Area3D = $Area3D


func _process(delta: float) -> void:
	if _taken:
		return
	_t += delta
	model.rotation = Vector3(0.0, _t * spin_speed, 0.0)
	model.position = Vector3(0.0, sin(_t * 2.4) * 0.25, 0.0)
	var k: float = 1.0 + sin(_t * 7.0) * 0.06
	model.scale = Vector3.ONE * k


func on_raft_touch(raft: Raft) -> void:
	if _taken:
		return
	_taken = true
	area.set_deferred(&"monitorable", false)
	raft.turbo()
	if burst_scene != null:
		var fx: Node3D = burst_scene.instantiate() as Node3D
		get_parent().add_child(fx)
		fx.global_position = global_position
		fx.scale = Vector3.ONE * 2.0
	var tw: Tween = create_tween()
	tw.tween_property(model, ^"scale", Vector3.ONE * 1.9, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, ^"scale", Vector3.ONE * 0.001, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)
