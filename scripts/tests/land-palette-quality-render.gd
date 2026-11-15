extends SceneTree

var output := "res://../artifacts/godot/land-palette-quality"

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
	for size in [Vector2i(667,375),Vector2i(844,390)]:
		root.size=size
		for place in [{"id":"hub","at":Vector2(1370,835)},{"id":"forest","at":Vector2(350,1250)}]:
			actor.position=place.at
			state.surface={"area":place.id,"x":actor.position.x,"y":actor.position.y}
			var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
			scene.add_child(renderer)
			renderer.setup(scene,actor,camera,place.id)
			renderer.set_process(false)
			for condition in [{"id":"day","minute":600.0},{"id":"dusk","minute":1050.0}]:
				clock.visual_minutes=condition.minute
				clock._presentation_initialized=false
				clock._process(0.0)
				renderer._update_lighting(2.0,clock.snapshot())
				renderer._process(0.0)
				for frame in range(3): await process_frame
				RenderingServer.force_draw()
				var id: String="%sx%s-%s-%s"%[size.x,size.y,place.id,condition.id]
				root.get_texture().get_image().save_png(output+"/"+id+".png")
				report[id]={"sunColor":renderer.sunlight.light_color.to_html(),"ambientColor":renderer.environment.ambient_light_color.to_html(),"dusk":renderer._lighting_display.dusk,"materialCount":renderer._materials._cache.size()}
			renderer.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LAND PALETTE QUALITY RENDER PASS: 8 actual-size day/dusk captures")
	scene.free()
	quit()
