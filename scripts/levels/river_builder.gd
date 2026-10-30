@tool
class_name RiverBuilder
extends Node3D
## Builds the river water ribbon and the valley terrain mesh from the RiverPath curve.
## Supports fork zones (the river widens around a central island) and waterfall drops
## (the water height falls over drop_length metres). Nodes are authored in the level scene;
## only mesh DATA is generated (editor preview + runtime) and cleared before every save.
## half_width_at / island_at / water_height_at / ground_height are the single source of
## truth for geometry: the raft, hazards and the level-placement tool all use them.

@export var half_width: float = 9.0
@export var bank_width: float = 48.0
@export var step: float = 2.0
@export var bank_rise: float = 0.28
@export var cliff_rise: float = 0.55
@export var max_height: float = 14.0
@export_group("Forks and drops")
## Each fork: x = start distance, y = end distance, z = extra half width.
@export var forks: PackedVector3Array = PackedVector3Array()
## Each drop: x = distance of the lip, y = height lost.
@export var drops: PackedVector2Array = PackedVector2Array()
@export var fork_ramp: float = 26.0
@export var drop_length: float = 5.0
@export_group("Colors")
@export var bed_color: Color = Color("3d5a52")
@export var sand_color: Color = Color("c9b98a")
@export var grass_color: Color = Color("6fa04a")
@export var grass_dark_color: Color = Color("4f8a3c")
@export var rock_color: Color = Color("8a8f8c")
@export var peak_color: Color = Color("9aa39a")
@export var peak_height: float = 9.0
@export_tool_button("Rebuild", "Reload") var rebuild_action: Callable = build

const BED_DEPTH: float = -1.6
const SHORE_HEIGHT: float = 0.35
const ISLAND_GAP: float = 4.5


func _ready() -> void:
	build()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		_clear()
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		build()


## Extra half width from fork zones at distance s (smooth ramps at both ends).
func fork_widen_at(s: float) -> float:
	var w: float = 0.0
	for f in forks:
		var ramp: float = smoothstep(f.x, f.x + fork_ramp, s) * (1.0 - smoothstep(f.y - fork_ramp, f.y, s))
		w = maxf(w, f.z * ramp)
	return w


func half_width_at(s: float) -> float:
	return half_width + fork_widen_at(s)


## Half width of the fork island at s (0 when there is no island).
func island_at(s: float) -> float:
	return maxf(0.0, fork_widen_at(s) - ISLAND_GAP + 1.5) if fork_widen_at(s) > ISLAND_GAP else 0.0


## Water surface offset at s from waterfall drops (negative = lower).
func water_height_at(s: float) -> float:
	var h: float = 0.0
	for d in drops:
		var t: float = clampf((s - d.x) / drop_length, 0.0, 1.0)
		h -= d.y * (t * t * (3.0 - 2.0 * t))
	return h


## Steepness 0..1 of the water at s (1 on a waterfall face).
func water_steepness_at(s: float) -> float:
	var a: float = water_height_at(s - 0.5)
	var b: float = water_height_at(s + 0.5)
	return clampf((a - b) * 0.8, 0.0, 1.0)


static func shore_profile(x: float) -> float:
	if x <= -1.5:
		return BED_DEPTH
	if x <= 0.5:
		var t: float = (x + 1.5) / 2.0
		return lerpf(BED_DEPTH, SHORE_HEIGHT, smoothstep(0.0, 1.0, t))
	return SHORE_HEIGHT


## Ground height (relative to the local water datum) at lateral distance a from the centre.
func ground_height(a: float, s: float, side: float) -> float:
	var hw: float = half_width_at(s)
	var h: float = shore_profile(a - hw)
	if a > hw + 0.5:
		var d: float = a - (hw + 0.5)
		h = SHORE_HEIGHT + minf(d, 6.0) * bank_rise + maxf(d - 6.0, 0.0) * cliff_rise
		h += (0.9 * sin(s * 0.045 + side * 1.7) + 0.5 * sin(s * 0.13 + side * 4.1 + d * 0.21)) * clampf(d / 10.0, 0.0, 1.0)
		h = minf(h, max_height)
	var island: float = island_at(s)
	if island > 0.01:
		var x: float = island - a
		var hi: float = shore_profile(x)
		if x > 0.5:
			hi = SHORE_HEIGHT + minf((x - 0.5) * 0.3, 1.6)
		h = maxf(h, hi)
	return h


