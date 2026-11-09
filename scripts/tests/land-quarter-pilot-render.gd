extends SceneTree

const CameraPose = preload("res://scripts/land/LandCameraPose.gd")
var output:="res://../artifacts/godot/06b-quarter-pilot"
var results: Dictionary={}

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func capture(id: String, renderer: Node, pose: Transform3D, snapped: bool, angles: Vector2) -> void:
	renderer.pilot_active=false
	renderer._process(.5)
	renderer.pilot_pose=pose
	renderer.pilot_active=true
	renderer.camera_3d.transform=pose
	renderer.camera_3d.size=640.0
	renderer.actors_3d.update_actors(0)
	if "_shelter_architecture" in renderer:
		renderer._shelter_architecture.update(renderer,.5)
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(renderer.debug_status().actors.player==1,"A pilot capture requires a live rendered player")
	var texture: Image=renderer.viewport_3d.get_texture().get_image()
	texture.save_png(output+"/"+id+".png")
	var expected_feet: Vector3=renderer.map_point(renderer.actor.position,renderer.ground_height(renderer.actor.position))
	var actual: Sprite3D=renderer.actors_3d.sprites.Nala
	var pivot: Vector2=renderer.actor.swim_sprite.get_land_pivot()
	var dimensions:=actual.texture.get_size()*Vector2(actual.scale.x,actual.scale.y)
	var rise: float=(pivot.y/actual.texture.get_height()-.5)*dimensions.y
	var visible_sole: Vector3=actual.global_position-renderer.camera_up()*rise
	var foot_error: float=renderer.camera_3d.unproject_position(visible_sole).distance_to(renderer.camera_3d.unproject_position(expected_feet))
	assert(foot_error<.01,"Calibrated static billboard foot must project onto its actual floor")
	results[id]={"angles":[angles.x,angles.y],"pixelSnapped":snapped,"player":[renderer.actor.position.x,renderer.actor.position.y],"footErrorPx":foot_error,"renderer":renderer.debug_status(),"cameraBasis":[str(pose.basis.x),str(pose.basis.y),str(pose.basis.z)],"weather":root.get_node("EnvironmentState").snapshot(),"scope":"static actual-mesh projection pilot; no gameplay input, live route, HUD or global camera acceptance"}

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1440,810)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var before:=JSON.stringify(state.world)
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.reduced_motion=true
	clock.clock_paused=true
	var stage:=Node2D.new()
	root.add_child(stage)
	var player: Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.position=Vector2(160,620)
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.set_locomotion(Vector2.ZERO,0)
	player.swim_sprite.animate(false,false,1,0)
	player.visible=false
	var camera:=Camera2D.new()
	camera.position=Vector2(160,560)
	stage.add_child(camera)
	camera.force_update_scroll()
	var renderer: Node2D=load("res://../scripts/tests/LandQuarterPilotRenderer.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	var target: Vector3=renderer.map_point(Vector2(160,540),96)+Vector3(0,0,20)
	for quality in ["low","balanced"]:
		root.get_node("RenderQuality").set_profile(quality,false)
		for condition in [{"id":"day","minute":600,"rain":false},{"id":"night","minute":1200,"rain":false},{"id":"rain","minute":600,"rain":true}]:
			clock.visual_minutes=condition.minute
			clock.set("_server_rain",condition.rain)
			clock.set("_rain_amount",.55 if condition.rain else 0)
			clock._process(0)
			for setting in [{"id":"legacy-35","angles":Vector2(0,35),"snap":false},{"id":"quarter-left-minus45-30","angles":Vector2(-45,30),"snap":true},{"id":"isometric-left-minus45-35","angles":Vector2(-45,35.26438968),"snap":true}]:
				var pose:=CameraPose.pose(target,setting.angles.x,setting.angles.y,3300,640,renderer.viewport_3d.size.y,setting.snap)
				await capture("%s-%s-%s"%[quality,condition.id,setting.id],renderer,pose,setting.snap,setting.angles)
	assert(JSON.stringify(state.world)==before,"Camera pilot cannot mutate authoritative geometry")
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(results,"  "))
	print("LAND QUARTER PILOT RENDER PASS: ",results.size()," real mesh frames, calibrated static player, no global camera/input claim")
	stage.free()
	quit()
