extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,810)
	for action in ["left","right","up","down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_default","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.visual_minutes=600
	clock.elapsed_seconds=0
	clock.reduced_motion=false
	clock.clock_paused=false
	var scene:=Node2D.new()
	root.add_child(scene)
	var player: Node2D=load("res://scripts/Player.gd").new()
	scene.add_child(player)
	player.set_physics_process(false)
	var outfit:=OS.get_environment("OUTFIT_PROOF")
	if outfit.is_empty(): outfit="diving"
	player.swim_sprite.set_appearance("male_default")
	player.outfit=outfit
	player.swim_sprite.set_outfit(outfit)
	player.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(1.2,1.2)
	scene.add_child(camera)
	var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
	collision.configure(state.world.landMaps.hub)
	scene.add_child(collision)
	var profiles: Array=state.world.surface_hub.residents.duplicate(true)
	var gardener: Dictionary=state.world.surface_hub.districtActivities["Bu Darmi"].duplicate(true)
	gardener["name"]="Bu Darmi"
	profiles.append(gardener)
	for profile in profiles:
		var npc: Node2D=load("res://scripts/HubActor.gd").new()
		npc.actor_name=str(profile.name)
		if profile.has("appearance"):
			npc.appearance_index=int(profile.appearance)
			npc.custom_sheet=load("res://resources/art/village-residents-v1.png")
			npc.custom_grid=Vector2i(3,2)
		npc.position=Vector2(float(profile.activity.work[0]),float(profile.activity.work[1]))
		npc.player=player
		npc.walkable=Callable(collision,"is_walkable")
		npc.set_meta("land_hidden",true)
		scene.add_child(npc)
		npc.configure_activity(profile)
	var land: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	scene.add_child(land)
	land.setup(scene,player,camera,"hub")
	player.visible=false
	var center:=Vector2(900,650)
	for candidate in [Vector2(1200,650),Vector2(1100,650),Vector2(900,650),Vector2(900,620),Vector2(950,640),Vector2(1000,650)]:
		var valid:=true
		for d in range(8):
			for step in range(14):
				if not collision.is_walkable(candidate+Vector2.RIGHT.rotated(d*PI*.25)*step*5): valid=false
		if valid:
			center=candidate
			break
	DirAccess.make_dir_recursive_absolute("res://../artifacts/godot/player-outfit-world/"+outfit+"")
	var report: Dictionary={}
	for d in range(8):
		player.position=center
		camera.position=center+Vector2(0,-40)
		camera.force_update_scroll()
		var vector:=Vector2.RIGHT.rotated(d*PI*.25)*175
		for frame in range(20):
			var previous: Vector2=player.position
			var next: Vector2=previous+vector*.02
			assert(collision.is_walkable(next),"Pilot proof path must remain on actual ground")
			player.position=next
			player.swim_sprite.set_outfit(outfit)
			player.swim_sprite.set_equipment({"tank":outfit=="diving","net":outfit=="diving","satchel":outfit=="explorer"})
			player.swim_sprite.set_locomotion((next-previous)/.02,.02)
			player.swim_sprite.animate(true,false,1,0)
			player.visible=false
			await process_frame
			await RenderingServer.frame_post_draw
			assert(player.swim_sprite.outfit==outfit,"Fixture outfit changed unexpectedly")
			var sprite: Sprite3D=land.actors_3d.sprites["Nala"]
			var projected: Vector2=land.ground_projection(sprite.position-land.camera_up()*40)
			assert(projected.distance_to(player.position)<2,"Authored foot pivot must remain on actual logical ground")
			land.viewport_3d.get_texture().get_image().save_png("res://../artifacts/godot/player-outfit-world/"+outfit+"/%03d.png"%(d*20+frame))
			if frame==10: root.get_texture().get_image().save_png("res://../artifacts/godot/player-outfit-world/"+outfit+"/direction-%d.png"%d)
		report[str(d)]=player.swim_sprite.locomotion_state()
		assert(report[str(d)].supportedDirections.size()==8 and not report[str(d)].directionalFallback)
	FileAccess.open("res://../artifacts/godot/player-outfit-world/"+outfit+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("OUTFIT MODULAR NATIVE FULL WORLD PASS ",report.keys())
	quit()
