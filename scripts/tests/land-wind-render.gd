extends SceneTree

var output := "res://../artifacts/godot/land-wind-review"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	_run.call_deferred()

func _pose(renderer: Node2D, seconds: float, wind_x: float, reduced: bool) -> void:
	var motion=load("res://scripts/FoliageMotion.gd")
	for material_id in ["wind_leaves","wind_flower"]:
		var material: ShaderMaterial=renderer._materials.get_material(material_id)
		material.set_shader_parameter("wind_time",seconds)
		material.set_shader_parameter("wind_x",wind_x)
		material.set_shader_parameter("wind_reduced",reduced)
	for leaf in renderer.get("_leaves"):
		var home: Vector3=leaf.home
		var drift: float=0.0 if reduced else motion.land_offset(seconds,Vector2(home.x,home.y),wind_x,float(leaf.pixel),float(leaf.size))
		leaf.node.position=home+Vector3(drift,0,0)

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
	clock.visual_minutes=720.0
	clock.set("_presented_minutes",720.0)
	clock.set("_presented_daylight",clock.daylight_for_minutes(720.0))
	clock._process(0)
	root.get_node("RenderQuality").set_profile("sharp",false)
	var scene:=Node2D.new()
	root.add_child(scene)
	var actor:=Node2D.new()
	scene.add_child(actor)
	var camera:=Camera2D.new()
	camera.zoom=Vector2(.75,.75)
	scene.add_child(camera)
	var proof: Dictionary={}
	for size in [Vector2i(667,375),Vector2i(844,390)]:
		root.size=size
		for place in [{"id":"hub","at":Vector2(1775,515)},{"id":"forest","at":Vector2(1290,470)}]:
			actor.position=place.at
			state.surface={"area":place.id,"x":actor.position.x,"y":actor.position.y}
			var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
			scene.add_child(renderer)
			renderer.setup(scene,actor,camera,place.id)
			renderer.set_process(false)
			renderer._process(.5)
			renderer._update_lighting(2.0,clock.snapshot())
			var fern_count:=0
			for leaf in renderer.get("_leaves"):
				var sprite: Sprite3D=leaf.node as Sprite3D
				if sprite!=null and sprite.texture!=null and sprite.texture.resource_path.ends_with("fern-plant.png"): fern_count+=1
			assert(fern_count>0,"Surface ferns must be registered for wind motion")
			var rendered:=0
			for variant in [{"id":"still","time":0.0,"wind":0.0,"reduced":true},{"id":"right","time":6.8,"wind":22.0,"reduced":false},{"id":"left","time":6.8,"wind":-22.0,"reduced":false}]:
				_pose(renderer,variant.time,variant.wind,variant.reduced)
				for frame in range(4): await process_frame
				RenderingServer.force_draw()
				var name: String="%sx%s-%s-%s"%[size.x,size.y,place.id,variant.id]
				root.get_texture().get_image().save_png(output+"/"+name+".png")
				rendered+=1
			proof["%sx%s-%s"%[size.x,size.y,place.id]]={"ferns":fern_count,"leaves":renderer.get("_leaves").size(),"frames":rendered,"viewport":renderer.viewport_3d.size}
			renderer.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(proof,"  "))
	print("LAND WIND RENDER PASS: 12 paired frames; visual review required")
	scene.free()
	quit()
