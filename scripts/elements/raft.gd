class_name Raft
extends Node3D
## The player's raft. It moves in river space: distance s downstream plus a lateral offset.
## The current always pushes it forward; Tilt.steer moves it sideways and Tilt.brake slows it.
## Systems: waterfall air time, near-miss FLOW meter, whirlpool pull, paddle bursts (stamina),
## turbo booster, rescued critter crew (point multiplier), fork-island channels, and an
## autopilot used by the FX tuner. River elements call in through on_raft_touch(raft).

signal hearts_changed(hearts: int, max_hearts: int)
signal score_changed(score: int, gained: int, world_position: Vector3)
signal hit_taken(hearts: int)
signal bank_bumped
signal boosted
signal turbo_started
signal paddled
signal finished
signal capsized
signal airborne_started
signal landed(impact: float)
signal near_miss(world_position: Vector3, streak: int)
signal flow_changed(value: float, active: bool)
signal stamina_changed(value: float)
signal crew_changed(count: int)

enum State { IDLE, RAFTING, FINISHED, CAPSIZED }
enum Autopilot { OFF, ZIGZAG, STRAIGHT }

@export_group("Speed")
@export var base_speed: float = 9.0
@export var brake_speed: float = 4.8
@export var boost_speed: float = 15.5
@export var boost_duration: float = 1.6
@export var turbo_speed: float = 19.0
@export var turbo_duration: float = 3.0
@export var speed_response: float = 2.2
@export_group("Steering")
@export var steer_speed: float = 8.5
@export var steer_response: float = 5.0
@export var edge_margin: float = 1.9
@export var island_margin: float = 1.7
@export var bank_bounce: float = 0.45
@export_group("Damage")
@export var max_hearts: int = 3
@export var invulnerable_time: float = 1.5
@export var hit_speed_factor: float = 0.35
@export var hit_push: float = 7.5
@export_group("Air")
@export var gravity: float = 16.0
@export var lip_hop: float = 2.2
@export_group("Flow")
@export var near_miss_gap: float = 1.7
@export var flow_per_near_miss: float = 0.26
@export var flow_decay: float = 0.035
@export var flow_duration: float = 6.0
@export var flow_speed_bonus: float = 1.15
@export_group("Paddle")
@export var paddle_cost: float = 0.34
@export var paddle_regen: float = 0.16
@export var paddle_speed_impulse: float = 5.0
@export var paddle_dodge: float = 7.0
@export_group("Feel")
@export var bob_height: float = 0.07
@export var roll_deg: float = 10.0
@export var yaw_deg: float = 18.0
@export var anim_blend: float = 0.75
@export var hit_anim_blend: float = 0.2
@export var splash_scene: PackedScene
@export var pop_scene: PackedScene
## Wake and foam emitter settings (FX tuner page 1).
@export var fx: RaftFx

const ANIM_IDLE: StringName = &"CharacterArmature|Idle"
const ANIM_HIT: StringName = &"CharacterArmature|HitRecieve"
const ANIM_WAVE: StringName = &"CharacterArmature|Wave"
const ANIM_DEATH: StringName = &"CharacterArmature|Death"

var state: State = State.IDLE
var autopilot: Autopilot = Autopilot.OFF
var river: RiverBuilder
var s: float = 0.0
var lateral: float = 0.0
var lateral_velocity: float = 0.0
var speed: float = 0.0
var hearts: int = 3
var coins: int = 0
var score: int = 0
var elapsed: float = 0.0
var hits_taken: int = 0
var near_misses: int = 0
var flow: float = 0.0
var flow_active: bool = false
var stamina: float = 1.0
var airborne: bool = false
var whirl_amount: float = 0.0
var crew: Array[Node3D] = []
var rescued_total: int = 0
## Autopilot loops back to the start before this distance (set by the director).
var loop_distance: float = 0.0

var _boost_left: float = 0.0
var _turbo_left: float = 0.0
var _paddle_left: float = 0.0
var _flow_left: float = 0.0
var _invulnerable: float = 0.0
var _time: float = 0.0
var _yaw: float = 0.0
var _spin: float = 0.0
var _sink: float = 0.0
var _capsize_roll: float = 0.0
var _air_y: float = 0.0
var _vy: float = 0.0
var _side_lock: float = 0.0
var _frame: Transform3D = Transform3D.IDENTITY
var _coin_streak: int = 0
var _coin_streak_timer: float = 0.0
var _bank_cooldown: float = 0.0
var _last_hit_time: float = -10.0
var _miss_streak: int = 0
var _hazards: Array = []
var _hazard_index: int = 0
var _whirl_force: float = 0.0
var _whirl_slow: float = 0.0
var _anim: AnimationPlayer
var _squash_tween: Tween

