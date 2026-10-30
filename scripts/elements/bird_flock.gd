class_name BirdFlock
extends Node3D
## Birds resting on the bank. When the raft approaches they take off, flap, climb away and
## fade out.

@export var trigger_distance: float = 24.0
@export var fly_time: float = 4.0

var _raft: Raft
var _birds: Array[Node3D] = []
var _vel: Array[Vector3] = []
var _flying: bool = false
var _t: float = 0.0


func _ready() -> void:
	for c in get_children():
		if c is Node3D and String(c.name).begins_with("Bird"):
			_birds.append(c as Node3D)
			_vel.append(Vector3.ZERO)


func _process(delta: float) -> void:
	_t += delta
	if _raft == null or not is_instance_valid(_raft) or not _raft.is_inside_tree() or not is_inside_tree():
		_raft = get_tree().get_first_node_in_group(&"raft") as Raft if is_inside_tree() else null
		return
	if not _flying:
		for i in _birds.size():
			_birds[i].position.y = maxf(0.0, sin(_t * 6.0 + i * 1.7)) * 0.12
		if global_position.distance_to(_raft.global_position) < trigger_distance:
			_take_off()
		return
	for i in _birds.size():
		var b: Node3D = _birds[i]
		_vel[i] += Vector3(0.0, 2.2, 0.0) * delta
		b.position += _vel[i] * delta
		var flap: float = sin(_t * 28.0 + i)
		b.scale = Vector3(1.0 + flap * 0.18, 1.0 - flap * 0.25, 1.0)
		b.rotation = Vector3(-0.35, b.rotation.y, flap * 0.25)


func _take_off() -> void:
	_flying = true
	for i in _birds.size():
		var away: Vector3 = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
		_vel[i] = away * randf_range(3.5, 6.0) + Vector3.UP * randf_range(3.0, 5.0)
		_birds[i].rotation.y = atan2(away.x, away.z)
	var tw: Tween = create_tween()
	tw.tween_interval(fly_time * 0.6)
	for b in _birds:
		tw.parallel().tween_property(b, ^"scale", Vector3.ONE * 0.001, fly_time * 0.4).set_delay(fly_time * 0.6)
	tw.tween_callback(queue_free)
