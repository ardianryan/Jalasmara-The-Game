extends SceneTree

var output := "res://../artifacts/godot/moodboard-daylight-boundary"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	state.surface={"area":"hub","x":1370.0,"y":835.0}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	clock.reduced_motion=true
	root.get_node("RenderQuality").set_profile("sharp",false)
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Node2D.new()
	actor.position=Vector2(1370,835)
	scene.add_child(actor)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.75,.75)
	scene.add_child(camera)
	var report: Dictionary={}
	for size in [Vector2i(844,390),Vector2i(667,375)]:
		root.size=size
		for phase in [{"id":"dawn","minutes":[330.0,360.0,390.0,420.0,450.0]},{"id":"dusk","minutes":[990.0,1020.0,1050.0,1080.0,1110.0]}]:
			clock.visual_minutes=float(phase.minutes[0])
			var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
			scene.add_child(renderer)
			renderer.setup(scene,actor,camera,"hub")
			renderer.set_process(false)
			for minute in phase.minutes:
				clock.visual_minutes=float(minute)
				var weather: Dictionary=clock.snapshot()
				renderer._update_lighting(2.0,weather)
				renderer._process(0.0)
				for frame in range(3): await process_frame
				RenderingServer.force_draw()
				var id: String="%sx%s-%s-%04d"%[size.x,size.y,phase.id,int(minute)]
				root.get_texture().get_image().save_png(output+"/"+id+".png")
				report[id]={"minuteOfDay":minute,"phase":weather.phase,"daylight":weather.daylight,"sunEnergy":renderer.sunlight.light_energy,"sunColor":renderer.sunlight.light_color.to_html(),"ambientEnergy":renderer.environment.ambient_light_energy,"ambientColor":renderer.environment.ambient_light_color.to_html(),"shadowOpacity":renderer.sunlight.shadow_opacity,"shadowEnabled":renderer.sunlight.shadow_enabled}
			renderer.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MOODBOARD DAYLIGHT BOUNDARY RENDER PASS: 20 actual-size dawn/dusk captures")
	scene.free()
	quit()