@onready var visual: Node3D = $Visual
@onready var rider: Node3D = get_node_or_null(^"Visual/Rider") as Node3D
@onready var paddle_node: Node3D = get_node_or_null(^"Visual/Paddle") as Node3D
@onready var seats: Node3D = get_node_or_null(^"Visual/Seats") as Node3D
@onready var wake: GPUParticles3D = $Visual/Wake
@onready var spray_left: GPUParticles3D = $Visual/SprayLeft
@onready var spray_right: GPUParticles3D = $Visual/SprayRight
@onready var turbo_trail: GPUParticles3D = get_node_or_null(^"Visual/TurboTrail") as GPUParticles3D
@onready var hull_foam: Node3D = get_node_or_null(^"HullFoam") as Node3D
@onready var hit_area: Area3D = $HitArea


func _ready() -> void:
	add_to_group(&"raft")
	hearts = max_hearts
	if rider != null:
		_anim = rider.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim != null:
		for loop_name: StringName in [ANIM_IDLE, ANIM_WAVE]:
			if _anim.has_animation(loop_name):
				_anim.get_animation(loop_name).loop_mode = Animation.LOOP_LINEAR
		_anim.animation_finished.connect(_on_animation_finished)
	_play_anim(ANIM_IDLE, 0.0)
	hit_area.area_entered.connect(_on_area_entered)
	apply_fx()


## Applies the RaftFx resource to the wake, spray and hull foam (also called live by the tuner).
func apply_fx() -> void:
	if fx == null:
		return
	if wake.amount != fx.wake_amount:
		wake.amount = maxi(1, fx.wake_amount)
	wake.lifetime = maxf(0.1, fx.wake_lifetime)
	wake.position = fx.wake_offset
	wake.visible = fx.wake_enabled
	for sp: GPUParticles3D in [spray_left, spray_right]:
		if sp.amount != fx.spray_amount:
			sp.amount = maxi(1, fx.spray_amount)
	if hull_foam != null:
		hull_foam.visible = fx.hull_foam_enabled
		hull_foam.scale = Vector3.ONE * fx.hull_foam_scale


## Places the raft at distance start_s on the given river.
func setup(target: RiverBuilder, start_s: float) -> void:
	river = target
	s = start_s
	lateral = 0.0
	lateral_velocity = 0.0
	speed = 0.0
	_frame = river.sample_frame(s)
	_air_y = _frame.origin.y
	airborne = false
	_apply_transform(0.0)
	reset_physics_interpolation()


## Hazards used for near-miss detection (sorted by river distance).
func set_hazards(nodes: Array) -> void:
	_hazards.clear()
	for n in nodes:
		var h: Node3D = n as Node3D
		if h != null and river != null:
			_hazards.append({"node": h, "s": river.distance_of(h.global_position)})
	_hazards.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["s"] < b["s"])
	_hazard_index = 0


func start_rafting() -> void:
	state = State.RAFTING
	speed = base_speed * 0.6


func get_frame() -> Transform3D:
	return _frame


func is_boosting() -> bool:
	return _boost_left > 0.0 or _turbo_left > 0.0 or _paddle_left > 0.0


func is_turbo() -> bool:
	return _turbo_left > 0.0


## 0 at brake speed, 1 at boost speed.
func speed_ratio() -> float:
	return clampf((speed - brake_speed) / (boost_speed - brake_speed), 0.0, 1.0)


func is_invulnerable() -> bool:
	return _invulnerable > 0.0 or _turbo_left > 0.0


func coin_multiplier() -> int:
	return (1 + crew.size()) * (2 if flow_active else 1)


