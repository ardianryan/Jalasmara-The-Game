extends SceneTree

class Actor extends Node2D:
	var swim_sprite: Sprite2D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var fixture:="res://../.runtime/world-map.json"
	if not FileAccess.file_exists(fixture): fixture="res://../.runtime/land-world-map.json"
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string(fixture))
	assert(state.world.has("landMaps"),"World fixture must include authoritative component land maps")
	state.player={"appearance":"male_default","coins":321,"progress":{"day":1,"stage":"dive"}}
	state.dive={}
	var before:=JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Actor.new()
	scene.add_child(actor)
	actor.swim_sprite=load("res://scripts/CharacterVisual.gd").new()
	actor.add_child(actor.swim_sprite)
	actor.swim_sprite.set_appearance("male_default")
	actor.swim_sprite.animate(false,false,1,0)
	actor.position=Vector2(1120,1230)
	var camera:=Camera2D.new()
	camera.position=actor.position
	camera.zoom=Vector2(.88,.88)
	scene.add_child(camera)
	camera.force_update_scroll()
	var renderer=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(renderer)
	renderer.setup(scene,actor,camera,"hub")
	await process_frame
	renderer._process(.3)
	var checks:=0
	for point in [Vector2(1120,1230),Vector2(595,650),Vector2(1370,775),Vector2(2295,125)]:
		for height in [0.0,48.0,96.0,144.0]:
			var world_point: Vector3=renderer.map_point(point,height)
			assert(renderer.ground_projection(world_point).distance_to(point)<.001)
			var pixel: Vector2=renderer.camera_3d.unproject_position(world_point)
			var expected: Vector2=Vector2(240,135)+(point-renderer.get("_center"))*.44
			assert(pixel.distance_to(expected)<.05,"Rendered elevated feet must project onto the actual logical floor")
			checks+=1
	var status: Dictionary=renderer.debug_status()
	assert(status.active and status.renderer=="LandSubViewport3D")
	assert(status.elevationDegrees==35 and status.viewport==[480,270])
	assert(not status.bitmapGround and status.houses==3 and status.glbModels>0)
	assert(status.meshes<60,"Static material batches must not become hundreds of draw calls")
	assert(status.stairTreads>=10 and status.actors.player==1)
	assert(float(status.maxFootError)<.01,"Actual atlas alpha-bottom must stay at the ground pivot")
	assert(status.warmLanterns==3 and renderer.sunlight.shadow_enabled)
	for light in renderer.get("_lanterns"): assert(light is OmniLight3D and light.omni_range>=200)
	assert(renderer.world_root.find_children("*","CollisionObject3D",true,false).is_empty(),"Renderer must not invent unsynchronized physics")
	renderer.set_area("forest")
	renderer._process(.3)
	var forest: Dictionary=renderer.debug_status()
	assert(forest.trees>=30 and forest.glbModels>=4)
	assert(forest.water.mesh and forest.water.vertexWaves)
	var authored_bridges: Array=state.world.landMaps.forest.get("bridges",[])
	assert(authored_bridges.size()==2,"Renderer test needs both authoritative river crossings")
	assert(forest.get("bridges",{}).size()==authored_bridges.size())
	for bridge in authored_bridges:
		var emitted: Dictionary=forest.bridges.get(str(bridge.id),{})
		assert(not emitted.is_empty(),"Priority overlays must not skip bridge geometry")
		assert(emitted.oriented and float(emitted.thickness)>=12,"Bridge deck needs actual oriented thickness")
		assert(int(emitted.planks)>=8 and int(emitted.sideBeams)==2,"Planks and both supporting side beams must actually be emitted")
		assert(int(emitted.railPosts)>=8 and int(emitted.railBeams)>=4,"Both authoritative rail blockers need posts and horizontal beams")
		for index in range(2):
			assert(Vector2(float(emitted.endpoints[index][0]),float(emitted.endpoints[index][1])).distance_to(Vector2(float(bridge.path[index][0]),float(bridge.path[index][1])))<.01)
		var expected_axis:=(Vector2(float(bridge.path[1][0]),float(bridge.path[1][1]))-Vector2(float(bridge.path[0][0]),float(bridge.path[0][1]))).normalized()
		assert(Vector2(float(emitted.axis[0]),float(emitted.axis[1])).dot(expected_axis)>.999,"Visible planks must follow the crossing axis, not world X/Y")
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before)
	state.dive={"id":"renderer-test","oxygen":77,"loot":[]}
	renderer.set_area("hub")
	renderer._process(.1)
	assert(not renderer.active and not renderer.display.visible)
	assert(renderer.viewport_3d.render_target_update_mode==SubViewport.UPDATE_DISABLED)
	assert(state.dive.oxygen==77)
	scene.free()
	print("LAND RENDERER PASS: ",checks," exact projected feet across4 elevations, 35degree camera, true3D architecture/GLB/trees/stairs, bounded batches, alpha-foot anchors, warm spatial lamps, emitted oriented bridge planks/beams/rails/thickness, no collision/resource mutation, dive transition")
	quit()
