extends Node3D
## One-shot particle effect (splash, coin burst). Fires every GPUParticles3D child once and
## frees itself after the longest lifetime.

func _ready() -> void:
	var longest: float = 0.2
	for child in get_children():
		if child is GPUParticles3D:
			var p: GPUParticles3D = child
			p.one_shot = true
			p.emitting = true
			longest = maxf(longest, p.lifetime)
	get_tree().create_timer(longest + 0.4, false).timeout.connect(queue_free)