func _physics_process(delta: float) -> void:
	_time += delta
	if river == null:
		return
	match state:
		State.RAFTING:
			_update_rafting(delta)
		State.FINISHED:
			speed = lerpf(speed, 1.5, 1.0 - exp(-1.2 * delta))
			lateral_velocity = lerpf(lateral_velocity, 0.0, 1.0 - exp(-3.0 * delta))
			s += speed * delta
		State.CAPSIZED:
			speed = lerpf(speed, 0.0, 1.0 - exp(-2.5 * delta))
			s += speed * delta
			_sink = lerpf(_sink, 0.55, 1.0 - exp(-2.0 * delta))
			_capsize_roll = lerpf(_capsize_roll, deg_to_rad(28.0), 1.0 - exp(-3.0 * delta))
	_frame = river.sample_frame(s)
	_update_air(delta)
	_apply_transform(delta)
	_update_fx()
	_whirl_force = 0.0
	_whirl_slow = 0.0


func _steer_input() -> float:
	match autopilot:
		Autopilot.ZIGZAG:
			return clampf(sin(_time * 1.1) * 1.6, -1.0, 1.0)
		Autopilot.STRAIGHT:
			return clampf(-lateral * 0.4, -1.0, 1.0)
	return Tilt.steer


func _update_rafting(delta: float) -> void:
	elapsed += delta
	_invulnerable = maxf(0.0, _invulnerable - delta)
	_boost_left = maxf(0.0, _boost_left - delta)
	_paddle_left = maxf(0.0, _paddle_left - delta)
	_bank_cooldown = maxf(0.0, _bank_cooldown - delta)
	_coin_streak_timer = maxf(0.0, _coin_streak_timer - delta)
	if _turbo_left > 0.0:
		_turbo_left = maxf(0.0, _turbo_left - delta)
	var old_stamina: float = stamina
	stamina = minf(1.0, stamina + paddle_regen * delta)
	if absf(stamina - old_stamina) > 0.0001 and (int(stamina * 20.0) != int(old_stamina * 20.0) or stamina >= 1.0):
		stamina_changed.emit(stamina)
	_update_flow(delta)
	var brake: float = 0.0 if autopilot != Autopilot.OFF else Tilt.brake
	var target_speed: float = lerpf(base_speed, brake_speed, brake)
	if _boost_left > 0.0:
		target_speed = boost_speed
	if _turbo_left > 0.0:
		target_speed = turbo_speed
	if flow_active:
		target_speed *= flow_speed_bonus
	target_speed *= 1.0 - _whirl_slow
	speed = lerpf(speed, target_speed, 1.0 - exp(-speed_response * delta))
	var steer_k: float = 0.45 if airborne else 1.0
	lateral_velocity = lerpf(lateral_velocity, _steer_input() * steer_speed, 1.0 - exp(-steer_response * steer_k * delta))
	lateral_velocity += _whirl_force * delta
	lateral += lateral_velocity * delta
	_constrain_lateral()
	var prev_s: float = s
	s += speed * delta
	_check_near_misses(prev_s)
	var loop_at: float = loop_distance if loop_distance > 0.0 else river.get_length() - 40.0
	if autopilot != Autopilot.OFF and s > loop_at:
		debug_jump_to(30.0)


## Keeps the raft inside its channel: outer banks and the fork island.
func _constrain_lateral() -> void:
	var hw: float = river.half_width_at(s)
	var limit: float = hw - edge_margin
	var isl: float = river.island_at(s)
	if isl > 0.01:
		if _side_lock == 0.0:
			_side_lock = signf(lateral) if absf(lateral) > 0.05 else (signf(Tilt.steer) if absf(Tilt.steer) > 0.05 else 1.0)
		var inner: float = isl + island_margin
		if absf(lateral) < inner or signf(lateral) != _side_lock:
			lateral = _side_lock * inner
			if signf(lateral_velocity) != _side_lock:
				lateral_velocity = -lateral_velocity * bank_bounce
	else:
		_side_lock = 0.0
	if absf(lateral) > limit:
		lateral = signf(lateral) * limit
		if signf(lateral_velocity) == signf(lateral):
			var impact: float = absf(lateral_velocity)
			lateral_velocity = -lateral_velocity * bank_bounce
			if impact > 2.5 and _bank_cooldown <= 0.0:
				_bank_cooldown = 0.5
				_spawn_splash(global_position + _frame.basis.x * signf(lateral) * 1.2, 0.6)
				Audio.play(&"splash", 1.3, -6.0)
				_squash(0.12)
				bank_bumped.emit()


