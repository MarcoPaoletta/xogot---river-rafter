extends Node
## Durable run state: selected level, unlocks, best stars, tilt settings and debug flags.
## Persisted to user://river_rafter.cfg (settings and progress only).

signal settings_changed

const LEVEL_SCENES: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
]
const LEVEL_NAMES: Array[String] = ["Pine Gorge", "Autumn Bend", "Frozen Rapids"]
const SAVE_PATH: String = "user://river_rafter.cfg"

var current_level: int = 0
var unlocked: int = 1
var best_stars: Array[int] = [0, 0, 0]
var invert_steer: bool = false
var tilt_sensitivity: float = 1.0
## When true the director skips the title and starts the countdown (Retry / Next).
var skip_title: bool = false
var god_mode: bool = false
## When > 0 the director reopens the FX tuner on that page after a reload.
var tuner_page: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()


func level_count() -> int:
	return LEVEL_SCENES.size()


func record_result(level: int, stars: int) -> void:
	if level < 0 or level >= best_stars.size():
		return
	best_stars[level] = maxi(best_stars[level], stars)
	unlocked = clampi(maxi(unlocked, level + 2), 1, LEVEL_SCENES.size())
	save()


func set_invert_steer(value: bool) -> void:
	invert_steer = value
	save()
	settings_changed.emit()


func set_tilt_sensitivity(value: float) -> void:
	tilt_sensitivity = clampf(value, 0.5, 2.0)
	save()
	settings_changed.emit()


func save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best_stars", best_stars)
	cfg.set_value("settings", "invert_steer", invert_steer)
	cfg.set_value("settings", "tilt_sensitivity", tilt_sensitivity)
	cfg.save(SAVE_PATH)


func reset_save() -> void:
	unlocked = 1
	best_stars = [0, 0, 0]
	invert_steer = false
	tilt_sensitivity = 1.0
	current_level = 0
	save()
	settings_changed.emit()


func _load() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, LEVEL_SCENES.size())
	var stars: Array = cfg.get_value("progress", "best_stars", [0, 0, 0])
	for i in mini(stars.size(), best_stars.size()):
		best_stars[i] = int(stars[i])
	invert_steer = bool(cfg.get_value("settings", "invert_steer", false))
	tilt_sensitivity = float(cfg.get_value("settings", "tilt_sensitivity", 1.0))
