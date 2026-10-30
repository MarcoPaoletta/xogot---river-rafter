class_name Hud
extends CanvasLayer
## In-game HUD: hearts, river progress, coin counter, mute and pause buttons, countdown and hints.
## Every change animates (pops, punches, fades); the mood overlay flashes on damage and boosts.

signal pause_pressed
signal paddle_pressed

@onready var root: Control = $Root
@onready var vignette: ColorRect = $Root/Vignette
@onready var hearts_box: HBoxContainer = $Root/TopBar/Row/Hearts
@onready var level_label: Label = $Root/TopBar/Row/Middle/LevelName
@onready var progress: RiverProgress = $Root/TopBar/Row/Middle/Progress
@onready var coin_panel: PanelContainer = $Root/TopBar/Row/CoinPanel
@onready var coin_label: Label = $Root/TopBar/Row/CoinPanel/CoinRow/CoinLabel
@onready var mute_button: Button = $Root/TopBar/Row/MuteButton
@onready var speaker: SpeakerIcon = $Root/TopBar/Row/MuteButton/Speaker
@onready var pause_button: Button = $Root/TopBar/Row/PauseButton
@onready var countdown: Label = $Root/Countdown
@onready var hint: Label = $Root/Hint
@onready var multiplier: Label = $Root/TopBar/Row/CoinPanel/CoinRow/Multiplier
@onready var flow_bar: FlowBar = $Root/FlowBox/FlowBar
@onready var flow_label: Label = $Root/FlowBox/FlowLabel
@onready var paddle_button: Button = $Root/PaddleButton
@onready var stamina_ring: StaminaRing = $Root/PaddleButton/Ring
@onready var callout: Label = $Root/Callout

var _callout_tween: Tween
var _icon_t: float = 0.0
var _icon_swing: float = 0.0

@onready var paddle_pivot: Node3D = get_node_or_null(^"Root/PaddleButton/Icon3D/Viewport/Pivot") as Node3D
var _flow_was_active: bool = false

var _flash_tween: Tween
var _coin_tween: Tween
var _count_tween: Tween
var _hint_tween: Tween


func _ready() -> void:
	root.visible = false
	countdown.visible = false
	hint.modulate.a = 0.0
	mute_button.pressed.connect(Audio.toggle_mute)
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())
	paddle_button.button_down.connect(func() -> void: paddle_pressed.emit())
	callout.visible = false
	multiplier.visible = false
	Audio.mute_changed.connect(_on_mute_changed)
	speaker.muted = Audio.is_muted()
	UiJuice.wire(self)


func show_hud() -> void:
	UiJuice.fade_in(root, 0.4)


func hide_hud() -> void:
	UiJuice.fade_out(root, 0.3)


func set_level_name(value: String) -> void:
	level_label.text = value


func set_hearts(count: int, max_count: int, lost: bool) -> void:
	var icons: Array[Node] = hearts_box.get_children()
	for i in icons.size():
		var h: HeartIcon = icons[i] as HeartIcon
		h.visible = i < max_count
		h.filled = i < count
	if lost:
		if count < icons.size():
			(icons[count] as HeartIcon).pop(0.6)
		flash(Color(0.95, 0.12, 0.18, 1.0), 1.0)
	elif count > 0:
		(icons[count - 1] as HeartIcon).pop(0.4)


