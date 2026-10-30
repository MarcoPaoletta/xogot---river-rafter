extends Node3D
## Game director (root of scenes/main.tscn). Coordinates the loop
## TITLE -> COUNTDOWN -> PLAYING -> RESULT, plus pause and the FX tuner mode. It does not
## build anything: the level is an authored scene in LevelSlot (level 1 in the editor).

enum Phase { TITLE, COUNTDOWN, PLAYING, RESULT }

@export var countdown_step: float = 0.7
@export var hit_trauma: float = 0.75
@export var bank_trauma: float = 0.3
@export var boost_trauma: float = 0.25
@export var near_miss_trauma: float = 0.18
@export var air_time_scale: float = 0.55

var phase: Phase = Phase.TITLE
var level: RiverLevel
var _total_coins: int = 0
var _hint_shown: bool = false
var _tuning: bool = false

@onready var level_slot: Node3D = $LevelSlot
@onready var raft: Raft = $Raft
@onready var camera_rig: CameraRig = $CameraRig
@onready var hud: Hud = $HUD
@onready var title: TitleScreen = $TitleScreen
@onready var pause_menu: PauseMenu = $PauseMenu
@onready var results: ResultScreen = $ResultScreen
@onready var debug_panel: DebugPanel = $DebugPanel
@onready var tuner: FxTuner = $FxTuner
@onready var fade: ScreenFade = $ScreenFade


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.time_scale = 1.0
	_load_level(GameState.current_level)
	raft.process_mode = Node.PROCESS_MODE_PAUSABLE
	raft.setup(level.river, level.start_distance)
	raft.set_hazards(get_tree().get_nodes_in_group(&"hazard"))
	raft.loop_distance = level.finish_distance - 14.0
	camera_rig.set_target(raft)
	_total_coins = level.total_coins()
	_set_water_glow(0.0)
	hud.set_level_name(level.display_name)
	hud.set_hearts(raft.hearts, raft.max_hearts, false)
	hud.set_score(0, 1, false)
	hud.set_flow(0.0, false)
	hud.set_stamina(1.0)
	tuner.setup(raft, level)
	_connect_signals()
	if GameState.tuner_page > 0:
		var p: int = GameState.tuner_page
		GameState.tuner_page = 0
		title.hide_instant()
		camera_rig.set_mode(CameraRig.Mode.FOLLOW, true)
		fade.fade_in()
		_begin_play()
		tuner.open(p)
	elif GameState.skip_title:
		GameState.skip_title = false
		title.hide_instant()
		camera_rig.set_mode(CameraRig.Mode.FOLLOW, true)
		fade.fade_in()
		_start_countdown()
	else:
		phase = Phase.TITLE
		camera_rig.set_mode(CameraRig.Mode.MENU, true)
		title.show_title()
		fade.fade_in()


func _connect_signals() -> void:
	raft.score_changed.connect(func(score: int, _gained: int, _pos: Vector3) -> void:
		hud.set_score(score, raft.coin_multiplier(), true))
	raft.hearts_changed.connect(func(h: int, m: int) -> void: hud.set_hearts(h, m, false))
	raft.hit_taken.connect(_on_hit)
	raft.bank_bumped.connect(func() -> void: camera_rig.add_trauma(bank_trauma))
	raft.boosted.connect(_on_boost)
	raft.turbo_started.connect(_on_turbo)
	raft.paddled.connect(func() -> void:
		hud.pulse_paddle()
		camera_rig.add_trauma(0.12))
	raft.stamina_changed.connect(hud.set_stamina)
	raft.flow_changed.connect(_on_flow)
	raft.near_miss.connect(_on_near_miss)
	raft.crew_changed.connect(func(_n: int) -> void: hud.set_multiplier(raft.coin_multiplier()))
	raft.airborne_started.connect(_on_airborne)
	raft.landed.connect(_on_landed)
	raft.finished.connect(_on_finished)
	raft.capsized.connect(_on_capsized)
	title.level_chosen.connect(_on_level_chosen)
	hud.pause_pressed.connect(_pause)
	hud.paddle_pressed.connect(_paddle)
	Tilt.shaken.connect(_paddle)
	pause_menu.resume_pressed.connect(_resume)
	pause_menu.restart_pressed.connect(func() -> void: _reload(true))
	pause_menu.menu_pressed.connect(func() -> void: _reload(false))
	results.next_pressed.connect(_on_next)
	results.retry_pressed.connect(func() -> void: _reload(true))
	results.menu_pressed.connect(func() -> void: _reload(false))
	debug_panel.add_coins_requested.connect(func(n: int) -> void: raft.debug_add_coins(n))
	debug_panel.finish_requested.connect(_debug_finish)
	debug_panel.skip_level_requested.connect(_on_next)
	debug_panel.erase_save_requested.connect(func() -> void:
		GameState.reset_save()
		_reload(false))
	tuner.opened.connect(_on_tuner_opened)
	tuner.page_changed.connect(_on_tuner_page)
	tuner.closed.connect(_on_tuner_closed)
	tuner.level_requested.connect(func(i: int) -> void:
		GameState.current_level = i
		GameState.unlocked = maxi(GameState.unlocked, i + 1)
		GameState.tuner_page = 2
		_reload_scene())