func _update_air(delta: float) -> void:
	var water_y: float = _frame.origin.y
	if state != State.RAFTING and not airborne:
		_air_y = water_y
		return
	if not airborne:
		if state == State.RAFTING and river.water_steepness_at(s + 0.6) > 0.25:
			airborne = true
			_air_y = water_y
			_vy = lip_hop
			airborne_started.emit()
		else:
			_air_y = water_y
			return
	_vy -= gravity * delta
	_air_y += _vy * delta
	if _air_y <= water_y:
		var impact: float = -_vy
		_air_y = water_y
		_vy = 0.0
		airborne = false
		_spawn_splash(global_position, clampf(impact * 0.18, 0.8, 2.6))
		Audio.play(&"splash", 0.75, 0.0)
		_squash(clampf(impact * 0.03, 0.1, 0.35))
		landed.emit(impact)


func _update_flow(delta: float) -> void:
	if flow_active:
		_flow_left -= delta
		flow = clampf(_flow_left / flow_duration, 0.0, 1.0)
		if _flow_left <= 0.0:
			flow_active = false
			flow = 0.0
		flow_changed.emit(flow, flow_active)
	elif flow > 0.0:
		flow = maxf(0.0, flow - flow_decay * delta)
		flow_changed.emit(flow, false)


func _check_near_misses(prev_s: float) -> void:
	while _hazard_index < _hazards.size() and _hazards[_hazard_index]["s"] < prev_s - 1.0:
		_hazard_index += 1
	var i: int = _hazard_index
	while i < _hazards.size() and _hazards[i]["s"] <= s:
		var entry: Dictionary = _hazards[i]
		var node: Node3D = entry["node"] as Node3D
		if entry["s"] > prev_s and is_instance_valid(node) and _time - _last_hit_time > 0.4:
			var hl: float = (node.global_position - _frame.origin).dot(_frame.basis.x)
			var radius: float = float(node.get(&"near_radius")) if node.get(&"near_radius") != null else 1.05
			var gap: float = absf(lateral - hl) - radius - 0.9
			if gap > 0.0 and gap < near_miss_gap:
				_register_near_miss(node.global_position)
		i += 1


func _register_near_miss(at: Vector3) -> void:
	near_misses += 1
	_miss_streak += 1
	Audio.play(&"coin", minf(1.3 + 0.08 * _miss_streak, 2.0), -4.0)
	_spawn_pop(at + Vector3.UP * 2.2, "CLOSE!", Color(0.45, 0.95, 1.0, 1.0))
	near_miss.emit(at, _miss_streak)
	if not flow_active:
		flow = minf(1.0, flow + flow_per_near_miss)
		if flow >= 1.0:
			flow_active = true
			_flow_left = flow_duration
			Audio.play(&"boost", 1.25)
		flow_changed.emit(flow, flow_active)


func _apply_transform(delta: float) -> void:
	var steer_t: float = clampf(lateral_velocity / steer_speed, -1.0, 1.0)
	var k: float = 1.0 - exp(-6.0 * delta) if delta > 0.0 else 1.0
	_yaw = lerpf(_yaw, -steer_t * deg_to_rad(yaw_deg), k)
	_spin = lerpf(_spin, 0.0, 1.0 - exp(-1.5 * delta)) if whirl_amount < 0.05 else _spin + whirl_amount * 5.0 * delta
	whirl_amount = lerpf(whirl_amount, 0.0, 1.0 - exp(-4.0 * delta)) if delta > 0.0 else whirl_amount
	var raft_basis: Basis = _frame.basis * Basis(Vector3.UP, _yaw + _spin)
	var pos: Vector3 = _frame.origin + _frame.basis.x * lateral
	pos.y = _air_y
	global_transform = Transform3D(raft_basis, pos)
	var air_pitch: float = clampf(-_vy * 0.05, -0.45, 0.3) if airborne else 0.0
	var roll: float = -steer_t * deg_to_rad(roll_deg) + sin(_time * 2.1) * 0.03 + _capsize_roll
	var pitch: float = sin(_time * 1.7) * 0.025 - speed_ratio() * 0.05 + air_pitch
	visual.position = Vector3(0.0, (0.0 if airborne else sin(_time * 2.6) * bob_height) - _sink, 0.0)
	visual.rotation = Vector3(pitch, 0.0, roll)
	visual.visible = _invulnerable <= 0.0 or fmod(_invulnerable, 0.16) > 0.06


