extends SceneTree

var checks:=0

func _initialize() -> void: call_deferred("run")

func _v2(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))
func _v3(value: Array) -> Vector3: return Vector3(float(value[0]),float(value[1]),float(value[2]))

func _key(point: Vector3) -> Vector3i:
	return Vector3i(roundi(point.x*100),roundi(point.y*100),roundi(point.z*100))

func _in_polygon(point: Vector2,polygon: PackedVector2Array) -> bool:
	if Geometry2D.is_point_in_polygon(point,polygon): return true
	for index in range(polygon.size()):
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[index],polygon[(index+1)%polygon.size()]))<.01: return true
	return false

func _has_vertex(vertices: Dictionary,point: Vector3) -> bool:
	var at:=_key(point)
	for x in range(-1,2):
		for y in range(-1,2):
			for z in range(-1,2):
				if vertices.has(at+Vector3i(x,y,z)): return true
	return false

func run() -> void:
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	root.get_node("EnvironmentState").set_process(false)
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var stage:=Node2D.new()
	root.add_child(stage)
	var actor:=Node2D.new()
	stage.add_child(actor)
	var camera:=Camera2D.new()
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	for area in ["hub","forest"]:
		var map: Dictionary=state.world.landMaps[area]
		assert(map.get("gateways",[]).size()==1,"Integrated world must provide the authoritative gateway metadata")
		actor.position=_v2(map.gateways[0].center)
		if area=="hub": renderer.setup(stage,actor,camera,area)
		else: renderer.set_area(area)
		renderer.set_process(false)
		renderer._process(0)
		var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
		collision.configure(map)
		var status: Dictionary=renderer.debug_status()
		assert(status.components.RouteAlignedGateways==1)
		var batch_vertices: Dictionary={}
		for instance in renderer._geometry.find_children("*","MeshInstance3D",true,false):
			if not str(instance.name).begins_with("StaticMaterialBatch_"): continue
			for surface in range(instance.mesh.get_surface_count()):
				for vertex in instance.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
					batch_vertices[_key(instance.global_transform*vertex)]=true
		for gate in map.gateways:
			var record: Dictionary=status.gateways[str(gate.id)]
			var origin: Vector3=renderer.map_point(_v2(gate.center),float(gate.elevation)*renderer.LEVEL_HEIGHT)
			var road: Vector3=(renderer.map_point(_v2(gate.route.segment[1]))-renderer.map_point(_v2(gate.route.segment[0]))).normalized()
			var right:=road.cross(Vector3(0,0,1))
			var base_index:=0
			var roof_found:=false
			for mesh in record.meshes:
				assert(_v3(mesh.right).dot(right)>.99999,"Every box, roof, sign and lantern must use the physical road perpendicular")
				assert(_v3(mesh.forward).dot(road)>.99999)
				checks+=2
				if str(mesh.label).ends_with("_Base") and str(mesh.label)==str(gate.label)+"_Base":
					var collider: Dictionary={}
					for obstacle in map.obstacles:
						if str(obstacle.id)==str(gate.colliderIds[base_index]): collider=obstacle
					assert(not collider.is_empty())
					var center: Vector3=renderer.map_point(_v2(gate.postCenters[base_index]),float(gate.elevation)*renderer.LEVEL_HEIGHT)+Vector3(0,0,10)
					assert(_v3(mesh.center).distance_to(center)<.002,"Actual base center must coincide with its authoritative post")
					var polygon:=PackedVector2Array()
					for point in collider.footprint: polygon.append(_v2(point))
					var floor_vertices:=0
					for value in mesh.vertices:
						var vertex:=_v3(value)
						if absf(vertex.z-origin.z)>.01: continue
						assert(_in_polygon(renderer.ground_projection(vertex),polygon),"Physical base corner lies outside its actual collider footprint")
						floor_vertices+=1
						checks+=1
					assert(floor_vertices==4)
					base_index+=1
				if str(mesh.label).ends_with("_LintelRoof"):
					assert(_v3(mesh.center).distance_to(origin+Vector3(0,0,122))<.002,"Roof must be centered above the road, not the legacy post midpoint")
					for value in mesh.vertices:
						assert(_has_vertex(batch_vertices,_v3(value)),"Static batching lost the gate's actual rotated roof vertices")
						checks+=1
					roof_found=true
			assert(base_index==2 and roof_found)
			for step in range(49):
				var point:=_v2(gate.crossing[0]).lerp(_v2(gate.crossing[1]),float(step)/48)
				assert(collision.is_walkable(point),"Actual radius13 collision blocks the gate approach/aperture/exit")
				checks+=1
			for post in gate.postCenters: assert(not collision.is_walkable(_v2(post)),"Visual post cannot be non-solid")
			if area=="hub":
				assert(record.sideFences.size()==2)
				for side in record.sideFences:
					assert(float(side.depth)>190 and float(side.width)==25 and int(side.supportCount)>=20,"Existing long side fence must visibly follow its actual footprint")
			else: assert(record.sideFences.is_empty())
		collision.free()
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before,"Architecture may not mutate gameplay state")
	print("GATEWAY ARCHITECTURE06 PASS: ",checks," emitted geometry/batched roof/actual radius13 crossing checks; 2 gates,4 grounded bases,2 visible compound side fences")
	stage.free()
	quit()
