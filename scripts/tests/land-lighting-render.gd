extends SceneTree

var output := "res://../artifacts/godot/moodboard-light"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	_run.call_deferred()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size=Vector2i(844,390)
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	clock.reduced_motion=true
	root.get_node("RenderQuality").set_profile("sharp",false)
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Node2D.new()
	scene.add_child(actor)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.75,.75)
	scene.add_child(camera)
	var report: Dictionary={}
	for place in [{"id":"hub","at":Vector2(1370,835)},{"id":"forest","at":Vector2(350,1250)}]:
		actor.position=place.at
		state.surface={"area":place.id,"x":actor.position.x,"y":actor.position.y}
		var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
		scene.add_child(renderer)
		renderer.setup(scene,actor,camera,place.id)
		renderer.set_process(false)
		for condition in [{"id":"day","minute":720.0},{"id":"dusk","minute":1050.0},{"id":"night","minute":1200.0}]:
			clock.visual_minutes=condition.minute
			clock._process(0)
			renderer._process(.5)
			for frame in range(4): await process_frame
			RenderingServer.force_draw()
			var id: String=place.id+"-"+condition.id
			root.get_texture().get_image().save_png(output+"/"+id+".png")
			report[id]={"clock":clock.snapshot().clock,"sunColor":renderer.sunlight.light_color.to_html(),"sunEnergy":renderer.sunlight.light_energy,"ambientColor":renderer.environment.ambient_light_color.to_html(),"ambientEnergy":renderer.environment.ambient_light_energy,"renderSize":renderer.viewport_3d.size}
			_apply_previous_lighting(renderer,clock.snapshot(),place.id)
			for frame in range(2): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png(output+"/"+id+"-before.png")
		renderer.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LAND LIGHTING RENDER PASS: six 844x390 same-camera day/dusk/night pairs; visual review required")
	scene.free()
	quit()

func _apply_previous_lighting(renderer: Node2D,weather: Dictionary,place: String) -> void:
	var daylight:=clampf((float(weather.get("daylight",.8))-.24)/.76,0.0,1.0)
	var clouds:=float(weather.get("clouds",0))
	renderer.sunlight.light_energy=lerpf(.035,.72,daylight)*(1.0-clouds*.25)
	renderer.sunlight.light_color=Color("a5c2c0").lerp(Color("fff0d7"),daylight)
	renderer.environment.ambient_light_energy=lerpf(.65,.62,daylight) if place=="home" else lerpf(.50,.62,daylight)
	renderer.environment.ambient_light_color=(Color("9faeae") if place=="home" else Color("71929c")).lerp(Color("b7d4d1"),daylight)
