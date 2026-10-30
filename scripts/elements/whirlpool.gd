class_name Whirlpool
extends Node3D
## Spinning whirlpool: pulls the raft toward its centre and spins it; the player tilts away
## to escape. Reaching the eye costs a heart and throws the raft out.

@export var radius: float = 6.5
@export var strength: float = 30.0
@export var eye_radius: float = 1.3
@export var spin_speed: float = 1.4

var _raft: Raft
var _t: float = 0.0

@onready var surface: Node3D = $Surface


func _ready() -> void:
	_raft = get_tree().get_first_node_in_group(&"raft") as Raft


func _physics_process(delta: float) -> void:
	_t += delta
	surface.rotation = Vector3(0.0, -_t * spin_speed, 0.0)
	if _raft == null or not is_instance_valid(_raft) or not _raft.is_inside_tree() or not is_inside_tree():
		_raft = get_tree().get_first_node_in_group(&"raft") as Raft
		return
	var d: Vector3 = _raft.global_position - global_position
	d.y = 0.0
	var dist: float = d.length()
	if dist < radius:
		_raft.apply_whirl(global_position, strength, radius)
		if dist < eye_radius and _raft.take_hit(global_position):
			_raft.lateral_velocity += signf((_raft.global_position - global_position).dot(_raft.get_frame().basis.x)) * 6.0
