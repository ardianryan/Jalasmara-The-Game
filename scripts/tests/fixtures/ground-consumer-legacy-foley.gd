extends "res://scripts/WorldFoley.gd"

var baseline_state: Node

func material_at(point: Vector2) -> String:
	var maps: Dictionary = baseline_state.world.get("landMaps",{})
	var map: Dictionary = maps.get(area,{})
	if _has_traversal:
		var traversal: Dictionary = actor.get("traversal_state")
		if bool(traversal.get("onConnector",false)):
			var surface := str(traversal.get("footstepMaterial",""))
			if FOOTSTEPS.has(surface): return surface
	for stair in map.get("stairs",[]):
		var path: Array = stair.get("path",[])
		if path.size()<2: continue
		for index in range(path.size()-1):
			var a := Vector2(float(path[index][0]),float(path[index][1]))
			var b := Vector2(float(path[index+1][0]),float(path[index+1][1]))
			var progress := (point-a).dot(b-a)/maxf(1,(b-a).length_squared())
			if progress>=0 and progress<=1 and point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)) <= float(stair.get("width",90))/2:
				var surface := str(stair.get("material","stone"))
				if FOOTSTEPS.has(surface): return surface
	var selected := ""
	var priority := -INF
	var elevation := -INF
	for surface in map.get("surfaces",[]):
		var polygon := PackedVector2Array()
		for vertex in surface.get("polygon",[]): polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
		if polygon.size()<3 or not Geometry2D.is_point_in_polygon(point,polygon): continue
		var candidate := str(surface.get("material",""))
		var candidate_priority := float(surface.get("priority",0))
		var candidate_elevation := float(surface.get("elevation",0))
		if FOOTSTEPS.has(candidate) and (candidate_priority>priority or (candidate_priority==priority and candidate_elevation>elevation)):
			selected = candidate
			priority = candidate_priority
			elevation = candidate_elevation
	return selected
