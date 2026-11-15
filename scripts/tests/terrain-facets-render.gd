extends SceneTree

var output:="res://../artifacts/godot/terrain-facets"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state:=root.get_node("GameState")
	root.get_node("CalendarSync").set_process(false)
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	clock.reduced_motion=true
	clock.visual_minutes=600
	clock.set("_server_rain",false)
	clock.set("_rain_amount",0)
	clock._process(0)
	root.get_node("RenderQuality").set_profile("sharp",false)
	var cases:={"hub":[["central-stairs",1370,835],["lower-coast",1005,995]],"forest":[["upper-west-bank",1260,660]]}
	var reports: Array=[]
	for area in cases:
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
		renderer.setup(stage,player,camera,area)
		renderer.set_process(false)
		for entry in cases[area]:
			player.position=Vector2(entry[1],entry[2])
			for size in [Vector2i(844,390),Vector2i(667,375)]:
				root.size=size
				renderer._update_view(0,true)
				renderer._process(.5)
				for frame in range(6): await process_frame
				RenderingServer.force_draw()
				var status: Dictionary=renderer.debug_status()
				assert(status.actors.player==1 and status.maxFootError<.01)
				var id: String=str(area)+"-"+str(entry[0])+"-"+str(size.x)+"x"+str(size.y)
				root.get_texture().get_image().save_png(output+"/"+id+".png")
				reports.append({"id":id,"status":status})
		stage.free()
		await process_frame
	assert(reports.size()==6)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("TERRAIN FACETS RENDER PASS: six hub/forest actual-world day frames at 844x390 and 667x375")
	quit()
