extends SceneTree

var output := "res://../artifacts/godot/moodboard-foliage-composition"

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
		for place in [{"id":"hub","at":Vector2(325,375)},{"id":"forest","at":Vector2(1290,470)}]:
			actor.position=place.at
			state.surface={"area":place.id,"x":actor.position.x,"y":actor.position.y}
			var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
			scene.add_child(renderer)
			renderer.setup(scene,actor,camera,place.id)
			renderer.set_process(false)
			var changed: Array[Dictionary]=[]
			for leaf in renderer.get("_leaves"):
				var sprite: Sprite3D=leaf.node as Sprite3D
				if sprite==null or sprite.pixel_size<.1: continue
				var frame:=sprite.texture as AtlasTexture
				if frame==null or frame.region.position!=Vector2(512,512): continue
				var baseline:=AtlasTexture.new()
				baseline.atlas=frame.atlas
				baseline.region=Rect2(Vector2.ZERO,frame.region.size)
				baseline.filter_clip=true
				changed.append({"sprite":sprite,"candidate":frame,"baseline":baseline,"pixel":sprite.pixel_size,"modulate":sprite.modulate})
			assert(not changed.is_empty(),"Composition proof needs a changed canopy in view")
			for condition in [{"id":"day","minute":720.0},{"id":"dusk","minute":1050.0}]:
				clock.visual_minutes=condition.minute
				clock.set("_presented_minutes",condition.minute)
				clock.set("_presented_daylight",clock.daylight_for_minutes(condition.minute))
				clock._process(0)
				renderer._process(.5)
				renderer._update_lighting(2.0,clock.snapshot())
				for variant in ["baseline","candidate"]:
					for entry in changed:
						var sprite: Sprite3D=entry.sprite
						sprite.texture=entry.baseline if variant=="baseline" else entry.candidate
						sprite.pixel_size=entry.pixel/.92 if variant=="baseline" else entry.pixel
						sprite.modulate=Color.WHITE if variant=="baseline" else entry.modulate
					for frame_index in range(4): await process_frame
					RenderingServer.force_draw()
					var id: String="%sx%s-%s-%s-%s"%[size.x,size.y,place.id,condition.id,variant]
					root.get_texture().get_image().save_png(output+"/"+id+".png")
					report[id]={"changedCanopies":changed.size(),"renderSize":renderer.viewport_3d.size}
			renderer.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("FOLIAGE COMPOSITION RENDER PASS: 16 matched actual-size frames; visual review required")
	scene.free()
	quit()
