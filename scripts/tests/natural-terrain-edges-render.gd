extends SceneTree

var output:="res://../artifacts/godot/natural-terrain-edges"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1280,720)
	var state:=root.get_node("GameState")
	root.get_node("CalendarSync").set_process(false)
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var unchanged:=JSON.stringify(state.world)
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	clock.reduced_motion=true
	root.get_node("RenderQuality").set_profile("balanced",false)
	var reports: Array=[]
	var cases:={"hub":[["western-steps",600,835],["central-steps",1370,835],["ridge-steps",1780,470],["lower-coast",1005,995],["corporate-coast",1990,300]],"forest":[["upper-west-bank",1260,660],["upper-east-bank",1660,640],["lower-west-bank",1260,1080],["lower-east-bank",1670,1080]]}
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
		var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
		stage.add_child(collision)
		collision.configure(renderer.map)
		assert(renderer._components.get("NaturalTerrainShoulder",0)>0)
		for entry in cases[area]:
			player.position=Vector2(entry[1],entry[2])
			assert(collision.is_walkable(player.position),str(entry[0])+" marker must stand on an actual reachable floor")
			for setting in [["day",600],["night",1200]]:
				clock.visual_minutes=setting[1]
				clock.set("_server_rain",false)
				clock.set("_rain_amount",0)
				clock._process(0)
				renderer._update_view(0,true)
				renderer._process(.5)
				for frame in range(6): await process_frame
				RenderingServer.force_draw()
				var status: Dictionary=renderer.debug_status()
				assert(status.view.azimuth==-45 and status.view.elevation==35 and status.actors.player==1 and status.maxFootError<.01)
				var id: String=str(area)+"-"+str(entry[0])+"-"+str(setting[0])
				root.get_texture().get_image().save_png(output+"/"+id+".png")
				reports.append({"id":id,"marker":[player.position.x,player.position.y],"status":status})
		stage.free()
		await process_frame
	assert(reports.size()==18 and JSON.stringify(state.world)==unchanged)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("NATURAL TERRAIN RENDER PASS:18 actual hub/forest component frames,stairs/coast/both banks,day/night,left3/4,one Nala on existing clear floor; not browser traversal acceptance")
	quit()
