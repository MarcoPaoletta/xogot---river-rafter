class_name FishJump
extends Node3D
## A fish that leaps across the river in an arc when the raft comes near, with a splash on
## take-off and landing. Local X is the river's lateral axis.

@export var trigger_distance: float = 32.0
@export var min_distance: float = 7.0
@export var span: float = 11.0
@export var height: float = 3.4
@export var duration: float = 1.05
@export var repeat_delay: float = 2.2
@export var splash_scene: PackedScene

var _raft: Raft
var _u: float = -1.0
var _cool: float = 0.0
var _dir: float = 1.0

@onready var fish: Node3D = $Fish


func _ready() -> void:
	fish.visible = false
	var ap: AnimationPlayer = fish.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null and ap.get_animation_list().size() > 0:
		var a: StringName = ap.get_animation_list()[0]
		ap.get_animation(a).loop_mode = Animation.LOOP_LINEAR
		ap.play(a)


func _process(delta: float) -> void:
	if _raft == null or not is_instance_valid(_raft) or not _raft.is_inside_tree() or not is_inside_tree():
		_raft = get_tree().get_first_node_in_group(&"raft") as Raft if is_inside_tree() else null
		return
	if _u < 0.0:
		_cool -= delta
		var d: float = global_position.distance_to(_raft.global_position)
		if _cool <= 0.0 and d < trigger_distance and d > min_distance:
			_u = 0.0
			_dir = -_dir
			fish.visible = true
			_splash(_point(0.0))
		return
	_u += delta / duration
	var u: float = minf(_u, 1.0)
	var p: Vector3 = _point(u)
	var ahead: Vector3 = _point(minf(u + 0.02, 1.0)) - p
	fish.position = p
	fish.rotation = Vector3(0.0, 0.0, atan2(ahead.y, ahead.x * _dir) * _dir)
	fish.scale = Vector3(_dir, 1.0, 1.0)
	if _u >= 1.0:
		_splash(p)
		fish.visible = false
		_u = -1.0
		_cool = repeat_delay


func _point(u: float) -> Vector3:
	return Vector3(lerpf(-span * 0.5, span * 0.5, u) * _dir, sin(u * PI) * height - 0.3, 0.0)


func _splash(local_pos: Vector3) -> void:
	if splash_scene == null:
		return
	var fx: Node3D = splash_scene.instantiate() as Node3D
	get_parent().add_child(fx)
	fx.global_position = to_global(local_pos)
	fx.scale = Vector3.ONE * 0.6
