class_name Critter
extends Node3D
## Stranded animal on a rock. When the raft brushes past, the animal hops aboard in an arc,
## sits on a raft seat and multiplies coin value. On a hit it is thrown into the water,
## paddles off and fades. The rock stays behind (only the Animal node travels).

enum Mode { WAITING, HOPPING, RIDING, FALLEN }

@export var idle_suffix: String = "Idle"
@export var jump_suffix: String = "Jump"
@export var hop_time: float = 0.55
@export var hop_height: float = 2.2
@export var riding_scale: float = 0.75
@export var splash_scene: PackedScene

var mode: Mode = Mode.WAITING
var _anim: AnimationPlayer
var _idle: StringName = &""
var _jump: StringName = &""
var _t: float = 0.0

@onready var animal: Node3D = $Animal
@onready var area: Area3D = $Animal/Area3D
@onready var help_label: Label3D = get_node_or_null(^"Animal/Help") as Label3D


func _ready() -> void:
	_anim = animal.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim != null:
		for n in _anim.get_animation_list():
			if _idle == &"" and String(n).ends_with(idle_suffix):
				_idle = n
			if _jump == &"" and String(n).ends_with(jump_suffix):
				_jump = n
		if _idle != &"":
			_anim.get_animation(_idle).loop_mode = Animation.LOOP_LINEAR
			_anim.play(_idle)
			_anim.seek(randf() * 2.0)


func _process(delta: float) -> void:
	_t += delta
	if mode == Mode.WAITING and help_label != null:
		help_label.position.y = 2.1 + sin(_t * 3.0) * 0.12
		help_label.modulate.a = 0.75 + sin(_t * 5.0) * 0.25


func on_raft_touch(raft: Raft) -> void:
	if mode != Mode.WAITING:
		return
	mode = Mode.HOPPING
	area.set_deferred(&"monitorable", false)
	if help_label != null:
		help_label.visible = false
	var seat: Node3D = raft.rescue(self)
	var start_global: Vector3 = animal.global_position
	animal.reparent(seat, true)
	var start: Vector3 = seat.to_local(start_global)
	if _jump != &"" and _anim != null:
		_anim.play(_jump, 0.1)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_method(func(u: float) -> void:
		animal.position = start.lerp(Vector3.ZERO, u) + Vector3.UP * sin(u * PI) * hop_height, 0.0, 1.0, hop_time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(animal, ^"rotation", Vector3.ZERO, hop_time)
	tw.tween_property(animal, ^"scale", Vector3.ONE * riding_scale, hop_time)
	tw.chain().tween_callback(func() -> void:
		mode = Mode.RIDING
		if _idle != &"" and _anim != null:
			_anim.play(_idle, 0.3)
		animal.scale = Vector3.ONE * riding_scale * 1.25
		create_tween().tween_property(animal, ^"scale", Vector3.ONE * riding_scale, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


## Thrown off the raft by a hit: arc into the water, splash, paddle away and fade.
func fall_off(push: Vector3) -> void:
	if mode != Mode.RIDING and mode != Mode.HOPPING:
		return
	mode = Mode.FALLEN
	var world: Node = get_tree().current_scene
	animal.reparent(world, true)
	var start: Vector3 = animal.global_position
	var target: Vector3 = start + push.normalized() * 3.5 + Vector3.DOWN * 0.6
	var tw: Tween = create_tween()
	tw.tween_method(func(u: float) -> void:
		animal.global_position = start.lerp(target, u) + Vector3.UP * sin(u * PI) * 1.8, 0.0, 1.0, 0.5)
	tw.tween_callback(func() -> void:
		if splash_scene != null:
			var fx: Node3D = splash_scene.instantiate() as Node3D
			world.add_child(fx)
			fx.global_position = animal.global_position
		Audio.play(&"splash", 1.5, -4.0))
	tw.tween_property(animal, ^"global_position", target + push.normalized() * 4.0, 1.4)
	tw.parallel().tween_property(animal, ^"scale", Vector3.ONE * 0.001, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(animal.queue_free)
