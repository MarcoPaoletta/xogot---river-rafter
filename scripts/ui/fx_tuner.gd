class_name FxTuner
extends CanvasLayer
## Two-page FX tuner. Opens with a double tap on the top half of the screen (or F2).
## Page 1 "Wake & Foam": the raft zig-zags down the river on the right; sliders on the left tune
##   the wake/foam/spray particles, foam shaders and water streaks live.
## Page 2 "Light & Env": the raft goes straight; sliders tune this level's sun (LevelLook) and
##   Environment; the level buttons switch river.
## Save writes the edited .tres files; Reload discards unsaved changes.

signal opened(page: int)
signal closed
signal page_changed(page: int)
signal level_requested(index: int)

const M: String = "res://assets/materials/"

@export var double_tap_time: float = 0.32
@export var double_tap_distance: float = 90.0

var page: int = 1
var is_open: bool = false

var _defs: Dictionary = {}
var _raft: Raft
var _level: RiverLevel
var _last_tap_time: float = -10.0
var _last_tap_pos: Vector2 = Vector2.ZERO
var _syncing: bool = false
var _saved: Array[Resource] = []

@onready var root: Control = $Root
@onready var panel: PanelContainer = $Root/Panel
@onready var page1_button: Button = $Root/Panel/VBox/Header/Page1
@onready var page2_button: Button = $Root/Panel/VBox/Header/Page2
@onready var close_button: Button = $Root/Panel/VBox/Header/Close
@onready var level_select: HBoxContainer = $Root/Panel/VBox/LevelSelect
@onready var rows1: VBoxContainer = $Root/Panel/VBox/Scroll/Pages/Page1Rows
@onready var rows2: VBoxContainer = $Root/Panel/VBox/Scroll/Pages/Page2Rows
@onready var save_button: Button = $Root/Panel/VBox/Footer/Save
@onready var reset_button: Button = $Root/Panel/VBox/Footer/Reload
@onready var status: Label = $Root/Panel/VBox/Footer/Status


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	page1_button.pressed.connect(func() -> void: show_page(1))
	page2_button.pressed.connect(func() -> void: show_page(2))
	close_button.pressed.connect(close)
	save_button.pressed.connect(_save)
	reset_button.pressed.connect(_reload)
	for i in level_select.get_child_count():
		var b: Button = level_select.get_child(i) as Button
		b.pressed.connect(func() -> void: level_requested.emit(i))
	for rows: VBoxContainer in [rows1, rows2]:
		for row in rows.get_children():
			var slider: HSlider = row.get_node_or_null(^"Slider") as HSlider
			if slider != null:
				slider.value_changed.connect(_on_slider.bind(String(row.name)))
	UiJuice.wire(self)


## Binds the tuner to the live raft and level (called by the director after loading).
func setup(raft: Raft, level: RiverLevel) -> void:
	_raft = raft
	_level = level
	_build_defs()


func open(p: int) -> void:
	is_open = true
	root.visible = true
	UiJuice.fade_in(root, 0.2)
	status.text = "Double tap top half to close"
	show_page(p)
	opened.emit(page)


func close() -> void:
	is_open = false
	UiJuice.fade_out(root, 0.2)
	closed.emit()


func show_page(p: int) -> void:
	page = p
	rows1.visible = p == 1
	rows2.visible = p == 2
	level_select.visible = p == 2
	page1_button.modulate = Color.WHITE if p == 1 else Color(1, 1, 1, 0.55)
	page2_button.modulate = Color.WHITE if p == 2 else Color(1, 1, 1, 0.55)
	_sync_rows()
	page_changed.emit(p)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo and (event as InputEventKey).physical_keycode == KEY_F2:
		_toggle()
		return
	var tap_pos: Vector2 = Vector2(-1, -1)
	if event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed:
		tap_pos = (event as InputEventScreenTouch).position
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).double_click:
		_toggle()
		return
	if tap_pos.x < 0.0:
		return
	var vp: Vector2 = get_viewport().get_visible_rect().size
	if tap_pos.y > vp.y * 0.5:
		return
	if is_open and panel.get_global_rect().has_point(tap_pos):
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_tap_time < double_tap_time and tap_pos.distance_to(_last_tap_pos) < double_tap_distance:
		_last_tap_time = -10.0
		_toggle()
	else:
		_last_tap_time = now
		_last_tap_pos = tap_pos


func _toggle() -> void:
	if is_open:
		close()
	else:
		open(page)


# ---------------------------------------------------------------- parameters

func _def(key: String, getter: Callable, setter: Callable) -> void:
	_defs[key] = {"get": getter, "set": setter}


static func _sp(mat: ShaderMaterial, param: String, fallback: float) -> float:
	var v: Variant = mat.get_shader_parameter(param)
	return float(v) if v != null else fallback