func _load_level(index: int) -> void:
	var wanted: String = GameState.LEVEL_SCENES[clampi(index, 0, GameState.level_count() - 1)]
	var existing: RiverLevel = null
	if level_slot.get_child_count() > 0:
		existing = level_slot.get_child(0) as RiverLevel
	if existing != null and existing.scene_file_path == wanted:
		level = existing
		return
	if existing != null:
		level_slot.remove_child(existing)
		existing.free()
	var packed: PackedScene = load(wanted) as PackedScene
	level = packed.instantiate() as RiverLevel
	level_slot.add_child(level)


func _process(_delta: float) -> void:
	if level == null:
		return
	level.update_ambient(camera_rig.global_position)
	if phase == Phase.PLAYING:
		hud.set_progress(level.progress(raft.s))
		Audio.set_river_intensity(raft.speed_ratio())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if pause_menu.is_open():
			_resume()
		else:
			_pause()
	elif event.is_action_pressed(&"calibrate"):
		Tilt.calibrate()
	elif event.is_action_pressed(&"paddle"):
		_paddle()


func _on_level_chosen(index: int) -> void:
	Audio.play(&"click")
	if index == GameState.current_level:
		title.hide_title()
		camera_rig.set_mode(CameraRig.Mode.FOLLOW)
		_start_countdown()
	else:
		GameState.current_level = index
		GameState.skip_title = true
		_reload_scene()


func _start_countdown() -> void:
	phase = Phase.COUNTDOWN
	hud.show_hud()
	await get_tree().create_timer(0.6).timeout
	for n: String in ["3", "2", "1"]:
		hud.show_countdown(n)
		Audio.play(&"beep")
		await get_tree().create_timer(countdown_step).timeout
	if _tuning:
		return
	hud.show_countdown("GO!")
	Audio.play(&"go")
	Tilt.calibrate()
	_begin_play()
	if not _hint_shown:
		_hint_shown = true
		var text: String = "Tilt to steer  -  tilt back to slow  -  shake or tap PADDLE" if Tilt.has_sensor else "A / D to steer  -  S to slow  -  SPACE to paddle"
		hud.show_hint(text, 3.0)


func _begin_play() -> void:
	if raft.state == Raft.State.IDLE:
		raft.start_rafting()
	phase = Phase.PLAYING


func _paddle() -> void:
	if phase == Phase.PLAYING and not get_tree().paused:
		raft.paddle()


func _on_hit(hearts_left: int) -> void:
	camera_rig.add_trauma(hit_trauma)
	hud.set_hearts(hearts_left, raft.max_hearts, true)
	hud.set_multiplier(raft.coin_multiplier())
	_hitstop()


## Brief slow-motion so the impact reads (world only; tweens and UI keep running).
func _hitstop() -> void:
	Engine.time_scale = 0.25
	await get_tree().create_timer(0.09, true, false, true).timeout
	Engine.time_scale = air_time_scale if raft.airborne else 1.0


func _on_boost() -> void:
	camera_rig.add_trauma(boost_trauma)
	hud.flash(Color(0.45, 0.95, 1.0, 1.0), 0.55)


func _on_turbo() -> void:
	camera_rig.add_trauma(0.4)
	hud.flash(Color(0.35, 0.75, 1.0, 1.0), 0.8)
	hud.show_callout("TURBO!", Color(0.5, 0.85, 1.0, 1.0))


