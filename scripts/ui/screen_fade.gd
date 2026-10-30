class_name ScreenFade
extends CanvasLayer
## Global fade overlay owned by the director. Pause-safe; blocks input while dark.
## fade_out() / fade_in() return when finished; a newer request cancels the older tween.

@export var duration: float = 0.45

var _tween: Tween

@onready var overlay: ColorRect = $Overlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.visible = true
	overlay.modulate.a = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func fade_out() -> void:
	await _run(1.0)


func fade_in() -> void:
	await _run(0.0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _run(target: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	overlay.visible = true
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(overlay, ^"modulate:a", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished
	if target <= 0.0:
		overlay.visible = false
