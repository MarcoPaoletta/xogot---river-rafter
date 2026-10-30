extends Node
## Tilt steering service. Converts the device gravity sensor (landscape),
## keyboard and touch into a smoothed steer value [-1, 1] and a brake value [0, 1].
## Roll (steering-wheel tilt) steers; tilting the top edge back toward you brakes.
## calibrate() stores the current hold angle as neutral.

signal calibrated
## Fired by a hard shake/flick of the phone (linear acceleration above shake_threshold).
signal shaken

## Roll, in degrees from neutral, that gives full steering lock.
@export var full_lock_deg: float = 22.0
## Steering below this (normalized) is ignored.
@export var deadzone: float = 0.06
@export var brake_start_deg: float = 8.0
@export var brake_full_deg: float = 22.0
@export var steer_smoothing: float = 12.0
@export var brake_smoothing: float = 8.0
## Linear acceleration (m/s², gravity removed) that counts as an aggressive shake.
@export var shake_threshold: float = 13.0
@export var shake_cooldown: float = 0.55

var _shake_timer: float = 0.0

## Smoothed outputs read by the raft.
var steer: float = 0.0
var brake: float = 0.0
var has_sensor: bool = false
## Debug readouts.
var roll_deg: float = 0.0
var pitch_deg: float = 0.0

var _neutral: Vector3 = Vector3(0.0, -0.7, -0.7)
var _axis_sign: float = 0.0
var _touches: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var g: Vector3 = _read_gravity()
	has_sensor = g.length_squared() > 0.01
	var target_steer: float = 0.0
	var target_brake: float = 0.0
	if has_sensor:
		var gs: Vector3 = _to_screen(g).normalized()
		var n0: Vector3 = _to_screen(_neutral).normalized()
		roll_deg = rad_to_deg(asin(clampf(gs.x, -1.0, 1.0)) - asin(clampf(n0.x, -1.0, 1.0)))
		pitch_deg = rad_to_deg(atan2(gs.z, -gs.y) - atan2(n0.z, -n0.y))
		target_steer = clampf(roll_deg * GameState.tilt_sensitivity / full_lock_deg, -1.0, 1.0)
		if GameState.invert_steer:
			target_steer = -target_steer
		target_brake = clampf((pitch_deg - brake_start_deg) / (brake_full_deg - brake_start_deg), 0.0, 1.0)
	else:
		target_steer = _touch_steer()
	var keys: float = Input.get_axis(&"steer_left", &"steer_right")
	if absf(keys) > 0.01:
		target_steer = keys
	if Input.is_action_pressed(&"slow_down"):
		target_brake = 1.0
	if absf(target_steer) < deadzone:
		target_steer = 0.0
	_shake_timer = maxf(0.0, _shake_timer - delta)
	var accel: Vector3 = Input.get_accelerometer()
	if accel.length_squared() > 0.01 and has_sensor:
		var linear: Vector3 = accel - Input.get_gravity()
		if linear.length() > shake_threshold and _shake_timer <= 0.0:
			_shake_timer = shake_cooldown
			shaken.emit()
	steer = lerpf(steer, target_steer, 1.0 - exp(-steer_smoothing * delta))
	brake = lerpf(brake, target_brake, 1.0 - exp(-brake_smoothing * delta))


## Stores the current device angle as neutral (called on GO and from the pause menu).
func calibrate() -> void:
	var g: Vector3 = _read_gravity()
	if g.length_squared() > 0.01:
		_neutral = g
		# Sensor axes still in portrait while the screen is landscape: gravity lies along X.
		var n: Vector3 = g.normalized()
		_axis_sign = -signf(n.x) if absf(n.x) > 0.55 else 0.0
	calibrated.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_touches[touch.index] = touch.position.x
		else:
			_touches.erase(touch.index)
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		_touches[drag.index] = drag.position.x


func _read_gravity() -> Vector3:
	var g: Vector3 = Input.get_gravity()
	if g.length_squared() < 0.01:
		g = Input.get_accelerometer()
	return g


## Maps raw sensor axes to screen axes (x right, y up) when the platform did not.
func _to_screen(g: Vector3) -> Vector3:
	if _axis_sign == 0.0:
		return g
	return Vector3(_axis_sign * g.y, _axis_sign * g.x, g.z)


func _touch_steer() -> float:
	if _touches.is_empty():
		return 0.0
	var width: float = get_viewport().get_visible_rect().size.x
	var total: float = 0.0
	for x: float in _touches.values():
		total += -1.0 if x < width * 0.5 else 1.0
	return clampf(total, -1.0, 1.0)