func get_path_node() -> Path3D:
	return get_node_or_null(^"RiverPath") as Path3D


func get_length() -> float:
	var p: Path3D = get_path_node()
	if p == null or p.curve == null:
		return 0.0
	return p.curve.get_baked_length()


## Distance along the river closest to a global position.
func distance_of(global_pos: Vector3) -> float:
	var p: Path3D = get_path_node()
	if p == null or p.curve == null:
		return 0.0
	return p.curve.get_closest_offset(p.to_local(global_pos))


## Global transform of the river frame at distance s (basis -Z = downstream, X = right).
## The origin sits on the water surface, including waterfall drops.
func sample_frame(s: float) -> Transform3D:
	var p: Path3D = get_path_node()
	if p == null or p.curve == null or p.curve.point_count < 2:
		return global_transform
	var local: Transform3D = p.curve.sample_baked_with_rotation(clampf(s, 0.0, p.curve.get_baked_length()), true, false)
	var xf: Transform3D = p.global_transform * local
	var fwd: Vector3 = -xf.basis.z
	fwd.y = 0.0
	if fwd.length_squared() < 0.0001:
		fwd = Vector3.FORWARD
	fwd = fwd.normalized()
	var right: Vector3 = fwd.cross(Vector3.UP).normalized()
	return Transform3D(Basis(right, Vector3.UP, -fwd), xf.origin + Vector3.UP * water_height_at(s))


func build() -> void:
	var p: Path3D = get_path_node()
	var terrain: MeshInstance3D = get_node_or_null(^"Terrain") as MeshInstance3D
	var water: MeshInstance3D = get_node_or_null(^"Water") as MeshInstance3D
	if p == null or p.curve == null or p.curve.point_count < 2 or terrain == null or water == null:
		return
	var length: float = p.curve.get_baked_length()
	var dists: PackedFloat32Array = _sample_distances(length)
	var frames: Array[Transform3D] = []
	var inv: Transform3D = global_transform.affine_inverse()
	for s in dists:
		frames.append(inv * sample_frame(s))
	terrain.mesh = _build_terrain(frames, dists)
	water.mesh = _build_water(frames, dists)


func _sample_distances(length: float) -> PackedFloat32Array:
	var out: Array[float] = []
	var s: float = 0.0
	while s < length:
		out.append(s)
		var fine: bool = false
		for d in drops:
			if s > d.x - 2.0 and s < d.x + drop_length + 2.0:
				fine = true
		s += 0.5 if fine else step
	out.append(length)
	return PackedFloat32Array(out)


func _clear() -> void:
	var terrain: MeshInstance3D = get_node_or_null(^"Terrain") as MeshInstance3D
	var water: MeshInstance3D = get_node_or_null(^"Water") as MeshInstance3D
	if terrain != null:
		terrain.mesh = null
	if water != null:
		water.mesh = null


## Lateral sample offsets for one cross-section (same count on every row).
func _lateral_samples(s: float) -> PackedFloat32Array:
	var hw: float = half_width_at(s)
	var isl: float = island_at(s)
	var channel: float = maxf(isl + 1.7, (isl + hw) * 0.5)
	var offsets: Array[float] = [0.0, isl * 0.45, maxf(isl - 0.6, 0.0), isl + 0.5, isl + 1.6]
	offsets.append_array([channel, hw - 1.5, hw - 0.6, hw + 0.5, hw + 1.6, hw + 3.2, hw + 5.5, hw + 8.5, hw + 12.5, hw + 17.5, hw + 24.0, hw + 32.0, hw + bank_width])
	for i in range(1, offsets.size()):
		offsets[i] = maxf(offsets[i], offsets[i - 1])
	var out: PackedFloat32Array = PackedFloat32Array()
	for i in range(offsets.size() - 1, 0, -1):
		out.append(-offsets[i])
	for o in offsets:
		out.append(o)
	return out


