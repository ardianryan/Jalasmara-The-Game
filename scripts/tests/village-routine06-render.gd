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
	root.get_node("RenderQuality").set_profile("balanced",false)
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
	for child in scene.get_children():
		if child.has_method("configure_activity"): child.set_process(false)
	var subject:Node2D
	for child in scene.get_children():
		if child.get("actor_name")=="Mang Ujang": subject=child
	assert(subject!=null)
	var reduced:=OS.get_environment("NPC_06_REDUCED")=="1"
	clock.reduced_motion=reduced
	var directory:="res://../artifacts/godot/06b-routines/"+("reduced" if reduced else "normal")
	DirAccess.make_dir_recursive_absolute(directory)
	var report:Dictionary={"reducedMotion":reduced,"simulationDelta":.1,"recordingFps":10,"frames":{},"clips":{},"phases":{}}
	var previous:=subject.position
	player.position=Vector2(600,650)
	for frame in range(590):
		if frame==30:
			player.position=subject.position+Vector2(45,0)
			clock.clock_paused=true
		if frame==50:
			player.position=Vector2(600,650)
			clock.clock_paused=false
		if frame==80: clock.visual_minutes=1100
		if frame==250: clock.visual_minutes=600
		if frame==420: clock.elapsed_seconds=180
		subject.call("_process",.1)
		assert(collision.is_walkable(subject.position))
		assert(subject.position.distance_to(previous)<=2.601)
		previous=subject.position
		camera.position=subject.position+Vector2(0,-45)
		camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		land.viewport_3d.get_texture().get_image().save_png(directory+"/%03d.png"%frame)
		var body:Dictionary=subject.body_animation_state()
		var routine:Dictionary=subject.activity_state()
		report.clips[body.clip]=true
		report.phases[routine.phase]=true
		if frame in [24,45,72,120,240,300,410,460,589]:
			root.get_texture().get_image().save_png(directory+"/scene-%03d.png"%frame)
			report.frames[str(frame)]={"routine":routine,"body":body,"position":[subject.position.x,subject.position.y]}
	assert(report.clips.has("walk") and report.clips.has("interact") and report.clips.has("work_loop"))
	assert(report.phases.has("rest") and report.phases.has("shelter") and report.phases.has("walking_work"))
	FileAccess.open(directory+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("VILLAGE06 NATIVE PASS: actual Ujang work-dialogue-resume-home-return-rain-shelter, displacement and authored collisions retained; reduced=",reduced)
	scene.free()
	quit()