func _on_flow(value: float, active: bool) -> void:
	hud.set_flow(value, active)
	hud.set_multiplier(raft.coin_multiplier())
	_set_water_glow(1.0 if active else 0.0)


func _set_water_glow(target: float) -> void:
	var mat: ShaderMaterial = level.get_water_material() if level != null else null
	if mat == null:
		return
	var current: float = float(mat.get_shader_parameter(&"flow_glow")) if mat.get_shader_parameter(&"flow_glow") != null else 0.0
	if is_equal_approx(current, target):
		return
	var tw: Tween = create_tween()
	tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"flow_glow", v), current, target, 0.5)


func _on_near_miss(_pos: Vector3, streak: int) -> void:
	camera_rig.add_trauma(near_miss_trauma)
	if streak >= 2:
		hud.show_callout("CLOSE CALL x%d!" % streak, Color(0.55, 0.97, 1.0, 1.0))


func _on_airborne() -> void:
	if _tuning:
		return
	Engine.time_scale = air_time_scale
	hud.show_callout("WATERFALL!", Color(1.0, 0.92, 0.5, 1.0))


func _on_landed(impact: float) -> void:
	Engine.time_scale = 1.0
	camera_rig.add_trauma(clampf(impact * 0.07, 0.3, 0.9))
	hud.flash(Color(0.85, 0.97, 1.0, 1.0), 0.45)


func _on_finished() -> void:
	if _tuning:
		return
	phase = Phase.RESULT
	Engine.time_scale = 1.0
	Audio.play(&"win")
	camera_rig.add_trauma(0.3)
	hud.set_progress(1.0)
	var stars: int = level.stars_for(raft.coins, raft.hits_taken)
	GameState.record_result(GameState.current_level, stars)
	await get_tree().create_timer(1.1).timeout
	camera_rig.set_mode(CameraRig.Mode.CELEBRATE)
	hud.hide_hud()
	var last: bool = GameState.current_level >= GameState.level_count() - 1
	var extra: Dictionary = {"score": raft.score, "rescued": raft.rescued_total, "critters": level.total_critters(), "near": raft.near_misses}
	results.show_win(stars, raft.coins, _total_coins, raft.elapsed, raft.hearts, not last, last, extra)


func _on_capsized() -> void:
	phase = Phase.RESULT
	Engine.time_scale = 1.0
	Audio.play(&"lose")
	await get_tree().create_timer(1.4).timeout
	hud.hide_hud()
	results.show_fail(raft.coins, _total_coins, level.progress(raft.s))


func _on_tuner_opened(page: int) -> void:
	_tuning = true
	Engine.time_scale = 1.0
	if phase == Phase.TITLE:
		title.hide_title()
	camera_rig.set_mode(CameraRig.Mode.FOLLOW)
	camera_rig.view_shift = 1.0
	hud.hide_hud()
	if phase != Phase.PLAYING:
		_begin_play()
	_on_tuner_page(page)


func _on_tuner_page(page: int) -> void:
	raft.autopilot = Raft.Autopilot.ZIGZAG if page == 1 else Raft.Autopilot.STRAIGHT


func _on_tuner_closed() -> void:
	_tuning = false
	raft.autopilot = Raft.Autopilot.OFF
	camera_rig.view_shift = 0.0
	if phase == Phase.PLAYING:
		hud.show_hud()


func _pause() -> void:
	if (phase != Phase.PLAYING and phase != Phase.COUNTDOWN) or _tuning:
		return
	get_tree().paused = true
	pause_menu.open()


func _resume() -> void:
	pause_menu.close()
	get_tree().paused = false


func _on_next() -> void:
	GameState.current_level = mini(GameState.current_level + 1, GameState.level_count() - 1)
	GameState.unlocked = maxi(GameState.unlocked, GameState.current_level + 1)
	GameState.skip_title = true
	_reload_scene()


func _debug_finish() -> void:
	if phase == Phase.PLAYING:
		raft.debug_jump_to(level.finish_distance - 12.0)


func _reload(skip_title: bool) -> void:
	GameState.skip_title = skip_title
	_reload_scene()


func _reload_scene() -> void:
	await fade.fade_out()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
