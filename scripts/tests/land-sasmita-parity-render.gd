extends SceneTree

var output := "res://../artifacts/godot/land-sasmita-parity"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	clock.reduced_motion=true
	root.get_node("RenderQuality").set_profile("sharp",false)
	var stage:=Node2D.new()
	root.add_child(stage)
	var player: Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.visible=false
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.75,.75)
	stage.add_child(camera)
	var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	var reports: Array=[]
	for entry in [{"id":"front","at":Vector2(160,615)},{"id":"side","at":Vector2(275,690)}]:
		player.position=entry.at
		for size in [Vector2i(844,390),Vector2i(667,375)]:
			root.size=size
			clock.visual_minutes=600
			clock.set("_server_rain",false)
			clock.set("_rain_amount",0)
			clock._process(0)
			renderer._update_view(0,true)
			renderer._process(.5)
			for frame in range(6): await process_frame
			RenderingServer.force_draw()
			var status: Dictionary=renderer.debug_status()
			assert(status.actors.player==1 and status.maxFootError<.01 and status.components.SasmitaPileFrame==1)
			var id: String="%s-%sx%s"%[entry.id,size.x,size.y]
			root.get_texture().get_image().save_png(output+"/"+id+".png")
			reports.append({"id":id,"status":status,"drawCalls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"renderObjects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"renderPrimitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)})
	assert(reports.size()==4)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("LAND SASMITA PARITY RENDER PASS: four actual-scale hub frames, unchanged floor, one grounded Nala")
	quit()
