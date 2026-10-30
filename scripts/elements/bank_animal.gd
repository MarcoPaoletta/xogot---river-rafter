class_name BankAnimal
extends Node3D
## Animal on the river bank: grazes, then looks up and turns to watch the raft pass.

@export var watch_distance: float = 28.0
@export var graze_suffix: String = "Eating"
@export var watch_suffix: String = "Idle"
@export var turn_speed: float = 2.5

var _raft: Raft
var _anim: AnimationPlayer
var _graze: StringName = &""
var _watch: StringName = &""
var _base_yaw: float = 0.0
var _watching: bool = false

@onready var model: Node3D = $Model


func _ready() -> void:
	_base_yaw = model.rotation.y
	_anim = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim != null:
		for n in _anim.get_animation_list():
			if _graze == &"" and String(n).ends_with(graze_suffix):
				_graze = n
			if _watch == &"" and String(n).ends_with(watch_suffix):
				_watch = n
		for a: StringName in [_graze, _watch]:
			if a != &"":
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		if _graze != &"":
			_anim.play(_graze)
			_anim.seek(randf() * 2.0)


func _process(delta: float) -> void:
	if _raft == null or not is_instance_valid(_raft) or not _raft.is_inside_tree() or not is_inside_tree():
		_raft = get_tree().get_first_node_in_group(&"raft") as Raft if is_inside_tree() else null
		return
	var near: bool = global_position.distance_to(_raft.global_position) < watch_distance
	if near != _watching:
		_watching = near
		var a: StringName = _watch if near else _graze
		if _anim != null and a != &"":
			_anim.play(a, 0.75)
	var target: float = _base_yaw
	if _watching:
		var to: Vector3 = to_local(_raft.global_position)
		target = atan2(to.x, to.z)
	model.rotation.y = lerp_angle(model.rotation.y, target, 1.0 - exp(-turn_speed * delta))
