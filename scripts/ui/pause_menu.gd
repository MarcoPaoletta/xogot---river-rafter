class_name PauseMenu
extends CanvasLayer
## Pause overlay (works while the tree is paused): resume, restart, recalibrate tilt,
## invert steering, tilt sensitivity and back to the title.

signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Panel
@onready var resume_button: Button = $Root/Panel/VBox/Resume
@onready var restart_button: Button = $Root/Panel/VBox/Restart
@onready var calibrate_button: Button = $Root/Panel/VBox/Calibrate
@onready var invert_check: CheckButton = $Root/Panel/VBox/InvertSteer
@onready var sensitivity: HSlider = $Root/Panel/VBox/Sensitivity/Slider
@onready var menu_button: Button = $Root/Panel/VBox/Menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	resume_button.pressed.connect(func() -> void: resume_pressed.emit())
	restart_button.pressed.connect(func() -> void: restart_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	calibrate_button.pressed.connect(_on_calibrate)
	invert_check.toggled.connect(GameState.set_invert_steer)
	sensitivity.value_changed.connect(GameState.set_tilt_sensitivity)
	UiJuice.wire(self)


func open() -> void:
	invert_check.set_pressed_no_signal(GameState.invert_steer)
	sensitivity.set_value_no_signal(GameState.tilt_sensitivity)
	UiJuice.fade_in(root, 0.25)
	UiJuice.pop_in(panel, 0.35)
	resume_button.grab_focus.call_deferred()


func close() -> void:
	UiJuice.fade_out(root, 0.2)


func is_open() -> bool:
	return root.visible


func _on_calibrate() -> void:
	Tilt.calibrate()
	calibrate_button.text = "Tilt calibrated!"
	get_tree().create_timer(1.2, true, false, true).timeout.connect(func() -> void: calibrate_button.text = "Recalibrate tilt")
