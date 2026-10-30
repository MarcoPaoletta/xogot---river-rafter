class_name Rapids
extends Node3D
## Rapids boost zone: glowing chevrons sweep downstream; entering gives the raft a speed boost.

@export var sweep_speed: float = 1.3
@export var sweep_length: float = 2.4

var _t: float = 0.0
var _bases: Array[Vector3] = []
var _cooldown: float = 0.0

@onready var chevrons: Node3D = $Chevrons


func _ready() -> void:
	for child in chevrons.get_children():
		_bases.append((child as Node3D).position)


func _process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	for i in chevrons.get_child_count():
		var c: Node3D = chevrons.get_child(i) as Node3D
		var phase: float = fposmod(_t * sweep_speed + float(i) / chevrons.get_child_count(), 1.0)
		c.position = _bases[i] + Vector3(0.0, 0.0, -phase * sweep_length)
		var k: float = 0.75 + 0.35 * sin(phase * PI)
		c.scale = Vector3(k, 1.0, k)


func on_raft_touch(raft: Raft) -> void:
	if _cooldown > 0.0:
		return
	_cooldown = 1.0
	raft.boost()
	var tw: Tween = create_tween()
	chevrons.scale = Vector3(1.25, 1.0, 1.25)
	tw.tween_property(chevrons, ^"scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
