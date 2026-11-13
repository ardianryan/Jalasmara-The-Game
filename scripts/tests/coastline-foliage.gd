extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var contour=load("res://scripts/land/CoastlineContour.gd")
	var original:=PackedVector2Array([Vector2(0,0),Vector2(420,0),Vector2(560,120),Vector2(420,300),Vector2(0,300)])
	var before:=original.duplicate()
	var outline: PackedVector2Array=contour.naturalize(original)
	assert(outline.size()>original.size()*2)
	assert(outline==contour.naturalize(original),"Coastline must be deterministic")
	assert(original==before,"Visual coastline must not change collision polygons")
	assert(not Geometry2D.triangulate_polygon(outline).is_empty(),"Smoothed coastline must remain a valid surface")
	for point in outline:
		var nearest:=INF
		for index in range(original.size()):
			nearest=minf(nearest,Geometry2D.get_closest_point_to_segment(point,original[index],original[(index+1)%original.size()]).distance_to(point))
		assert(nearest<=21.0,"Coastline relief must remain near the authored shore")
	var world: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var coast:=PackedVector2Array()
	for pair in world.landMaps.hub.landmass: coast.append(Vector2(float(pair[0]),float(pair[1])))
	var active_outline: PackedVector2Array=contour.naturalize(coast)
	assert(not Geometry2D.triangulate_polygon(active_outline).is_empty(),"Production hub shoreline must remain a valid mesh")
	assert(coast.size()==world.landMaps.hub.landmass.size(),"Production map must not change")
	for area in ["hub","forest"]:
		for surface in world.landMaps[area].surfaces:
			if str(surface.id) not in ["lower_court","forest_west_land","forest_east_land"]: continue
			var floor:=PackedVector2Array()
			for pair in surface.polygon: floor.append(Vector2(float(pair[0]),float(pair[1])))
			var anchors:=PackedVector2Array()
			if str(surface.id)=="lower_court":
				for stair in world.landMaps.hub.stairs:
					for pair in stair.path: anchors.append(Vector2(float(pair[0]),float(pair[1])))
			var visual: PackedVector2Array=contour.naturalize(floor,true,anchors)
			assert(not Geometry2D.triangulate_polygon(visual).is_empty(),"Production natural bank must remain triangulatable")
			assert(visual.size()>floor.size())
			if str(surface.id)=="lower_court":
				for point in visual:
					if point.distance_to(Vector2(1120,1125))<80.0:
						assert(absf(point.y-1125.0)<.001,"Visual bank must keep the dock stair landing clear")
	var motion=load("res://scripts/FoliageMotion.gd")
	var at:=Vector2(100,150)
	assert(motion.land_offset(1.01,at,18.0,1.0)==motion.land_offset(1.07,at,18.0,1.0),"Foliage must hold its pixel pose within a 100 ms step")
	for t in range(0,80):
		var offset: float=motion.land_offset(float(t)*.1,at,18.0,1.0)
		assert(offset==roundf(offset),"Foliage offset must stay on the pixel grid")
	print("PASS coastline and foliage motion")
	quit()
