extends RefCounted

const MAX_SURFACE_BUBBLES := 18
const MAX_UNDERWATER_BUBBLES := 12

static func intensity(player: Dictionary, adventure: Dictionary, source: String = "main", dive: Dictionary = {}) -> float:
	if bool(player.get("progress", {}).get("bossDefeated", false)):
		return 0.0
	if str(dive.get("mode", "")) == "boss" and int(dive.get("requiredHits", 0)) > 0 and int(dive.get("hits", 0)) >= int(dive.get("requiredHits", 0)):
		return 0.0
	if source == "valve" and adventure.get("puzzles", []).has("valve"):
		return 0.34
	return 1.0

static func source_position(world: Dictionary, id: String, fallback: Vector2) -> Vector2:
	var collection := "puzzles" if id == "valve" else "landmarks"
	for item in world.get(collection, []):
		if str(item.get("id", "")) == id:
			return Vector2(float(item.get("x", fallback.x)), float(item.get("y", fallback.y)))
	return fallback

static func bubble_offset(index: int, time: float, rise: float, reduced_motion: bool) -> Vector2:
	var speed := 0.18 if reduced_motion else 1.0
	var phase := fposmod(float(index) * 0.341 + time * speed * (0.24 + float(index % 3) * 0.035), 1.0)
	var lane := float((index * 7) % 11) - 5.0
	var drift := sin(float(index) * 1.7 + time * speed * 0.8) * (1.5 if reduced_motion else 6.0)
	return Vector2(lane * 6.0 + drift, -phase * rise)
