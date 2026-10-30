class_name ResultScreen
extends CanvasLayer
## End-of-river panel: win (stars pop one by one, stats) or capsized; Next / Retry / Menu.

signal next_pressed
signal retry_pressed
signal menu_pressed

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Panel
@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var stars: StarRow = $Root/Panel/VBox/Stars
@onready var stats: Label = $Root/Panel/VBox/Stats
@onready var next_button: Button = $Root/Panel/VBox/Buttons/Next
@onready var retry_button: Button = $Root/Panel/VBox/Buttons/Retry
@onready var menu_button: Button = $Root/Panel/VBox/Buttons/Menu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	next_button.pressed.connect(func() -> void: next_pressed.emit())
	retry_button.pressed.connect(func() -> void: retry_pressed.emit())
	menu_button.pressed.connect(func() -> void: menu_pressed.emit())
	UiJuice.wire(self)


func show_win(star_count: int, coins: int, total: int, seconds: float, hearts: int, has_next: bool, final_level: bool, extra: Dictionary = {}) -> void:
	title_label.text = "RIVER CONQUERED!" if not final_level else "ALL RIVERS CONQUERED!"
	stats.text = "Score  %d\nCoins  %d / %d    Critters  %d / %d\nClose calls  %d    Time  %.1f s    Hearts  %d" % [int(extra.get("score", 0)), coins, total, int(extra.get("rescued", 0)), int(extra.get("critters", 0)), int(extra.get("near", 0)), seconds, hearts]
	stars.visible = true
	stars.filled = 0
	next_button.visible = has_next
	_open(next_button if has_next else retry_button)
	for i in star_count:
		await get_tree().create_timer(0.45 + i * 0.35, true, false, true).timeout
		stars.filled = i + 1
		stars.pop_star(i)
		Audio.play(&"coin", 1.0 + i * 0.25)


func show_fail(coins: int, total: int, progress: float) -> void:
	title_label.text = "CAPSIZED!"
	stats.text = "You made it %d%% down the river\nCoins  %d / %d" % [int(progress * 100.0), coins, total]
	stars.visible = false
	next_button.visible = false
	_open(retry_button)


func _open(focus: Button) -> void:
	UiJuice.fade_in(root, 0.3)
	UiJuice.pop_in(panel, 0.45)
	focus.grab_focus.call_deferred()
