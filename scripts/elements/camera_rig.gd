class_name CameraRig
extends Node3D
## Chase camera for the raft. Position follow is rigid (no lerp lag); smoothing lives in
## rotation, FOV and shake. MENU mode orbits the raft slowly behind the title screen;
## switching modes blends over blend_time with ease-in-out.

enum Mode { MENU, FOLLOW, CELEBRATE }

@export var distance: float = 8.5
@export var height: float = 4.3
@export var look_ahead: float = 9.0
@export var look_height: float = 0.6
@export var lateral_follow: float = 0.7
@export var rotation_smoothing: float = 4.0
@export var base_fov: float = 62.0
@export var boost_fov: float = 76.0
@export var fov_smoothing: float = 4.0
@export var shake_max_offset: float = 0.45
@export var shake_max_roll_deg: float = 3.0
@export var trauma_decay: float = 1.5
@export var menu_orbit_speed: float = 0.12
@export var menu_radius: float = 10.0
@export var menu_height: float = 3.6
@export var blend_time: float = 1.2
## Fraction of the half screen width to shift the framing (FX tuner shows the raft on the right).
@export_range(0.0, 1.0) var view_shift: float = 0.0
## Tuner framing: closer, lower and tighter than gameplay.
@export var tuner_distance: float = 5.6
@export var tuner_height: float = 2.6
@export var tuner_fov: float = 44.0

var _shift_k: float = 0.0
@export var air_look_drop: float = 3.5
@export var whirl_roll_deg: float = 7.0

var _air_look: float = 0.0

var mode: Mode = Mode.MENU
var target: Raft

var _basis: Basis = Basis.IDENTITY
var _trauma: float = 0.0
var _orbit: float = 0.6
var _shake_t: float = 0.0
var _blend: float = 1.0
var _from: Transform3D = Transform3D.IDENTITY

@onready var camera: Camera3D = $Camera3D


func set_target(raft: Raft) -> void:
	target = raft
	_basis = raft.get_frame().basis
	_update_pose(0.0, true)


func set_mode(new_mode: Mode, instant: bool = false) -> void:
	if new_mode == mode:
		return
	_from = global_transform
	mode = new_mode
	_blend = 1.0 if instant else 0.0
	if new_mode == Mode.CELEBRATE and target != null:
		var back: Vector3 = -target.get_frame().basis.z
		_orbit = atan2(back.x, back.z)


## Adds screen shake (0..1). Shake grows with trauma squared.
func add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)


func _process(delta: float) -> void:
	_update_pose(delta, false)


func _update_pose(delta: float, snap: bool) -> void:
	if target == null:
		return
	var anchor: Vector3 = target.get_global_transform_interpolated().origin
	var desired: Transform3D
	if mode == Mode.FOLLOW:
		var k: float = 1.0 if snap else 1.0 - exp(-rotation_smoothing * delta)
		_basis = _basis.slerp(target.get_frame().basis.orthonormalized(), k).orthonormalized()
		var fwd: Vector3 = -_basis.z
		var center: Vector3 = anchor - _basis.x * (target.lateral * (1.0 - lateral_follow))
		var air_k: float = 1.0 if snap else 1.0 - exp(-4.0 * delta)
		_air_look = lerpf(_air_look, air_look_drop if target.airborne else 0.0, air_k)
		_shift_k = view_shift if snap else lerpf(_shift_k, view_shift, 1.0 - exp(-4.0 * delta))
		var dist: float = lerpf(distance, tuner_distance, _shift_k)
		var hgt: float = lerpf(height, tuner_height, _shift_k)
		var pos: Vector3 = center - fwd * dist + Vector3.UP * (hgt + _air_look * 0.4)
		desired = Transform3D(Basis.IDENTITY, pos).looking_at(center + fwd * look_ahead + Vector3.UP * (look_height - _air_look), Vector3.UP)
	else:
		_orbit += delta * (menu_orbit_speed if mode == Mode.MENU else menu_orbit_speed * 1.6)
		var radius: float = menu_radius if mode == Mode.MENU else menu_radius * 0.75
		var pos2: Vector3 = anchor + Vector3(sin(_orbit), 0.0, cos(_orbit)) * radius + Vector3.UP * menu_height
		desired = Transform3D(Basis.IDENTITY, pos2).looking_at(anchor + Vector3.UP * 1.2, Vector3.UP)
	if _blend < 1.0 and not snap:
		_blend = minf(1.0, _blend + delta / blend_time)
		var e: float = ease(_blend, -2.2)
		global_transform = _from.interpolate_with(desired, e)
	else:
		global_transform = desired
	var fov_target: float = base_fov + target.speed_ratio() * 5.0
	if target.is_boosting():
		fov_target = boost_fov
	fov_target = lerpf(fov_target, tuner_fov, _shift_k)
	camera.fov = fov_target if snap else lerpf(camera.fov, fov_target, 1.0 - exp(-fov_smoothing * delta))
	_trauma = maxf(0.0, _trauma - trauma_decay * delta)
	_shake_t += delta * 32.0
	var amount: float = _trauma * _trauma
	camera.position = Vector3(sin(_shake_t * 1.31) + sin(_shake_t * 2.7) * 0.5, cos(_shake_t * 1.73) + sin(_shake_t * 3.1) * 0.5, 0.0) * shake_max_offset * amount
	# Tuner framing: off-axis perspective (lens shift) puts the raft in the right part of the
	# screen with no stretching and without moving or turning the camera.
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var aspect: float = vp.x / maxf(1.0, vp.y)
	if _shift_k > 0.002:
		var half_h: float = camera.near * tan(deg_to_rad(camera.fov) * 0.5)
		camera.projection = Camera3D.PROJECTION_FRUSTUM
		camera.size = half_h * 2.0
		camera.frustum_offset = Vector2(-_shift_k * 0.44 * half_h * aspect, 0.0)
	else:
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.rotation = Vector3(0.0, 0.0, sin(_shake_t * 1.9) * deg_to_rad(shake_max_roll_deg) * amount + sin(_shake_t * 0.12) * deg_to_rad(whirl_roll_deg) * target.whirl_amount)
