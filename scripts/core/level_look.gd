@tool
class_name LevelLook
extends Resource
## Per-level sun settings (tuned in the FX tuner, page 2). The level applies it to its Sun.

@export var sun_energy: float = 1.3
@export var sun_color: Color = Color(1.0, 0.95, 0.85, 1.0)
@export_range(2.0, 89.0) var sun_elevation: float = 52.0
@export_range(-180.0, 180.0) var sun_azimuth: float = 35.0
@export var shadows: bool = true


func apply(sun: DirectionalLight3D) -> void:
	if sun == null:
		return
	sun.light_energy = sun_energy
	sun.light_color = sun_color
	sun.rotation_degrees = Vector3(-sun_elevation, sun_azimuth, 0.0)
	sun.shadow_enabled = shadows