func set_coins(count: int, total: int, animate: bool) -> void:
	coin_label.text = "%d / %d" % [count, total]
	if not animate:
		return
	if _coin_tween != null and _coin_tween.is_valid():
		_coin_tween.kill()
	coin_panel.pivot_offset = coin_panel.size * 0.5
	coin_panel.scale = Vector2.ONE * 1.22
	_coin_tween = create_tween()
	_coin_tween.tween_property(coin_panel, ^"scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Score counter with the current coin multiplier badge (crew x FLOW).
func set_score(score: int, mult: int, animate: bool) -> void:
	coin_label.text = str(score)
	multiplier.visible = mult > 1
	multiplier.text = "x%d" % mult
	if animate:
		set_coins(0, 0, true)
		coin_label.text = str(score)


func set_multiplier(mult: int) -> void:
	var was: bool = multiplier.visible
	multiplier.visible = mult > 1
	multiplier.text = "x%d" % mult
	if mult > 1:
		multiplier.pivot_offset = multiplier.size * 0.5
		multiplier.scale = Vector2.ONE * (1.6 if not was else 1.3)
		create_tween().tween_property(multiplier, ^"scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_flow(value: float, active: bool) -> void:
	flow_bar.value = value
	flow_bar.active = active
	flow_label.text = "FLOW x2!" if active else "FLOW"
	if active and not _flow_was_active:
		show_callout("FLOW!", Color(0.5, 1.0, 1.0, 1.0))
		flash(Color(0.4, 0.95, 1.0, 1.0), 0.6)
	_flow_was_active = active


func set_stamina(value: float) -> void:
	stamina_ring.value = value


func _process(delta: float) -> void:
	if paddle_pivot == null or not root.visible:
		return
	_icon_t += delta
	_icon_swing = lerpf(_icon_swing, 0.0, 1.0 - exp(-6.0 * delta))
	paddle_pivot.rotation = Vector3(0.0, sin(_icon_t * 1.3) * 0.5, deg_to_rad(-40.0) + sin(_icon_t * 2.1) * 0.08 + _icon_swing)


func pulse_paddle() -> void:
	_icon_swing = -1.1
	paddle_button.pivot_offset = paddle_button.size * 0.5
	paddle_button.scale = Vector2.ONE * 0.86
	create_tween().tween_property(paddle_button, ^"scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Big banner text (FLOW!, TURBO!, WATERFALL!, CLOSE CALL x3!) that pops and fades.
func show_callout(text: String, color: Color) -> void:
	if _callout_tween != null and _callout_tween.is_valid():
		_callout_tween.kill()
	callout.text = text
	callout.modulate = color
	callout.visible = true
	callout.pivot_offset = callout.size * 0.5
	callout.scale = Vector2.ONE * 1.8
	callout.rotation = -0.06
	_callout_tween = create_tween()
	_callout_tween.tween_property(callout, ^"scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_callout_tween.parallel().tween_property(callout, ^"rotation", 0.0, 0.3)
	_callout_tween.tween_interval(0.6)
	_callout_tween.tween_property(callout, ^"modulate:a", 0.0, 0.35)
	_callout_tween.tween_callback(func() -> void: callout.visible = false)


func set_progress(value: float) -> void:
	progress.value = value


## Big centre text with a pop; "GO!" fades out on its own.
func show_countdown(text: String) -> void:
	if _count_tween != null and _count_tween.is_valid():
		_count_tween.kill()
	countdown.text = text
	countdown.visible = true
	countdown.modulate.a = 1.0
	countdown.pivot_offset = countdown.size * 0.5
	countdown.scale = Vector2.ONE * 2.0
	_count_tween = create_tween()
	_count_tween.tween_property(countdown, ^"scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if text == "GO!":
		_count_tween.tween_interval(0.35)
		_count_tween.tween_property(countdown, ^"modulate:a", 0.0, 0.35)
		_count_tween.tween_callback(func() -> void: countdown.visible = false)


func show_hint(text: String, seconds: float) -> void:
	if _hint_tween != null and _hint_tween.is_valid():
		_hint_tween.kill()
	hint.text = text
	_hint_tween = create_tween()
	_hint_tween.tween_property(hint, ^"modulate:a", 1.0, 0.4)
	_hint_tween.tween_interval(seconds)
	_hint_tween.tween_property(hint, ^"modulate:a", 0.0, 0.6)


## Mood overlay flash: rises fast (0.06 s), falls slow (0.45 s).
func flash(color: Color, strength: float) -> void:
	var mat: ShaderMaterial = vignette.material as ShaderMaterial
	if mat == null:
		return
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	mat.set_shader_parameter(&"tint", color)
	_flash_tween = create_tween()
	_flash_tween.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"intensity", v), 0.0, strength, 0.06)
	_flash_tween.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"intensity", v), strength, 0.0, 0.45)


func _on_mute_changed(muted: bool) -> void:
	speaker.muted = muted
	mute_button.pivot_offset = mute_button.size * 0.5
	mute_button.scale = Vector2.ONE * 1.2
	create_tween().tween_property(mute_button, ^"scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
