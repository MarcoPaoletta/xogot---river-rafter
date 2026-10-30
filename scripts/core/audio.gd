extends Node
## Audio service (autoload scene res://scenes/core/audio.tscn).
## Boots with the Master bus MUTED; the toggle_mute action (M) or the HUD speaker button flips it.
## One-shot SFX play through the authored Pool players (no runtime node creation);
## the river ambience keeps playing while muted so unmuting lands mid-loop.

signal mute_changed(muted: bool)

const SFX_PATHS: Dictionary = {
	&"coin": "res://assets/audio/coin.res",
	&"splash": "res://assets/audio/splash.res",
	&"hit": "res://assets/audio/hit.res",
	&"boost": "res://assets/audio/boost.res",
	&"heart": "res://assets/audio/heart.res",
	&"win": "res://assets/audio/win.res",
	&"lose": "res://assets/audio/lose.res",
	&"click": "res://assets/audio/click.res",
	&"beep": "res://assets/audio/beep.res",
	&"go": "res://assets/audio/go.res",
}
const AMBIENCE_PATH: String = "res://assets/audio/river_loop.res"

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _master: int = 0

@onready var _ambience: AudioStreamPlayer = $Ambience
@onready var _pool: Node = $Pool


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_master = AudioServer.get_bus_index(&"Master")
	AudioServer.set_bus_mute(_master, true)
	for key: StringName in SFX_PATHS:
		var path: String = SFX_PATHS[key]
		if ResourceLoader.exists(path):
			_streams[key] = load(path)
	for child in _pool.get_children():
		if child is AudioStreamPlayer:
			_players.append(child as AudioStreamPlayer)
	if ResourceLoader.exists(AMBIENCE_PATH):
		_ambience.stream = (load(AMBIENCE_PATH) as AudioStream).duplicate()
		_ambience.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"toggle_mute"):
		toggle_mute()
		get_viewport().set_input_as_handled()


## True while the Master bus is muted.
func is_muted() -> bool:
	return AudioServer.is_bus_mute(_master)


func toggle_mute() -> void:
	set_muted(not is_muted())


func set_muted(value: bool) -> void:
	AudioServer.set_bus_mute(_master, value)
	mute_changed.emit(value)


## Plays a pooled one-shot. Unknown keys are ignored (defensive).
func play(key: StringName, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not _streams.has(key) or _players.is_empty():
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[key]
	player.pitch_scale = pitch * randf_range(0.97, 1.03)
	player.volume_db = volume_db
	player.play()


## Drives the river bed from the raft speed (0 calm .. 1 rapids).
func set_river_intensity(t: float) -> void:
	var k: float = clampf(t, 0.0, 1.0)
	_ambience.volume_db = lerpf(-16.0, -6.0, k)
	_ambience.pitch_scale = lerpf(0.9, 1.2, k)