func _ground_color(a: float, h: float, s: float, side: float) -> Color:
	var hw: float = half_width_at(s)
	var isl: float = island_at(s)
	var d: float = a - (hw + 0.5)
	var on_island: bool = isl > 0.01 and a < isl + 0.5
	if not on_island and a < hw - 0.8 and a > isl + 0.8:
		return bed_color
	if on_island:
		return sand_color if a > isl - 1.8 else grass_color.lerp(grass_dark_color, 0.3)
	if d < 2.2:
		return sand_color
	var n: float = 0.5 + 0.5 * sin(s * 0.21 + side * 2.3 + a * 0.37) * cos(s * 0.07 + a * 0.11)
	var c: Color = grass_color.lerp(grass_dark_color, n)
	var rocky: float = clampf((h - peak_height * 0.55) / (peak_height * 0.45), 0.0, 1.0)
	c = c.lerp(rock_color, rocky)
	if h > peak_height:
		c = c.lerp(peak_color, clampf((h - peak_height) / 3.0, 0.0, 1.0))
	return c


func _build_terrain(frames: Array[Transform3D], dists: PackedFloat32Array) -> ArrayMesh:
	var rows: Array[PackedVector3Array] = []
	var cols: Array[PackedColorArray] = []
	for i in frames.size():
		var f: Transform3D = frames[i]
		var lat: PackedFloat32Array = _lateral_samples(dists[i])
		var row: PackedVector3Array = PackedVector3Array()
		var crow: PackedColorArray = PackedColorArray()
		for l in lat:
			var side: float = signf(l) if l != 0.0 else 1.0
			var a: float = absf(l)
			var h: float = ground_height(a, dists[i], side)
			row.append(f.origin + f.basis.x * l + Vector3.UP * h)
			crow.append(_ground_color(a, h, dists[i], side))
		rows.append(row)
		cols.append(crow)
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	for i in rows.size() - 1:
		for j in rows[i].size() - 1:
			var a0: Vector3 = rows[i][j]
			var a1: Vector3 = rows[i][j + 1]
			var b0: Vector3 = rows[i + 1][j]
			var b1: Vector3 = rows[i + 1][j + 1]
			var c: Color = cols[i][j].lerp(cols[i + 1][j + 1], 0.5)
			_tri(st, a0, b0, a1, c)
			_tri(st, a1, b0, b1, c.darkened(0.04))
	st.generate_normals()
	return st.commit()


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	st.add_vertex(a)
	st.set_color(color)
	st.add_vertex(b)
	st.set_color(color)
	st.add_vertex(c)


## Water ribbon. UV.x = 0..1 across, UV.y = metres downstream, UV2 = (half width, island
## half width) for the shader's bank and island foam, COLOR.g = waterfall steepness.
func _build_water(frames: Array[Transform3D], dists: PackedFloat32Array) -> ArrayMesh:
	var margin: float = 1.2
	var segments: int = 12
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in frames.size():
		var f: Transform3D = frames[i]
		var hw: float = half_width_at(dists[i])
		var isl: float = island_at(dists[i])
		var steep: float = water_steepness_at(dists[i])
		var width: float = hw * 2.0 + margin * 2.0
		for j in segments + 1:
			var u: float = float(j) / segments
			var l: float = -hw - margin + u * width
			st.set_uv(Vector2(u, dists[i]))
			st.set_uv2(Vector2(hw, isl))
			st.set_color(Color(0.0, steep, 0.0, 1.0))
			st.set_normal(Vector3.UP)
			st.add_vertex(f.origin + f.basis.x * l)
	var stride: int = segments + 1
	for i in frames.size() - 1:
		for j in segments:
			var k: int = i * stride + j
			st.add_index(k)
			st.add_index(k + stride)
			st.add_index(k + 1)
			st.add_index(k + 1)
			st.add_index(k + stride)
			st.add_index(k + stride + 1)
	return st.commit()
