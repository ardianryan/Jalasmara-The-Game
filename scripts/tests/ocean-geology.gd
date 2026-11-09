extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var terrain=load("res://scripts/hybrid/TerrainGeometry.gd").new()
	root.add_child(terrain)
	terrain.configure(data)
	var geology=terrain.geology
	var before:=JSON.stringify(data)
	assert(geology.connections.size()>=8)
	for connection in geology.connections:
		var source:Array=data.terrain[int(connection.terrain)]
		var source_rect:=Rect2(source[0],source[1],source[2],source[3])
		assert(source_rect.has_point(Vector2(connection.top[0],connection.top[1])))
		var target:=int(connection.anchoredTo)
		if target>=0:
			var destination:Array=data.terrain[target]
			assert(Rect2(destination[0],destination[1],destination[2],destination[3]).has_point(Vector2(connection.base[0],connection.base[1])))
		else: assert(float(connection.base[1])>=3500)
		assert(connection.decorativeRear and not connection.collision)
	assert(geology.find_children("*","CollisionObject3D",true,false).is_empty())
	for instance in geology.get_children():
		for surface in instance.mesh.get_surface_count():
			for vertex in instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]: assert(vertex.z < -100)
	for camera in [Vector2.ZERO,Vector2(1550,620),Vector2(6144,3584),Vector2(-100,-100)]:
		geology.update_camera(camera)
		assert(geology.position==Vector3.ZERO,"Anchored roots must not drift relative to foreground at camera extremes")
		assert(geology.debug_status().parallaxOffset==[0.0,0.0])
	assert(JSON.stringify(data)==before)
	assert(load("res://scripts/hybrid/HybridOcean.gd").can_instantiate())
	print("GEOLOGY ANCHORS PASS: ",geology.connections.size()," roots anchored to lower stratum/seabed, rear-only depth, camera-locked seams at all world extremes, no collision/world mutation; HybridOcean parse")
	terrain.free()
	quit()
