extends RefCounted

const Polygon = preload("res://scripts/land/LandGeometry.gd")
var _entries: Array[Dictionary] = []

func clear() -> void:
	_entries.clear()

func prepare(index: int, polygon: Array) -> Dictionary:
	while _entries.size()<=index: _entries.append({})
	var entry: Dictionary = _entries[index]
	# Native deep equality catches replacement and in-place edits without a hash collision.
	if entry.is_empty() or entry.polygon!=polygon:
		var frozen: Array = polygon.duplicate(true)
		entry = {"polygon":frozen,"bounds":Polygon.polygon_bounds(frozen)}
		_entries[index] = entry
	return entry

func contains(point: Vector2, polygon: Array, index: int) -> bool:
	var entry := prepare(index,polygon)
	return Polygon.cached_point_in_polygon(point,entry.polygon,entry.bounds)
