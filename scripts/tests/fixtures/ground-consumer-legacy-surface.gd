extends "res://scripts/SurfaceTraversal.gd"

func _surface_at(point: Vector2) -> Dictionary:
	var selected: Dictionary = {}
	for surface in _hub.get("surfaces",[]):
		var polygon := PackedVector2Array()
		for vertex in surface.get("polygon",[]): polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
		if Geometry2D.is_point_in_polygon(point,polygon) and (selected.is_empty() or int(surface.get("priority",0))>=int(selected.get("priority",0))): selected = surface
	return selected
