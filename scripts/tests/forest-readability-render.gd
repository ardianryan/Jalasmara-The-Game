extends SceneTree

var output := "res://../artifacts/godot/06a-hutan/before"
var report: Dictionary = {}
var build_ms: Dictionary = {}
var acceptance := false

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
		if argument=="--acceptance": acceptance=true
	call_deferred("run")

func capture(id: String, renderer: Node) -> void:
	renderer._process(.5)
	for tick in range(6): await process_frame
	await RenderingServer.frame_post_draw
	assert(renderer.debug_status().actors.player==1,"Readability proof requires a rendered Nala, not an uninitialized visual")
	root.get_texture().get_image().save_png(output+"/"+id+".png")
	report[id]=renderer.debug_status()
	report[id]["weather"]=root.get_node("EnvironmentState").snapshot()
	report[id]["player"]=[renderer.actor.position.x,renderer.actor.position.y]
	if renderer.get("_canopy_readability")!=null: report[id]["readability"]=renderer.get("_canopy_readability").debug_status()
	report[id]["softGround"]={"patches":renderer.get("_soft_ground_patches"),"vertices":renderer.get("_soft_ground_vertices")}
	report[id]["sceneBuildMs"]=build_ms.get(renderer.area,0)
	if renderer.get("_canopy_readability")!=null:
		for active in renderer.get("_canopy_readability").debug_status().active:
			assert(float(active.amount)>.999,"Capture must settle deterministic fade before visual comparison")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1440,810)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	state.surface={"area":"forest","x":200,"y":1320}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.visual_minutes=600
	clock.elapsed_seconds=0
	clock.reduced_motion=true
	clock.clock_paused=true
	root.get_node("RenderQuality").set_profile("balanced",false)
	var forest: Node2D=load("res://scripts/Forest.gd").new()
	var started:=Time.get_ticks_usec()
	root.add_child(forest)
	build_ms["forest"]=float(Time.get_ticks_usec()-started)/1000.0
	forest.set_process(false)
	forest.set_physics_process(false)
	forest.avatar.set_physics_process(false)
	forest.avatar.swim_sprite.set_appearance("male_nusantara")
	forest.avatar.swim_sprite.set_outfit("explorer")
	forest.avatar.swim_sprite.set_equipment(forest.avatar.equipment)
	forest.avatar.swim_sprite.set_locomotion(Vector2.ZERO,0)
	forest.avatar.swim_sprite.animate(false,false,1,0)
	clock.visual_minutes=600
	forest.camera.position_smoothing_enabled=false
	for placement in [{"id":"entry","at":Vector2(200,1320)},{"id":"gateway","at":Vector2(350,1250)},{"id":"canopy","at":Vector2(650,1050)},{"id":"bridge","at":Vector2(1290,660)}]:
		forest.avatar.position=placement.at
		forest.camera.reset_smoothing()
		forest.camera.force_update_scroll()
		await capture(placement.id,forest.land_renderer)
		if placement.id in ["entry","gateway"]:
			for leaf in forest.land_renderer.get("_leaves"): leaf.node.visible=false
			await capture(placement.id+"-without-canopies",forest.land_renderer)
			for leaf in forest.land_renderer.get("_leaves"): leaf.node.visible=true
	if acceptance:
		forest.avatar.position=Vector2(350,1250)
		forest.camera.force_update_scroll()
		for quality in ["low","balanced"]:
			root.get_node("RenderQuality").set_profile(quality,false)
			for condition in [{"id":"day","minute":600,"rain":false},{"id":"night","minute":1200,"rain":false},{"id":"rain","minute":600,"rain":true}]:
				clock.authoritative=true
				clock.visual_minutes=condition.minute
				clock.set("_server_rain",condition.rain)
				clock.set("_rain_amount",.55 if condition.rain else 0)
				clock._process(0)
				for direction in range(8):
					forest.avatar.swim_sprite.set_locomotion(Vector2.RIGHT.rotated(direction*PI*.25)*100,.02)
					forest.avatar.swim_sprite.set_locomotion(Vector2.ZERO,.02)
					forest.avatar.swim_sprite.animate(false,false,1,0)
					await capture("gateway-%s-%s-%d"%[quality,condition.id,direction],forest.land_renderer)
		clock.authoritative=false
		clock.visual_minutes=600
		clock.elapsed_seconds=0
		clock.reduced_motion=false
		clock._process(0)
		root.get_node("RenderQuality").set_profile("balanced",false)
		forest.land_renderer.set_process(false)
		var frame_index:=0
		var motion_dir:=output+"/motion"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(motion_dir))
		forest.avatar.position=Vector2(200,1320)
		for target in [Vector2(350,1250),Vector2(480,1210),Vector2(650,1050),Vector2(930,950)]:
			while forest.avatar.position.distance_to(target)>.1:
				var previous: Vector2=forest.avatar.position
				forest.avatar.position=previous.move_toward(target,100.0/30.0)
				assert(forest.land_collision.is_walkable(forest.avatar.position),"Recorded path must stay on the real collision floor")
				forest.avatar.swim_sprite.set_locomotion((forest.avatar.position-previous)*30.0,1.0/30.0)
				forest.avatar.swim_sprite.animate(true,false,1,0)
				forest.camera.force_update_scroll()
				forest.land_renderer._process(1.0/30.0)
				await process_frame
				await RenderingServer.frame_post_draw
				forest.land_renderer.viewport_3d.get_texture().get_image().save_png(motion_dir+"/%04d.png"%frame_index)
				frame_index+=1
		print("FOREST MOTION FRAMES: ",frame_index," fixed30Hz, actual collision route,100worldpx/s")
		forest.land_renderer.set_process(true)
		clock.reduced_motion=true
	forest.free()
	var stage:=Node2D.new()
	root.add_child(stage)
	var player: Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.animate(false,false,1,0)
	player.visible=false
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.88,.88)
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	started=Time.get_ticks_usec()
	renderer.setup(stage,player,camera,"hub")
	build_ms["hub"]=float(Time.get_ticks_usec()-started)/1000.0
	for placement in [{"id":"village-grass-edge","at":Vector2(1310,1100)},{"id":"village-gateway","at":Vector2(2290,130)}]:
		player.position=placement.at
		camera.position=placement.at
		camera.force_update_scroll()
		await capture(placement.id,renderer)
	stage.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FOREST READABILITY RENDER: ",report.keys())
	quit()
