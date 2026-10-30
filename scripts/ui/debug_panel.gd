class_name DebugPanel
extends CanvasLayer
## F1 (or a three-finger tap) debug panel for recording: coins, finish/skip, god mode,
## time scale and erase save. Every action goes through the normal game feedback.

signal add_coins_requested(amount: int)
signal finish_requested
signal skip_level_requested
signal erase_save_requested

@onready var root: Control = $Root
@onready var add_coins: Button = $Root/VBox/AddCoins
@onready var finish: Button = $Root/VBox/Finish
@onready var skip: Button = $Root/VBox/SkipLevel
@onready var god: CheckButton = $Root/VBox/GodMode
@onready var speed_box: HBoxContainer = $Root/VBox/Speed
@onready var erase: Button = $Root/VBox/EraseSave
@onready var close_button: Button = $Root/VBox/Close

var _fingers: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	add_coins.pressed.connect(func() -> void: add_coins_requested.emit(10))
	finish.pressed.connect(func() -> void: finish_requested.emit())
	skip.pressed.connect(func() -> void: skip_level_requested.emit())
	erase.pressed.connect(func() -> void: erase_save_requested.emit())
	close_button.pressed.connect(toggle)
	god.toggled.connect(func(on: bool) -> void: GameState.god_mode = on)
	for child in speed_box.get_children():
		var b: Button = child as Button
		var factor: float = float(b.text.trim_suffix("x"))
		b.pressed.connect(func() -> void: Engine.time_scale = factor)
	UiJuice.wire(self)


func toggle() -> void:
	if root.visible:
		UiJuice.fade_out(root, 0.15)
	else:
		god.set_pressed_no_signal(GameState.god_mode)
		UiJuice.fade_in(root, 0.2)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"debug_panel"):
		toggle()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed:
			_fingers[touch.index] = true
			if _fingers.size() >= 3:
				_fingers.clear()
				toggle()
		else:
			_fingers.erase(touch.index)
