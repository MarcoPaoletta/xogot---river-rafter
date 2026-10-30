class_name TitleScreen
extends CanvasLayer
## Title over the live river: game name, three level cards (stars, locks) and mute.

signal level_chosen(index: int)

@onready var root: Control = $Root
@onready var title_label: Label = $Root/Center/Title
@onready var cards: HBoxContainer = $Root/Center/Levels
@onready var mute_button: Button = $Root/MuteButton
@onready var speaker: SpeakerIcon = $Root/MuteButton/Speaker

var _t: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	for i in cards.get_child_count():
		var card: Button = cards.get_child(i) as Button
		card.pressed.connect(_on_card_pressed.bind(i))
	mute_button.pressed.connect(Audio.toggle_mute)
	Audio.mute_changed.connect(func(m: bool) -> void: speaker.muted = m)
	speaker.muted = Audio.is_muted()
	UiJuice.wire(self)


func _process(delta: float) -> void:
	if not root.visible:
		return
	_t += delta
	title_label.pivot_offset = title_label.size * 0.5
	title_label.rotation = sin(_t * 1.3) * 0.02
	title_label.scale = Vector2.ONE * (1.0 + sin(_t * 2.0) * 0.015)


func show_title() -> void:
	_refresh()
	UiJuice.fade_in(root, 0.6)
	var first: Button = cards.get_child(0) as Button
	first.grab_focus.call_deferred()


func hide_title() -> void:
	UiJuice.fade_out(root, 0.35)


func hide_instant() -> void:
	root.visible = false


func _refresh() -> void:
	for i in cards.get_child_count():
		var card: Button = cards.get_child(i) as Button
		var locked: bool = i >= GameState.unlocked
		card.disabled = locked
		card.modulate = Color(1, 1, 1, 0.55) if locked else Color.WHITE
		var stars: StarRow = card.get_node(^"Content/Stars") as StarRow
		stars.filled = GameState.best_stars[i]
		var lock: Label = card.get_node(^"Content/Status") as Label
		lock.text = "LOCKED" if locked else ("Best run" if GameState.best_stars[i] > 0 else "New river")


func _on_card_pressed(index: int) -> void:
	if index >= GameState.unlocked:
		return
	level_chosen.emit(index)
