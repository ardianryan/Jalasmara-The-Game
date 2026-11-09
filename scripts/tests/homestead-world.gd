extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state=root.get_node("GameState")
	var fixture:="res://../.runtime/world-map.json"
	if not FileAccess.file_exists(fixture): fixture="res://../.runtime/homestead-world.json"
	state.world=JSON.parse_string(FileAccess.get_file_as_string(fixture))
	assert(state.world.has("homestead"),"Regenerate current WORLD fixture with the actual homestead geometry")
	state.player={"appearance":"female_nusantara","coins":321,"progress":{"day":1,"stage":"dive"},"adventure":{"keyItems":[]}}
	state.dive={}
	state.homestead={"inside":true,"position":{"x":480,"y":580},"plots":[{"id":"plot_1","stage":"empty"},{"id":"plot_2","stage":"seed"}]}
	var outside=load("res://scripts/land/LandCollision.gd").new()
	outside.configure(state.world.landMaps.hub)
	for offset in [-12,0,12]:
		for y in range(740,856,4):
			assert(outside.is_walkable(Vector2(280+offset,y)),"Garden aisle must tolerate12px lateral drift while retaining13px body clearance")
	outside.free()
	var before:=JSON.stringify({"world":state.world,"player":state.player,"home":state.homestead})
	var scene=load("res://scripts/HomesteadScene.gd").new()
	root.add_child(scene)
	await process_frame
	scene.player.set_physics_process(false)
	assert(scene.terrain.is_walkable(scene.player.position))
	var interior:Dictionary=state.world.homestead.interior
	var samples:=0
	for route in interior.routes:
		for i in range(1,route.size()):
			var a:=Vector2(float(route[i-1][0]),float(route[i-1][1]))
			var b:=Vector2(float(route[i][0]),float(route[i][1]))
			for step in range(41):
				assert(scene.terrain.is_walkable(a.lerp(b,float(step)/40.0)),"Interior routes need actual13px clearance")
				samples+=1
	for obstacle in interior.obstacles:
		assert(not scene.terrain.is_walkable(Vector2(float(obstacle.x)+float(obstacle.width)*.5,float(obstacle.y)+float(obstacle.height)*.5)))
	for entry in [["bed",Vector2(270,330)],["archive",Vector2(650,280)],["chest",Vector2(700,425)],["display",Vector2(420,280)],["exit",Vector2(480,625)]]:
		scene.player.position=entry[1]
		scene._process(0)
		assert(scene.get_nearby()==entry[0],"Every object needs a reachable actual interaction approach")
	var calls:Array[String]=[]
	scene.interaction_requested.connect(func(id:String):calls.append(id))
	scene.interact()
	assert(calls==["exit"])
	scene.set_modal(true)
	scene.interact()
	assert(scene.player.frozen and calls.size()==1)
	scene.set_modal(false)
	assert(not scene.player.frozen)
	for appearance in ["male_default","male_nusantara","female_default","female_nusantara"]:
		scene.player.swim_sprite.set_appearance(appearance)
		for outfit in ["daily","explorer","diving"]:
			scene.player.swim_sprite.set_outfit(outfit)
			scene.player.swim_sprite.animate(false,false,1,0)
			scene.land_renderer.actors_3d.update_actors(0)
			assert(scene.land_renderer.actors_3d.max_foot_error<.01)
	var status:Dictionary=scene.land_renderer.debug_status()
	assert(status.area=="home" and status.warmLanterns==2 and status.actors.player==1)
	assert(status.components.has("RattanBedFrame") and status.components.has("ArchiveTabletop") and status.components.has("StorageChestBody"))
	assert(not status.components.has("OwnedMemoryArtifact"),"Empty key-item ownership must produce an empty shelf")
	assert(JSON.stringify({"world":state.world,"player":state.player,"home":state.homestead})==before,"Scene/renderer cannot mutate server-owned world or home/economy state")
	scene.free()
	print("HOMESTEAD WORLD PASS: ",samples," route samples, drift-tolerant garden aisle, physical furniture blockers, five reachable object signals, modal pause,4identities/3outfits foot anchoring, cutaway3D+2lamps, empty owned-item shelf, no server-state mutation")
	quit()
