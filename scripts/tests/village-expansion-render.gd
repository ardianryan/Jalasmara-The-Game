extends SceneTree

var output:="res://../artifacts/godot/overnight-village"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(1440,810)
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","coins":321,"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive={}
	state.homestead={"plots":[{"id":"plot_1","cropId":"kangkung","stage":"mature"},{"id":"plot_2","cropId":"jahe","stage":"mature"}],"fishPen":{"breeders":2,"offspring":3}}
	var clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=true
	clock.authoritative=true
	clock.reduced_motion=true
	root.get_node("RenderQuality").set_profile("balanced",false)
	var stage:=Node2D.new()
	root.add_child(stage)
	var player:Node2D=load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.visible=false
	player.swim_sprite.set_appearance("male_nusantara")
	player.swim_sprite.set_outfit("daily")
	player.swim_sprite.animate(false,false,1,0)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.5,.5)
	stage.add_child(camera)
	var renderer:Node2D=load("res://../scripts/tests/fixtures/house-framing-renderer.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	var collision:Node2D=load("res://scripts/land/LandCollision.gd").new()
	stage.add_child(collision)
	collision.configure(state.world.landMaps.hub)
	var reports:Array=[]
	for sample in [{"id":"lurah-private","house":"rumah_lurah","at":Vector2(192.5,310)},{"id":"director-rv","house":"rumah_direktur","at":Vector2(1770,240)},{"id":"garden-fishpen","house":"","at":Vector2(275,850)}]:
		player.position=sample.at
		assert(collision.is_walkable(player.position),"Review marker must stand on the real legal entrance/aisle")
		for setting in [{"id":"day","minute":600},{"id":"night","minute":1200}]:
			clock.visual_minutes=setting.minute
			clock.set("_server_rain",false)
			clock.set("_rain_amount",0)
			clock._process(0)
			renderer._update_view(0,true)
			renderer._process(.5)
			for frame in range(6): await process_frame
			RenderingServer.force_draw()
			var status:Dictionary=renderer.debug_status()
			assert(status.view.azimuth==-45 and status.view.elevation==35 and status.actors.player==1 and status.maxFootError<.01)
			var framing:=Rect2(Vector2(8,8),Vector2(renderer.viewport_3d.size)-Vector2(16,16))
			var points:Array=[]
			if not str(sample.house).is_empty():
				points=renderer.house_bounds[sample.house].duplicate()
				for shelter in state.world.landMaps.hub.shelters:
					if str(shelter.get("buildingId",""))==str(sample.house): points.append_array(renderer._shelter_architecture.roofs[shelter.id])
			else:
				var center:Vector3=renderer._fish_pen._center
				for corner in [Vector3(-36,-28,-26),Vector3(36,28,6)]: points.append(center+corner)
			for at:Vector3 in points: assert(framing.has_point(renderer.camera_3d.unproject_position(at)),sample.id+" actual geometry must fit in the frame")
			var id:String=str(sample.id)+"-"+str(setting.id)
			root.get_texture().get_image().save_png(output+"/"+id+".png")
			reports.append({"id":id,"position":[player.position.x,player.position.y],"status":status})
	stage.free()
	await process_frame
	assert(reports.size()==6)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	print("VILLAGE EXPANSION RENDER PASS:6 actual day/night component frames; Lurah/RV house+roof bounds inside canvas, legal entrances, garden and live fish pen; new NPC bodies/UI/browser not exercised")
	quit()
