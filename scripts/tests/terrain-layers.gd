extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var terrain = load("res://scripts/hybrid/TerrainGeometry.gd").new()
	root.add_child(terrain)
	terrain.configure(data)
	var status: Dictionary = terrain.debug_status()
	assert(status.terrainVolumes == 15)
	assert(status.layeredBands > 400)
	assert(status.modelInstances == 3)
	assert(status.memoryBackingInstances == 1)
	var profiles := load("res://scripts/hybrid/TerrainLayerProfile.gd")
	assert(profiles.at_depth(900).id != profiles.at_depth(2500).id)
	assert(profiles.at_depth(2500).id != profiles.at_depth(3300).id)
	var vertices := 0
	for instance in terrain.get_children():
		if not instance is MeshInstance3D or not str(instance.name).begins_with("ReefRelief"): continue
		var index := int(str(instance.name).trim_prefix("ReefRelief"))
		var polygon := PackedVector2Array()
		for point in data.terrainContours[index]: polygon.append(Vector2(point[0],point[1]))
		for surface in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				vertices += 1
				var point := Vector2(vertex.x,-vertex.y+sin(deg_to_rad(12.0))*vertex.z)
				var inside := Geometry2D.is_point_in_polygon(point,polygon)
				for edge in polygon.size():
					if Geometry2D.get_closest_point_to_segment(point,polygon[edge],polygon[(edge+1)%polygon.size()]).distance_to(point)<0.05: inside=true
				assert(inside,"Layered mesh escaped authoritative contour")
	assert(vertices > 3000)
	var backing: Node3D = terrain.get_node("MemorySlabBacking")
	assert(backing.find_children("*","MeshInstance3D",true,false).size() == 2)
	assert(backing.position.z < 0,"Original PNG tablet must remain in front of physical backing")
	print("TERRAIN LAYERS PASS: 15 contours, ",status.layeredBands," terrace bands, ",vertices," projected vertices, three Polyfork GLBs and actual two-mesh img2threejs backing")
	terrain.free()
	quit()
