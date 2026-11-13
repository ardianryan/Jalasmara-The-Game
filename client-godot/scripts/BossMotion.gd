extends RefCounted

const ANCHOR := Vector2(3820, 3140)
const IMAGE := "res://resources/art/gajah-mina-motion-v1/swim.png"
const CELL := Vector2(224, 160)
const FRAME_COUNT := 12
var position := ANCHOR
var elapsed := 0.0
var swim_phase := 0.0
var visual_pitch := 0.0
var attack_clock := 0.0
var attack_event := false
var telegraph := false
var phase := 0
var _recovery_left := 0.0
var _session := ""
var _frames: Array[Texture2D] = []
var _transition_from := ANCHOR
var _transition_left := 0.0

func frame() -> Texture2D:
	if _frames.is_empty():
		var atlas: Texture2D = load(IMAGE)
		if atlas == null: return null
		for index in range(FRAME_COUNT):
			var cell := AtlasTexture.new()
			cell.atlas = atlas
			cell.region = Rect2(index * CELL.x, 0, CELL.x, CELL.y)
			cell.filter_clip = true
			_frames.append(cell)
	var index := floori(fposmod(swim_phase, TAU) / TAU * FRAME_COUNT) % FRAME_COUNT
	return _frames[index]

func attack_origin() -> Vector2:
	return position + Vector2(-170, 38).rotated(visual_pitch)

func second_attack_origin() -> Vector2:
	return position + Vector2(45, -125).rotated(visual_pitch)

func visual_angle() -> float:
	return visual_pitch

func advance(delta: float, session: String, hits: int, required: int, paused: bool, engaged: bool, recovered: bool) -> void:
	if session != _session:
		_session = session
		elapsed = 0.0
		swim_phase = 0.0
		visual_pitch = 0.0
		attack_clock = 0.0
		_recovery_left = 0.0
		position = ANCHOR
		_transition_left = 0.0
	attack_event = false
	if paused:
		telegraph = false
		return
	var dt := maxf(delta, 0.0)
	var next_phase := 0 if recovered or required <= 0 or hits >= required else 2 if hits >= ceili(float(required) / 2.0) else 1
	if next_phase != phase:
		_transition_from = position
		_transition_left = 0.75
		phase = next_phase
		attack_clock = 0.0
		_recovery_left = 0.0
	elapsed += dt
	swim_phase += TAU * (0.35 if phase == 0 else 0.62 if phase == 1 else 0.88) * dt
	var speed := 0.3 if phase == 0 else 0.48 if phase == 1 else 0.68
	var reach := 35.0 if phase == 0 else 110.0 if phase == 1 else 145.0
	var rise := 18.0 if phase == 0 else 40.0 if phase == 1 else 58.0
	var destination := ANCHOR + Vector2(90.0 + sin(elapsed * speed) * reach, cos(elapsed * speed) * rise)
	var attack_offset := 0.0
	if not engaged or phase == 0:
		attack_clock = 0.0
		_recovery_left = 0.0
		telegraph = false
	else:
		var period := 2.6 if phase == 2 else 3.5
		attack_clock += dt
		if attack_clock >= period:
			attack_clock = fmod(attack_clock, period)
			attack_event = true
			_recovery_left = 0.55
		telegraph = attack_clock >= period - 0.7 and _recovery_left <= 0.0
		if _recovery_left > 0.0:
			var recovery_t := 1.0 - _recovery_left / 0.55
			attack_offset = 8.0 * (1.0 - recovery_t) - 22.0 * sin(PI * recovery_t)
			_recovery_left = maxf(0.0, _recovery_left - dt)
		elif telegraph:
			var charge_t := clampf((attack_clock - (period - 0.7)) / 0.7, 0.0, 1.0)
			attack_offset = 8.0 * charge_t * charge_t * (3.0 - 2.0 * charge_t)
	destination.x += attack_offset
	var previous := position
	if _transition_left > 0.0:
		_transition_left = maxf(0.0, _transition_left - dt)
		var transition_t := 1.0 - _transition_left / 0.75
		position = _transition_from.lerp(destination, transition_t * transition_t * (3.0 - 2.0 * transition_t))
	else:
		position = destination
	if dt > 0.0:
		var vertical_speed := (position.y - previous.y) / dt
		var pitch_target := clampf(-vertical_speed / 650.0, -0.09, 0.09)
		visual_pitch = lerpf(visual_pitch, pitch_target, 1.0 - exp(-dt * 5.0))

func snapshot() -> Dictionary:
	return {"x": position.x, "y": position.y, "phase": phase, "frame": floori(fposmod(swim_phase, TAU) / TAU * FRAME_COUNT) % FRAME_COUNT, "angle": visual_pitch, "attackOrigin": attack_origin(), "telegraph": telegraph, "attackEvent": attack_event, "attackClock": attack_clock}