func _build_defs() -> void:
	_defs.clear()
	_saved.clear()
	if _raft == null or _level == null:
		return
	var fx: RaftFx = _raft.fx
	var wake: ParticleProcessMaterial = load(M + "pm_foam_trail.tres")
	var patch: ShaderMaterial = load(M + "foam_patch_mat.tres")
	var hull: ShaderMaterial = load(M + "foam_hull_mat.tres")
	var ring: ShaderMaterial = load(M + "foam_ring_mat.tres")
	var spray: ParticleProcessMaterial = load(M + "pm_spray.tres")
	var water: ShaderMaterial = _level.get_water_material()
	_saved = [fx, wake, patch, hull, ring, spray]
	if water != null:
		_saved.append(water)
	var refx: Callable = func() -> void: _raft.apply_fx()
	_def("wake_on", func() -> float: return 1.0 if fx.wake_enabled else 0.0, func(v: float) -> void:
		fx.wake_enabled = v > 0.5
		refx.call())
	_def("wake_amount", func() -> float: return fx.wake_amount, func(v: float) -> void:
		fx.wake_amount = int(v)
		refx.call())
	_def("wake_lifetime", func() -> float: return fx.wake_lifetime, func(v: float) -> void:
		fx.wake_lifetime = v
		refx.call())
	_def("wake_height", func() -> float: return fx.wake_offset.y, func(v: float) -> void:
		fx.wake_offset.y = v
		refx.call())
	_def("wake_back", func() -> float: return fx.wake_offset.z, func(v: float) -> void:
		fx.wake_offset.z = v
		refx.call())
	_def("wake_width", func() -> float: return wake.emission_box_extents.x, func(v: float) -> void: wake.emission_box_extents.x = v)
	_def("wake_spread", func() -> float: return wake.spread, func(v: float) -> void: wake.spread = v)
	_def("wake_vel_min", func() -> float: return wake.initial_velocity_min, func(v: float) -> void: wake.initial_velocity_min = v)
	_def("wake_vel_max", func() -> float: return wake.initial_velocity_max, func(v: float) -> void: wake.initial_velocity_max = v)
	_def("wake_scale_min", func() -> float: return wake.scale_min, func(v: float) -> void: wake.scale_min = v)
	_def("wake_scale_max", func() -> float: return wake.scale_max, func(v: float) -> void: wake.scale_max = v)
	_def("patch_opacity", func() -> float: return _sp(patch, "opacity", 0.9), func(v: float) -> void: patch.set_shader_parameter("opacity", v))
	_def("patch_breakup", func() -> float: return _sp(patch, "breakup", 0.5), func(v: float) -> void: patch.set_shader_parameter("breakup", v))
	_def("patch_noise", func() -> float: return _sp(patch, "noise_scale", 6.0), func(v: float) -> void: patch.set_shader_parameter("noise_scale", v))
	_def("hull_on", func() -> float: return 1.0 if fx.hull_foam_enabled else 0.0, func(v: float) -> void:
		fx.hull_foam_enabled = v > 0.5
		refx.call())
	_def("hull_scale", func() -> float: return fx.hull_foam_scale, func(v: float) -> void:
		fx.hull_foam_scale = v
		refx.call())
	_def("hull_opacity", func() -> float: return _sp(hull, "opacity", 0.6), func(v: float) -> void: hull.set_shader_parameter("opacity", v))
	_def("hull_inner", func() -> float: return _sp(hull, "ring_inner", 0.7), func(v: float) -> void: hull.set_shader_parameter("ring_inner", v))
	_def("hull_outer", func() -> float: return _sp(hull, "ring_outer", 0.76), func(v: float) -> void: hull.set_shader_parameter("ring_outer", v))
	_def("hull_breakup", func() -> float: return _sp(hull, "breakup", 0.5), func(v: float) -> void: hull.set_shader_parameter("breakup", v))
	_def("spray_amount", func() -> float: return fx.spray_amount, func(v: float) -> void:
		fx.spray_amount = int(v)
		refx.call())
	_def("spray_scale", func() -> float: return spray.scale_max, func(v: float) -> void:
		spray.scale_max = v
		spray.scale_min = v * 0.45)
	_def("rock_foam_opacity", func() -> float: return _sp(ring, "opacity", 0.8), func(v: float) -> void: ring.set_shader_parameter("opacity", v))
	_def("rock_foam_breakup", func() -> float: return _sp(ring, "breakup", 0.47), func(v: float) -> void: ring.set_shader_parameter("breakup", v))
	if water != null:
		_def("water_streaks", func() -> float: return _sp(water, "streak_amount", 0.55), func(v: float) -> void: water.set_shader_parameter("streak_amount", v))
		_def("water_bank_foam", func() -> float: return _sp(water, "bank_foam", 1.3), func(v: float) -> void: water.set_shader_parameter("bank_foam", v))
		_def("water_flow", func() -> float: return _sp(water, "flow_speed", 12.0), func(v: float) -> void: water.set_shader_parameter("flow_speed", v))
		_def("water_waves", func() -> float: return _sp(water, "wave_height", 0.07), func(v: float) -> void: water.set_shader_parameter("wave_height", v))
	# ---- page 2: light and environment of the current level
	var env: Environment = _level.get_environment()
	var look: LevelLook = _level.look
	var sun: DirectionalLight3D = _level.get_node_or_null(^"Sun") as DirectionalLight3D
	if look != null:
		_saved.append(look)
		var relook: Callable = func() -> void: look.apply(sun)
		_def("sun_energy", func() -> float: return look.sun_energy, func(v: float) -> void:
			look.sun_energy = v
			relook.call())
		_def("sun_elevation", func() -> float: return look.sun_elevation, func(v: float) -> void:
			look.sun_elevation = v
			relook.call())
		_def("sun_azimuth", func() -> float: return look.sun_azimuth, func(v: float) -> void:
			look.sun_azimuth = v
			relook.call())
		_def("sun_warmth", func() -> float: return clampf((look.sun_color.r - look.sun_color.b) / 0.55, -1.0, 1.0), func(v: float) -> void:
			var neutral: Color = Color(1.0, 0.97, 0.92)
			look.sun_color = neutral.lerp(Color(1.0, 0.72, 0.45), v) if v >= 0.0 else neutral.lerp(Color(0.72, 0.84, 1.0), -v)
			relook.call())
		_def("sun_shadows", func() -> float: return 1.0 if look.shadows else 0.0, func(v: float) -> void:
			look.shadows = v > 0.5
			relook.call())
	if env != null:
		_saved.append(env)
		_def("ambient_energy", func() -> float: return env.ambient_light_energy, func(v: float) -> void: env.ambient_light_energy = v)
		_def("sky_contribution", func() -> float: return env.ambient_light_sky_contribution, func(v: float) -> void: env.ambient_light_sky_contribution = v)
		_def("exposure", func() -> float: return env.tonemap_exposure, func(v: float) -> void: env.tonemap_exposure = v)
		_def("glow", func() -> float: return env.glow_intensity, func(v: float) -> void: env.glow_intensity = v)
		_def("glow_threshold", func() -> float: return env.glow_hdr_threshold, func(v: float) -> void: env.glow_hdr_threshold = v)
		_def("glow_bloom", func() -> float: return env.glow_bloom, func(v: float) -> void: env.glow_bloom = v)
		_def("fog_density", func() -> float: return env.fog_density, func(v: float) -> void: env.fog_density = v)
		_def("fog_sky", func() -> float: return env.fog_sky_affect, func(v: float) -> void: env.fog_sky_affect = v)
		_def("contrast", func() -> float: return env.adjustment_contrast, func(v: float) -> void: env.adjustment_contrast = v)
		_def("saturation", func() -> float: return env.adjustment_saturation, func(v: float) -> void: env.adjustment_saturation = v)
		_def("brightness", func() -> float: return env.adjustment_brightness, func(v: float) -> void: env.adjustment_brightness = v)
		var sky_mat: ProceduralSkyMaterial = env.sky.sky_material as ProceduralSkyMaterial if env.sky != null else null
		if sky_mat != null:
			_def("sky_energy", func() -> float: return sky_mat.energy_multiplier, func(v: float) -> void: sky_mat.energy_multiplier = v)


