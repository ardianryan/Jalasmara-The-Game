extends SceneTree

var output:="res://../artifacts/godot/06b-left-runtime"
var report:Dictionary={}
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
	var before:=JSON.stringify(state.world)
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	clock.authoritative=true
	clock.visual_minutes=600
	clock.reduced_motion=false
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
	camera.zoom=Vector2(1.15,1.15)
	stage.add_child(camera)
	var workers: Dictionary={}
	for name in ["Mang Ujang","Bu Darmi","Yu Sari"]:
		var profile: Dictionary={}
		if name=="Bu Darmi": profile=state.world.surface_hub.districtActivities[name].duplicate(true)
		else:
			for resident in state.world.surface_hub.residents:
				if resident.name==name: profile=resident.duplicate(true)
		profile["name"]=name
		var person: Node2D=load("res://scripts/HubActor.gd").new()
		person.actor_name=name
		person.position=Vector2(profile.activity.work[0],profile.activity.work[1])
		person.set_meta("land_hidden",true)
		stage.add_child(person)
		workers[name]=person
		person.configure_activity(profile)
		person.set_process(false)
		person._process(3)
		person._process(2.3)
	clock.clock_paused=true
	var renderer:Node2D=load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	for setting in [
		{"id":"griya-day-balanced","area":"hub","at":Vector2(160,615),"quality":"balanced","minute":600},
		{"id":"griya-night-balanced","area":"hub","at":Vector2(160,615),"quality":"balanced","minute":1200},
		{"id":"griya-day-low","area":"hub","at":Vector2(265,700),"quality":"low","minute":600},
		{"id":"hub-water-edge","area":"hub","at":Vector2(900,1360),"quality":"balanced","minute":600},
		{"id":"ujang-work","focus":"Mang Ujang","area":"hub","at":Vector2(980,1370),"quality":"balanced","minute":600,"zoom":2.4},
		{"id":"darmi-work","focus":"Bu Darmi","area":"hub","at":Vector2(1800,610),"quality":"balanced","minute":600,"zoom":2.4},
		{"id":"sari-work","focus":"Yu Sari","area":"hub","at":Vector2(840,740),"quality":"balanced","minute":600,"zoom":2.4},
		{"id":"forest-gateway","area":"forest","at":Vector2(350,1250),"quality":"balanced","minute":600},
		{"id":"forest-bridge","area":"forest","at":Vector2(1450,650),"quality":"balanced","minute":600},
	]:
		root.get_node("RenderQuality").set_profile(setting.quality,false)
		clock.visual_minutes=setting.minute
		clock.set("_server_rain",false)
		clock.set("_rain_amount",0)
		clock._process(0)
		camera.zoom=Vector2.ONE*float(setting.get("zoom",1.15))
		player.position=setting.at
		renderer.actor=workers[setting.focus] if setting.has("focus") else player
		if renderer.area!=setting.area: renderer.set_area(setting.area)
		renderer._update_view(0,true)
		renderer._process(.5)
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/"+setting.id+".png")
		report[setting.id]=renderer.debug_status()
		assert(report[setting.id].view.azimuth==-45 and report[setting.id].maxFootError<.01 and report[setting.id].actors.player==1)
	assert(JSON.stringify(state.world)==before)
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LAND LEFT RUNTIME RENDER PASS: ",report.size()," actual default-camera renderer frames; Griya day/night/low, coast backing, forest gateway and bridge; no static pilot pose override or global gameplay acceptance claim")
	stage.free()
	quit()
