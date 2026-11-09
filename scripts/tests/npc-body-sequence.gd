extends SceneTree

# Optional native recording proof; not part of headless CI.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1440,810)
	for action in ["left","right","up","down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
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
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
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
	var report: Dictionary={}
	for pilot in ["Mang Ujang","Bu Darmi","Yu Sari"]:
		var subject: Node2D
		for child in scene.get_children():
			if child is Node2D and child.get("actor_name")==pilot: subject=child
		if subject==null: continue
		for child in scene.get_children():
			if child.has_method("configure_activity"): child.set_process(false)
		var folder: String="res://../artifacts/godot/npc-body-rig/"+pilot.to_lower().replace(" ","-")
		DirAccess.make_dir_recursive_absolute(folder)
		clock.visual_minutes=600
		clock.clock_paused=false
		var clips: Dictionary={}
		var phases: Dictionary={}
		var origin: Vector2=subject.position
		for frame in range(180):
			if frame==120: clock.visual_minutes=1300
			if frame==156:
				player.position=subject.position+Vector2(45,0)
				clock.clock_paused=true
			subject.call("_process",1.0/12.0)
			camera.position=subject.position+Vector2(0,-45)
			camera.force_update_scroll()
			await process_frame
			await RenderingServer.frame_post_draw
			land.viewport_3d.get_texture().get_image().save_png(folder+"/%03d.png"%frame)
			var body: Dictionary=subject.body_animation_state()
			clips[str(body.clip)]=true
			phases[str(body.workPhase)]=true
			if frame in [24,84,150,175]: root.get_texture().get_image().save_png(folder+"/scene-%03d.png"%frame)
		assert(clips.has("work_loop") and clips.has("walk") and clips.has("interact"),"Native pilot must demonstrate work, travel and dialogue")
		assert(origin.distance_to(subject.position)>40,"Navigation must move the actor without animation root motion")
		report[pilot]={"clips":clips.keys(),"phases":phases.keys(),"travel":origin.distance_to(subject.position),"body":subject.body_animation_state(),"rigs":land.actors_3d.counts.get("bodyClips",{})}
		player.position=Vector2(1120,1230)
	FileAccess.open("res://../artifacts/godot/npc-body-rig/recording.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("NPC BODY SEQUENCE PASS ",report.keys())
	quit()
