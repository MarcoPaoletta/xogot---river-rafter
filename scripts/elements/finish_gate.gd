class_name FinishGate
extends Node3D
## Finish banner across the river. Touching it ends the level and fires confetti.

@onready var confetti_left: GPUParticles3D = $ConfettiLeft
@onready var confetti_right: GPUParticles3D = $ConfettiRight
@onready var banner: Node3D = $Banner

var _done: bool = false
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	banner.rotation = Vector3(sin(_t * 1.7) * 0.03, 0.0, sin(_t * 1.1) * 0.015)


func on_raft_touch(raft: Raft) -> void:
	if _done or raft.autopilot != Raft.Autopilot.OFF:
		return
	_done = true
	raft.finish()
	confetti_left.restart()
	confetti_right.restart()
	confetti_left.emitting = true
	confetti_right.emitting = true
	var tw: Tween = create_tween()
	banner.scale = Vector3(1.0, 1.3, 1.0)
	tw.tween_property(banner, ^"scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