func _sync_rows() -> void:
	_syncing = true
	for rows: VBoxContainer in [rows1, rows2]:
		for row in rows.get_children():
			var key: String = String(row.name)
			var slider: HSlider = row.get_node_or_null(^"Slider") as HSlider
			if slider == null:
				continue
			row.visible = _defs.has(key)
			if _defs.has(key):
				slider.value = float((_defs[key]["get"] as Callable).call())
				_show_value(row, slider)
	_syncing = false


func _on_slider(value: float, key: String) -> void:
	if _syncing or not _defs.has(key):
		return
	(_defs[key]["set"] as Callable).call(value)
	for rows: VBoxContainer in [rows1, rows2]:
		var row: Node = rows.get_node_or_null(NodePath(key))
		if row != null:
			_show_value(row, row.get_node(^"Slider") as HSlider)
	status.text = "Unsaved changes"


func _show_value(row: Node, slider: HSlider) -> void:
	var label: Label = row.get_node_or_null(^"Value") as Label
	if label == null:
		return
	if slider.step >= 1.0:
		label.text = str(int(slider.value))
	elif slider.step < 0.01:
		label.text = "%.4f" % slider.value
	else:
		label.text = "%.2f" % slider.value


func _save() -> void:
	var failed: int = 0
	for res in _saved:
		if res != null and res.resource_path != "":
			if ResourceSaver.save(res, res.resource_path) != OK:
				failed += 1
	status.text = "Saved!" if failed == 0 else "Save failed for %d files (exported build?)" % failed
	Audio.play(&"coin", 1.4)


func _reload() -> void:
	for res in _saved:
		if res != null and res.resource_path != "":
			ResourceLoader.load(res.resource_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if _raft != null:
		_raft.apply_fx()
	if _level != null:
		_level.apply_look()
	_sync_rows()
	status.text = "Reloaded from disk"