func _update_fx() -> void:
	var moving: bool = (state == State.RAFTING or state == State.FINISHED) and not airborne
	wake.emitting = moving and speed > 1.0
	wake.amount_ratio = clampf(speed / boost_speed, 0.2, 1.0)
	spray_left.emitting = moving and lateral_velocity < -3.0
	spray_right.emitting = moving and lateral_velocity > 3.0
	if turbo_trail != null:
		turbo_trail.emitting = _turbo_left > 0.0 or flow_active
	if hull_foam != null:
		hull_foam.visible = not airborne and (fx == null or fx.hull_foam_enabled)


func _on_area_entered(area: Area3D) -> void:
	var element: Node = area.get_parent()
	for i in 3:
		if element == null:
			return
		if element.has_method(&"on_raft_touch"):
			element.call(&"on_raft_touch", self)
			return
		element = element.get_parent()


## Rock or log impact. Returns true when the hit was accepted (no damage during turbo).
func take_hit(from_position: Vector3) -> bool:
	if state != State.RAFTING or is_invulnerable():
		return false
	var hazard_lateral: float = (from_position - _frame.origin).dot(_frame.basis.x)
	var away: float = signf(lateral - hazard_lateral)
	if away == 0.0:
		away = 1.0
	lateral_velocity = away * hit_push
	speed *= hit_speed_factor
	_invulnerable = invulnerable_time
	_last_hit_time = _time
	_miss_streak = 0
	hits_taken += 1
	if not GameState.god_mode and autopilot == Autopilot.OFF:
		hearts = maxi(0, hearts - 1)
	flow = 0.0
	flow_active = false
	flow_changed.emit(0.0, false)
	_lose_crew_member()
	_spawn_splash(global_position + Vector3.UP * 0.3, 1.5)
	Audio.play(&"hit")
	Audio.play(&"splash", 0.8, -3.0)
	_squash(0.28)
	hearts_changed.emit(hearts, max_hearts)
	hit_taken.emit(hearts)
	if hearts <= 0:
		_capsize()
	else:
		_play_anim(ANIM_HIT, hit_anim_blend)
	return true


## Coin pickup: value is multiplied by the crew and FLOW.
func add_coin(world_position: Vector3, base_value: int = 1) -> void:
	coins += 1
	var gained: int = base_value * coin_multiplier()
	score += gained
	_coin_streak = _coin_streak + 1 if _coin_streak_timer > 0.0 else 0
	_coin_streak_timer = 1.2
	Audio.play(&"coin", minf(1.0 + 0.06 * _coin_streak, 2.0))
	var col: Color = Color(0.45, 0.95, 1.0, 1.0) if flow_active else Color("ffd84a")
	_spawn_pop(world_position, "+%d" % gained, col)
	score_changed.emit(score, gained, world_position)


func heal() -> void:
	if hearts < max_hearts:
		hearts += 1
	Audio.play(&"heart")
	_spawn_pop(global_position + Vector3.UP * 2.4, "+♥", Color("ff5a6e"))
	_squash(0.15)
	hearts_changed.emit(hearts, max_hearts)


func boost() -> void:
	if state != State.RAFTING:
		return
	_boost_left = boost_duration
	Audio.play(&"boost")
	_spawn_splash(global_position, 0.9)
	boosted.emit()


## Turbo booster pickup: big speed, smash through rocks.
func turbo() -> void:
	if state != State.RAFTING:
		return
	_turbo_left = turbo_duration
	Audio.play(&"boost", 0.8)
	_spawn_pop(global_position + Vector3.UP * 2.6, "TURBO!", Color(0.45, 0.8, 1.0, 1.0))
	_squash(0.2)
	turbo_started.emit()


