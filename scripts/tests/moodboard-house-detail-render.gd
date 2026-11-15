extends SceneTree

var output:="res://../artifacts/godot/moodboard-house-detail"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	print("HOUSE RENDER START")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=true
	clock.authoritative=true
	clock.visual_minutes=600
	clock.set("_server_rain",false)
	clock.set("_rain_amount",0)
	clock._process(0)
	root.get_node("RenderQuality").set_profile("sharp",false)
	var result: Array=[]
	for frame_size in [Vector2i(844,390),Vector2i(667,375)]:
		root.size=frame_size
		for detail in [false,true]:
			print("HOUSE RENDER FRAME ",frame_size," detail=",detail)
			var stage:=Node2D.new()
			root.add_child(stage)
			var player: Node2D=load("res://scripts/Player.gd").new()
			stage.add_child(player)
			player.set_physics_process(false)
			player.visible=false
			player.position=Vector2(160,635)
			var camera:=Camera2D.new()
			camera.zoom=Vector2(.9,.9)
			stage.add_child(camera)
			var renderer: Node2D=load("res://../scripts/tests/fixtures/house-detail-renderer.gd").new()
			renderer.detail_enabled=detail
			stage.add_child(renderer)
			renderer.setup(stage,player,camera,"hub")
			renderer.set_process(false)
			renderer._update_view(0,true)
			renderer._process(.5)
			print("HOUSE RENDER BUILT")
			for frame in range(8): await process_frame
			print("HOUSE RENDER DRAW WAIT")
			await RenderingServer.frame_post_draw
			var label:="after" if detail else "before"
			var size_label:="%dx%d" % [frame_size.x,frame_size.y]
			root.get_texture().get_image().save_png(output+"/griya-"+label+"-"+size_label+".png")
			var status: Dictionary=renderer.debug_status()
			assert(status.view.azimuth==-45 and status.view.elevation==35)
			result.append({"id":label,"size":size_label,"meshes":status.meshes,"houses":status.houses,"components":status.components})
			stage.free()
			await process_frame
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("MOODBOARD HOUSE DETAIL RENDER PASS: matched Griya before/after 844x390 and 667x375")
	quit()
