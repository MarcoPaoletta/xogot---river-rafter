@tool
class_name RiverLevel
extends Node3D
## One river level: authored river path, hazards, pickups, rapids, decor, light and environment.
## The director reads start/finish distances and coin totals from here.

@export var display_name: String = "Pine Gorge"
@export var start_distance: float = 26.0
@export var finish_distance: float = 470.0
## Fraction of coins needed for the second star.
@export var coin_star_ratio: float = 0.5
## Fraction of coins needed (with at most one hit) for the third star.
@export var coin_three_star_ratio: float = 0.85

## Sun settings (FX tuner page 2).
@export var look: LevelLook

@onready var river: RiverBuilder = $River
@onready var pickups: Node3D = $Pickups
@onready var ambient: GPUParticles3D = get_node_or_null(^"Ambient") as GPUParticles3D


func _ready() -> void:
	apply_look()


func apply_look() -> void:
	if look != null:
		look.apply(get_node_or_null(^"Sun") as DirectionalLight3D)


func get_environment() -> Environment:
	var we: WorldEnvironment = get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	return we.environment if we != null else null


func get_water_material() -> ShaderMaterial:
	var water: MeshInstance3D = get_node_or_null(^"River/Water") as MeshInstance3D
	return water.material_override as ShaderMaterial if water != null else null


func total_coins() -> int:
	var count: int = 0
	for child in pickups.get_children():
		if child is Coin:
			count += 1
	return count


func total_critters() -> int:
	var count: int = 0
	for child in pickups.get_children():
		if child is Critter:
			count += 1
	return count


func progress(s: float) -> float:
	return clampf((s - start_distance) / maxf(1.0, finish_distance - start_distance), 0.0, 1.0)


## Keeps the ambient particle box (pollen, leaves, snow) around the camera.
func update_ambient(camera_position: Vector3) -> void:
	if ambient != null:
		ambient.global_position = camera_position + Vector3(0.0, 2.0, 0.0)


func stars_for(coins: int, hits: int) -> int:
	var total: int = maxi(1, total_coins())
	var ratio: float = float(coins) / total
	var stars: int = 1
	if ratio >= coin_star_ratio:
		stars += 1
	if ratio >= coin_three_star_ratio and hits <= 1:
		stars += 1
	return stars