## Paddle burst (HUD button or a hard shake): speed kick plus a dodge in the steer direction.
func paddle() -> bool:
	if state != State.RAFTING or stamina < paddle_cost:
		Audio.play(&"click", 0.6, -4.0)
		return false
	stamina -= paddle_cost
	stamina_changed.emit(stamina)
	_paddle_left = 0.5
	speed += paddle_speed_impulse
	var dir: float = signf(Tilt.steer) if absf(Tilt.steer) > 0.15 else 0.0
	lateral_velocity += dir * paddle_dodge
	spray_left.restart()
	spray_right.restart()
	_spawn_splash(global_position + _frame.basis.z * 1.5, 0.7)
	Audio.play(&"splash", 1.4, -2.0)
	_squash(0.14)
	if paddle_node != null:
		var tw: Tween = create_tween()
		var base_rot: Vector3 = paddle_node.rotation
		tw.tween_property(paddle_node, ^"rotation", base_rot + Vector3(0.0, 0.0, -0.9), 0.12).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(paddle_node, ^"rotation", base_rot, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	paddled.emit()
	return true


## Called every physics frame by a whirlpool the raft is inside.
func apply_whirl(center: Vector3, strength: float, radius: float) -> void:
	if state != State.RAFTING:
		return
	var center_lateral: float = (center - _frame.origin).dot(_frame.basis.x)
	var d: float = Vector2(center_lateral - lateral, (center - _frame.origin).dot(-_frame.basis.z)).length()
	var t: float = clampf(1.0 - d / radius, 0.0, 1.0)
	_whirl_force += signf(center_lateral - lateral) * strength * t
	_whirl_slow = maxf(_whirl_slow, t * 0.45)
	whirl_amount = maxf(whirl_amount, t)


## A critter hops aboard. Returns the seat node it should sit on.
func rescue(critter: Node3D) -> Node3D:
	crew.append(critter)
	rescued_total += 1
	Audio.play(&"heart", 1.2)
	_spawn_pop(global_position + Vector3.UP * 2.6, "RESCUED! x%d" % (1 + crew.size()), Color(0.6, 1.0, 0.55, 1.0))
	crew_changed.emit(crew.size())
	var seat: Node3D = seats.get_child(mini(crew.size() - 1, seats.get_child_count() - 1)) as Node3D if seats != null else visual
	return seat


func _lose_crew_member() -> void:
	if crew.is_empty():
		return
	var critter: Node3D = crew.pop_back()
	crew_changed.emit(crew.size())
	if is_instance_valid(critter) and critter.has_method(&"fall_off"):
		critter.call(&"fall_off", _frame.basis.x * signf(lateral_velocity if lateral_velocity != 0.0 else 1.0))


func finish() -> void:
	if state != State.RAFTING or autopilot != Autopilot.OFF:
		return
	state = State.FINISHED
	_boost_left = 0.0
	_turbo_left = 0.0
	_invulnerable = 0.0
	_play_anim(ANIM_WAVE, anim_blend)
	_celebrate()
	finished.emit()


## Debug helpers (F1 panel, tuner).
func debug_add_coins(amount: int) -> void:
	for i in amount:
		add_coin(global_position + Vector3.UP * 2.0)


func debug_jump_to(distance: float) -> void:
	s = distance
	_frame = river.sample_frame(s)
	_air_y = _frame.origin.y
	airborne = false
	_vy = 0.0
	_hazard_index = 0
	_apply_transform(0.0)
	reset_physics_interpolation()


func _capsize() -> void:
	state = State.CAPSIZED
	_play_anim(ANIM_DEATH, hit_anim_blend)
	capsized.emit()


func _celebrate() -> void:
	var tw: Tween = create_tween()
	tw.tween_property(visual, ^"scale", Vector3(1.2, 0.8, 1.2), 0.12)
	tw.tween_property(visual, ^"scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_spawn_splash(global_position, 1.2)


func _squash(amount: float) -> void:
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	visual.scale = Vector3(1.0 + amount, 1.0 - amount, 1.0 + amount)
	_squash_tween = create_tween()
	_squash_tween.tween_property(visual, ^"scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _spawn_splash(at: Vector3, size: float) -> void:
	if splash_scene == null:
		return
	var burst: Node3D = splash_scene.instantiate() as Node3D
	get_parent().add_child(burst)
	burst.global_position = at
	burst.scale = Vector3.ONE * size


func _spawn_pop(at: Vector3, label: String, color: Color) -> void:
	if pop_scene == null:
		return
	var pop: Node3D = pop_scene.instantiate() as Node3D
	get_parent().add_child(pop)
	pop.global_position = at
	if pop.has_method(&"setup"):
		pop.call(&"setup", label, color)


func _play_anim(anim_name: StringName, blend: float) -> void:
	if _anim == null or not _anim.has_animation(anim_name):
		return
	if _anim.current_animation != anim_name or not _anim.is_playing():
		_anim.play(anim_name, blend)


func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == ANIM_HIT and state == State.RAFTING:
		_play_anim(ANIM_IDLE, anim_blend)
