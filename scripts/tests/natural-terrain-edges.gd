extends SceneTree

func _initialize() -> void: call_deferred("run")

func _polygon(values: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for value in values: result.append(Vector2(value[0],value[1]))
	return result

func run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var unchanged:=JSON.stringify(state.world)
	var helper=load("res://scripts/land/NaturalTerrainEdges3D.gd").new()
	var synthetic: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	root.add_child(synthetic)
	var square:={"id":"closed_corner_test","material":"grass","elevation":2,"polygon":[[400,400],[700,400],[700,650],[400,650]]}
	synthetic.map={"surfaces":[square,{"id":"real_lower_floor","material":"grass","elevation":0,"polygon":[[-4000,-4000],[4000,-4000],[4000,4000],[-4000,4000]]}],"stairs":[]}
	var profile: Dictionary=helper.make_profile(synthetic,square,_polygon(square.polygon),96.0)
	assert(profile==helper.make_profile(synthetic,square,_polygon(square.polygon),96.0),"Geometry must be deterministic without global RNG or camera input")
	assert(profile.bevels==4 and profile.excluded==0)
	var normals: Dictionary={}
	var fans:=0
	for index in range(profile.nodes.size()):
		var node: Dictionary=profile.nodes[index]
		var next: Dictionary=profile.nodes[(index+1)%profile.nodes.size()]
		assert(profile.active[index])
		assert(node.rings[4].z==-5.0 and node.support==0.0,"Root must meet the actual lower floor, not stop after a fixed 44px wall")
		for layer in range(4): assert(node.rings[layer].z>node.rings[layer+1].z)
		var normal: Vector3=(next.rings[2]-node.rings[2]).cross(node.rings[3]-node.rings[2]).normalized()
		normals[str(normal.snapped(Vector3(.01,.01,.01)))]=true
		if node.logical==next.logical:
			assert(node.rings[1].distance_to(next.rings[1])>1,"Adjacent corner facets must form a continuous fan, not coincident 90-degree wall corners")
			fans+=1
	assert(fans==8 and normals.size()>16,"Shoulders need real noncoplanar facets, not a flat wall with scattered prop rocks")
	for material in ["dock","wood","bridge"]:
		var wood: Dictionary=square.duplicate(true)
		wood.material=material
		assert(helper.make_profile(synthetic,wood,_polygon(square.polygon),96).is_empty())
		assert(not helper.build_surface(synthetic,wood,_polygon(square.polygon),96),"Wooden structures must keep their existing straight architecture")
	synthetic.free()
	var actual_nodes:=0
	var cutouts:=0
	var supports:=0
	var actual_surfaces:=0
	for area in ["hub","forest"]:
		var stage:=Node2D.new()
		root.add_child(stage)
		var player:=Node2D.new()
		stage.add_child(player)
		var camera:=Camera2D.new()
		stage.add_child(camera)
		var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
		stage.add_child(renderer)
		renderer.setup(stage,player,camera,area)
		renderer.set_process(false)
		renderer._process(0)
		assert(renderer._components.get("NaturalTerrainShoulder",0)>0,"Actual renderer must replace exposed stone TerraceFace geometry through the helper")
		var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
		stage.add_child(collision)
		collision.configure(renderer.map)
		var before:=JSON.stringify(renderer.map)
		for surface in renderer.map.surfaces:
			if int(surface.get("priority",0))>0 or surface.has("connectorId") or str(surface.material) in ["bridge","dock","wood"]: continue
			var height: float=float(surface.get("heightPixels",float(surface.get("elevation",0))*renderer.LEVEL_HEIGHT))
			var shape: Dictionary=helper.make_profile(renderer,surface,_polygon(surface.polygon),height)
			if shape.is_empty(): continue
			actual_surfaces+=1
			cutouts+=int(shape.excluded)
			for index in range(shape.nodes.size()):
				var node: Dictionary=shape.nodes[index]
				if not shape.active[index]: continue
				for at: Vector3 in node.rings:
					assert(not renderer._connector_at(renderer.ground_projection(at)),"Natural edge vertices must clear actual stair/ramp cutouts at their true height")
				assert(node.rings[4].z<=node.support-4.99)
				if node.support> -40.0: supports+=1
				actual_nodes+=1
		for stair in renderer.map.stairs:
			var start:=Vector2(stair.path[0][0],stair.path[0][1])
			var end:=Vector2(stair.path[1][0],stair.path[1][1])
			for part in range(17): assert(collision.is_walkable(start.lerp(end,float(part)/16)),"Existing stair travel remains on its authoritative floor")
		assert(JSON.stringify(renderer.map)==before,"Edge rendering cannot edit floors, routes, stairs, obstacles or collider source")
		stage.free()
	assert(actual_surfaces>=4 and actual_nodes>100 and cutouts>0 and supports>0)
	assert(JSON.stringify(state.world)==unchanged)
	print("NATURAL TERRAIN EDGES PASS: continuous corner fans,deterministic noncoplanar shoulders,rooted real-floor toes,wood untouched; actual surfaces=",actual_surfaces," nodes=",actual_nodes," cutouts=",cutouts," supported=",supports,"; no authoritative geometry mutation")
	quit()
