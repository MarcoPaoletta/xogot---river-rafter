class_name Hazard
extends Node3D
## River hazard (rock or floating log). Touching it costs the raft a heart and bounces it away;
## during turbo the raft smashes it. Logs drift across the current with drift_amplitude > 0.
## near_radius is the hazard's lateral half-size used for near-miss (FLOW) detection.

@export var drift_amplitude: float = 0.0
@export var drift_speed: float = 0.7
@export var foam_pulse: float = 0.08
@export var near_radius: float = 1.05
@export var splash_scene: PackedScene

var _origin: Vector3 = Vector3.ZERO
var _t: float = 0.0
var _punch: Tween
var _smashed: bool = false

@onready var model: Node3D = $Model
@onready var foam: Node3D = get_node_or_null(^"Foam") as Node3D
@onready var area: Area3D = $Area3D


func _ready() -> void:
	add_to_group(&"hazard")
	_origin = position
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	_t += delta
	if drift_amplitude > 0.0 and not _smashed:
		position = _origin + transform.basis.x.normalized() * sin(_t * drift_speed) * drift_amplitude
	if foam != null:
		var k: float = 1.0 + sin(_t * 3.2) * foam_pulse
		foam.scale = Vector3(k, 1.0, k)


func on_raft_touch(raft: Raft) -> void:
	if _smashed:
		return
	if raft.is_turbo():
		_smash(raft)
		return
	if not raft.take_hit(global_position):
		return
	if _punch != null and _punch.is_valid():
		_punch.kill()
	model.scale = Vector3.ONE * 1.15
	_punch = create_tween()
	_punch.tween_property(model, ^"scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _smash(raft: Raft) -> void:
	_smashed = true
	area.set_deferred(&"monitorable", false)
	Audio.play(&"hit", 1.4, -2.0)
	if splash_scene != null:
		var fx: Node3D = splash_scene.instantiate() as Node3D
		get_parent().add_child(fx)
		fx.global_position = global_position
		fx.scale = Vector3.ONE * 1.6
	raft.score += 3
	raft.score_changed.emit(raft.score, 3, global_position)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(model, ^"position:y", model.position.y + 2.5, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, ^"rotation", Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)), 0.5)
	tw.tween_property(model, ^"scale", Vector3.ONE * 0.001, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if foam != null:
		tw.tween_property(foam, ^"scale", Vector3.ONE * 0.001, 0.4)
