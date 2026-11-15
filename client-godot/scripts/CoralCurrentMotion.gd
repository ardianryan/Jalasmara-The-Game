extends RefCounted

const MAX_ANGLE := 0.048

static func angle(seconds: float, at: Vector2, current_x: float) -> float:
	var tick := floorf(seconds * 10.0) / 10.0
	var flow := clampf(current_x / 14.0, -1.0, 1.0)
	var wave := sin(tick * 1.05 + at.x * 0.006 + at.y * 0.002) * 0.025
	wave += sin(tick * 1.71 - at.x * 0.003 + at.y * 0.001) * 0.008
	return clampf(flow * 0.017 + wave * lerpf(0.45, 1.0, absf(flow)), -MAX_ANGLE, MAX_ANGLE)
