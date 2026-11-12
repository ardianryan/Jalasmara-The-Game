extends RefCounted

const ANCHOR := Vector2(3820, 3140)
const IMAGE := "res://resources/art/gajah-mina-motion-v1/swim.png"
const CELL := Vector2(192, 128)
var position := ANCHOR
var elapsed := 0.0
var attack_clock := 0.0
var attack_event := false
var telegraph := false
var phase := 0
var _session := ""
var _frames: Array[Texture2D] = []
var _transition_from := ANCHOR
var _transition_left := 0.0

func frame() -> Texture2D:
	if _frames.is_empty():
		var atlas: Texture2D = load(IMAGE)
		if atlas == null: return null
		for index in range(8):
			var cell := AtlasTexture.new()
			cell.atlas = atlas
			cell.region = Rect2(index * CELL.x, 0, CELL.x, CELL.y)
			cell.filter_clip = true
			_frames.append(cell)
	var index := 0 if elapsed <= 0.0 else floori(elapsed * (2.8 if phase == 2 else 2.0)) % 8
	return _frames[index]

func attack_origin() -> Vector2:
	return position + Vector2(-170, 38)

func advance(delta: float, session: String, hits: int, required: int, paused: bool, engaged: bool, recovered: bool) -> void:
	if session != _session:
		_session = session
		elapsed = 0.0
		attack_clock = 0.0
		position = ANCHOR
		_transition_left = 0.0
	attack_event = false
	if paused:
		telegraph = false
		return
	var next_phase := 0 if recovered or required <= 0 or hits >= required else 2 if hits >= ceili(float(required) / 2.0) else 1
	if next_phase != phase:
		_transition_from = position
		_transition_left = 0.75
		phase = next_phase
	elapsed += maxf(delta, 0.0)
	var speed := 0.33 if phase == 0 else 0.57 if phase == 1 else 0.83
	var reach := 45.0 if phase == 0 else 125.0 if phase == 1 else 165.0
	var destination := ANCHOR + Vector2(110.0 + sin(elapsed * speed) * reach, sin(elapsed * speed * 1.45 + 0.3) * (22.0 if phase == 0 else 49.0 if phase == 1 else 70.0))
	if _transition_left > 0.0:
		_transition_left = maxf(0.0, _transition_left - maxf(delta, 0.0))
		position = _transition_from.lerp(destination, 1.0 - _transition_left / 0.75)
	else:
		position = destination
	if not engaged or phase == 0:
		attack_clock = 0.0
		telegraph = false
		return
	var period := 2.6 if phase == 2 else 3.5
	attack_clock += maxf(delta, 0.0)
	if attack_clock >= period:
		attack_clock = fmod(attack_clock, period)
		attack_event = true
	telegraph = attack_clock >= period - 0.7

func snapshot() -> Dictionary:
	return {"x": position.x, "y": position.y, "phase": phase, "frame": 0 if elapsed <= 0 else floori(elapsed * (2.8 if phase == 2 else 2.0)) % 8, "attackOrigin": attack_origin(), "telegraph": telegraph, "attackEvent": attack_event, "attackClock": attack_clock}
