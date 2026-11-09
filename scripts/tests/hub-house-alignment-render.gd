extends SceneTree

var output:="res://../artifacts/godot/06b-house-alignment"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1440,810)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	var old_map: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../apps/api/test/fixtures/hub-layout9.json"))
	assert(old_map.layoutVersion==9 and state.world.landMaps.hub.layoutVersion==10)
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=true
	clock.authoritative=true
	clock.reduced_motion=true
	root.get_node("RenderQuality").set_profile("balanced",false)
	var reports: Array=[]
	for layout in [{"id":"before9","map":old_map},{"id":"after10","map":state.world.landMaps.hub}]:
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
		camera.zoom=Vector2.ONE
		stage.add_child(camera)
		var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
		stage.add_child(renderer)
		renderer.setup(stage,player,camera,"hub",layout.map)
		renderer.set_process(false)
		var collision: Node2D=load("res://scripts/land/LandCollision.gd").new()
		stage.add_child(collision)
		collision.configure(layout.map)
		for house in old_map.obstacles:
			if str(house.kind)!="house" or str(house.id)=="griya_sasmita": continue
			# Fixed comparison coordinates derived from the frozen old layout, identical in both frames.
			player.position=Vector2(float(house.x)+float(house.width)*.5,float(house.y)+float(house.height)+55)
			assert(collision.is_walkable(player.position),"Comparison marker must stand on a real clear floor in both layouts")
			for setting in [{"id":"day","minute":600},{"id":"night","minute":1200}]:
				clock.visual_minutes=setting.minute
				clock.set("_server_rain",false)
				clock.set("_rain_amount",0)
				clock._process(0)
				renderer._update_view(0,true)
				renderer._process(.5)
				for frame in range(6): await process_frame
				await RenderingServer.frame_post_draw
				var status: Dictionary=renderer.debug_status()
				assert(status.view.azimuth==-45 and status.view.elevation==35 and status.actors.player==1 and status.maxFootError<.01)
				var id: String=str(layout.id)+"-"+str(house.id)+"-"+str(setting.id)
				root.get_texture().get_image().save_png(output+"/"+id+".png")
				reports.append({"id":id,"marker":[player.position.x,player.position.y],"status":status})
		stage.free()
		await process_frame
	assert(reports.size()==28)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("HUB HOUSE ALIGNMENT RENDER PASS:28 component frames,7 unchanged identities,old9/new10,day/night,shared fixed camera markers on real floors; no route/browser acceptance claim")
	quit()
