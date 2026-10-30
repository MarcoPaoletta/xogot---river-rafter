class_name UiJuice
extends RefCounted
## Shared UI feel: every Button under a root scales on hover (1.06) and press (0.94),
## plays a click, and grows its pivot from the centre.

static func wire(root: Node) -> void:
	for node in root.find_children("*", "BaseButton", true, false):
		var button: BaseButton = node as BaseButton
		if button.has_meta(&"juiced"):
			continue
		button.set_meta(&"juiced", true)
		button.resized.connect(func() -> void: button.pivot_offset = button.size * 0.5)
		button.pivot_offset = button.size * 0.5
		button.mouse_entered.connect(func() -> void: _tween_scale(button, 1.06, 0.15))
		button.mouse_exited.connect(func() -> void: _tween_scale(button, 1.0, 0.15))
		button.focus_entered.connect(func() -> void: _tween_scale(button, 1.06, 0.15))
		button.focus_exited.connect(func() -> void: _tween_scale(button, 1.0, 0.15))
		button.button_down.connect(func() -> void: _tween_scale(button, 0.94, 0.08))
		button.button_up.connect(func() -> void: _tween_scale(button, 1.0, 0.25))
		button.pressed.connect(func() -> void: Audio.play(&"click"))


static func _tween_scale(control: Control, target: float, time: float) -> void:
	if not control.is_inside_tree():
		return
	var tw: Tween = control.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(control, ^"scale", Vector2.ONE * target, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Fades a CanvasItem in (with a slight rise) and shows it.
static func fade_in(item: Control, time: float = 0.35) -> void:
	item.visible = true
	item.modulate.a = 0.0
	var tw: Tween = item.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(item, ^"modulate:a", 1.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


static func fade_out(item: Control, time: float = 0.3) -> void:
	var tw: Tween = item.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(item, ^"modulate:a", 0.0, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void: item.visible = false)


## Pops a panel in from 0.85 scale with a back ease.
static func pop_in(item: Control, time: float = 0.4) -> void:
	item.pivot_offset = item.size * 0.5
	item.scale = Vector2.ONE * 0.85
	fade_in(item, time * 0.7)
	var tw: Tween = item.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(item, ^"scale", Vector2.ONE, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
