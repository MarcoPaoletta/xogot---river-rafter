@tool
extends RefCounted
## Offline audio baker for River Rafter.
## Run once from the editor. It writes AudioStreamWAV resources (.res) into
## res://assets/audio/. The game only loads the baked files; nothing is synthesized at runtime.

const RATE: int = 22050
const OUT_DIR: String = "res://assets/audio"

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func run() -> void:
	_rng.seed = 7
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save("river_loop", _river_loop(6.0), true)
	_save("splash", _splash(0.7, 1.0), false)
	_save("hit", _hit(), false)
	_save("coin", _coin(), false)
	_save("heart", _arpeggio([660.0, 880.0, 1175.0], 0.09, 0.35, 0.55), false)
	_save("boost", _boost(), false)
	_save("win", _arpeggio([523.25, 659.25, 783.99, 1046.5, 1318.5], 0.12, 0.7, 0.5), false)
	_save("lose", _arpeggio([392.0, 329.63, 261.63, 196.0], 0.2, 0.8, 0.45), false)
	_save("click", _click(), false)
	_save("beep", _beep(880.0, 0.18), false)
	_save("go", _beep(1320.0, 0.4), false)
	print("make_audio: done")


func _save(file_name: String, data: PackedFloat32Array, loop: bool) -> void:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		bytes.encode_s16(i * 2, int(clampf(data[i], -1.0, 1.0) * 32000.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = data.size()
	var err: Error = ResourceSaver.save(wav, "%s/%s.res" % [OUT_DIR, file_name])
	print("make_audio: ", file_name, " samples=", data.size(), " err=", err)


func _noise() -> float:
	return _rng.randf_range(-1.0, 1.0)


## Rushing water bed: low rumble plus airy hiss, crossfaded so the loop seam is inaudible.
func _river_loop(seconds: float) -> PackedFloat32Array:
	var n: int = int(seconds * RATE)
	var fade: int = int(0.5 * RATE)
	var raw: PackedFloat32Array = PackedFloat32Array()
	raw.resize(n + fade)
	var lp1: float = 0.0
	var lp2: float = 0.0
	var hp_prev: float = 0.0
	var hp_out: float = 0.0
	for i in n + fade:
		var w: float = _noise()
		lp1 += (w - lp1) * 0.06
		lp2 += (lp1 - lp2) * 0.08
		hp_out = 0.85 * (hp_out + w - hp_prev)
		hp_prev = w
		var t: float = float(i) / RATE
		var swell: float = 0.75 + 0.25 * sin(TAU * t / seconds * 2.0) * sin(TAU * t / seconds * 3.0 + 1.0)
		raw[i] = (lp2 * 2.6 + hp_out * 0.05) * swell
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i in n:
		if i < fade:
			var k: float = float(i) / fade
			out[i] = raw[i] * k + raw[n + i] * (1.0 - k)
		else:
			out[i] = raw[i]
	return _normalize(out, 0.55)


func _splash(seconds: float, gain: float) -> PackedFloat32Array:
	var n: int = int(seconds * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	for i in n:
		var t: float = float(i) / n
		var cutoff: float = lerpf(0.55, 0.04, t)
		lp += (_noise() - lp) * cutoff
		var env: float = minf(1.0, t * 60.0) * exp(-t * 5.5)
		var bubble: float = sin(TAU * (380.0 - 220.0 * t) * float(i) / RATE) * 0.25 * exp(-t * 9.0)
		out[i] = (lp * 1.4 + bubble) * env * gain
	return _normalize(out, 0.8)


func _hit() -> PackedFloat32Array:
	var n: int = int(0.55 * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	var lp: float = 0.0
	for i in n:
		var t: float = float(i) / RATE
		var freq: float = lerpf(120.0, 42.0, minf(1.0, t / 0.3))
		phase += TAU * freq / RATE
		var thump: float = sin(phase) * exp(-t * 9.0)
		lp += (_noise() - lp) * 0.3
		var crack: float = lp * exp(-t * 30.0) * 0.9
		var rubber: float = sin(TAU * 210.0 * t + sin(TAU * 18.0 * t) * 2.0) * exp(-t * 12.0) * 0.35
		out[i] = thump + crack + rubber
	return _normalize(out, 0.9)


func _coin() -> PackedFloat32Array:
	var n: int = int(0.4 * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var f: float = 1318.5 if t < 0.07 else 1760.0
		var local_t: float = t if t < 0.07 else t - 0.07
		var env: float = minf(1.0, local_t * 400.0) * exp(-local_t * 11.0)
		var tone: float = sin(TAU * f * t) + 0.35 * sin(TAU * f * 2.0 * t) + 0.15 * sin(TAU * f * 3.0 * t)
		out[i] = tone * env
	return _normalize(out, 0.6)


func _arpeggio(notes: Array, step: float, tail: float, level: float) -> PackedFloat32Array:
	var total: float = step * notes.size() + tail
	var n: int = int(total * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for k in notes.size():
		var f: float = notes[k]
		var start: int = int(k * step * RATE)
		for i in range(start, n):
			var t: float = float(i - start) / RATE
			var env: float = minf(1.0, t * 300.0) * exp(-t * 4.5)
			var tri: float = 2.0 * absf(2.0 * fposmod(f * t, 1.0) - 1.0) - 1.0
			out[i] += (tri * 0.6 + sin(TAU * f * t) * 0.4) * env
	return _normalize(out, level)


func _boost() -> PackedFloat32Array:
	var n: int = int(0.9 * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	var bp_low: float = 0.0
	var bp_high: float = 0.0
	var phase: float = 0.0
	for i in n:
		var t: float = float(i) / n
		var c: float = lerpf(0.05, 0.35, t)
		var w: float = _noise()
		bp_low += (w - bp_low) * c
		bp_high += (bp_low - bp_high) * c * 0.5
		var band: float = bp_low - bp_high
		phase += TAU * lerpf(180.0, 720.0, t * t) / RATE
		var env: float = sin(PI * t) * (1.0 - t * 0.4)
		out[i] = (band * 2.0 + sin(phase) * 0.25) * env
	return _normalize(out, 0.7)


func _click() -> PackedFloat32Array:
	var n: int = int(0.09 * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		out[i] = (sin(TAU * 1800.0 * t) * 0.7 + _noise() * 0.3) * exp(-t * 70.0)
	return _normalize(out, 0.5)


func _beep(freq: float, seconds: float) -> PackedFloat32Array:
	var n: int = int(seconds * RATE)
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = float(i) / RATE
		var env: float = minf(1.0, t * 200.0) * exp(-t * 7.0)
		out[i] = (sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.0 * t)) * env
	return _normalize(out, 0.55)


func _normalize(data: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var m: float = 0.0001
	for v in data:
		m = maxf(m, absf(v))
	for i in data.size():
		data[i] = data[i] / m * peak
	return data
