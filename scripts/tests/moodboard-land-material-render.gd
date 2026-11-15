extends SceneTree

var output := "res://../artifacts/godot/moodboard-land-material"
var baseline_shader_path := "res://../.runtime/moodboard-land-baseline-shader.txt"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
		if argument.begins_with("--baseline-shader="): baseline_shader_path=argument.trim_prefix("--baseline-shader=")
	_run.call_deferred()

func _run() -> void:
	assert(FileAccess.file_exists(baseline_shader_path), "Missing source-pinned baseline shader")
	var baseline:=Shader.new()
	baseline.code=FileAccess.get_file_as_string(baseline_shader_path)
	var baseline_grade: Shader=load("res://shaders/ComfyGrade.gdshader")
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
	for size in [Vector2i(844,390),Vector2i(667,375)]:
		root.size=size
		for place in [{"id":"hub","at":Vector2(1370,835)},{"id":"forest","at":Vector2(350,1250)}]:
			actor.position=place.at
			state.surface={"area":place.id,"x":actor.position.x,"y":actor.position.y}
			var renderer: Node2D=load("res://scripts/land/LandWorld3D.gd").new()
			scene.add_child(renderer)
			renderer.setup(scene,actor,camera,place.id)
			renderer.set_process(false)
			var candidate_shader: Shader=renderer._materials._shader
			var materials: Dictionary=renderer._materials._cache
			var original_parameters: Dictionary={}
			for key in materials:
				var saved: Dictionary={}
				for uniform in candidate_shader.get_shader_uniform_list():
					var name: String=uniform.name
					var value: Variant=materials[key].get_shader_parameter(name)
					if value!=null: saved[name]=value
				original_parameters[key]=saved
			var baseline_colors: Dictionary={"dirt":"a68762","grass":"72995b","stone":"a8b5aa"}
			for condition in [{"id":"day","minute":720.0},{"id":"dusk","minute":1050.0},{"id":"night","minute":1200.0}]:
				clock.visual_minutes=condition.minute
				clock._process(0)
				renderer._process(.5)
				# Capture the intended clock keyframe, not the first transition frame from the previous keyframe.
				renderer._update_lighting(2.0,clock.snapshot())
				for variant in ["baseline","candidate"]:
					renderer._grade_material.shader=baseline_grade if variant=="baseline" else load("res://shaders/LandComfyGrade.gdshader")
					renderer._grade_material.set_shader_parameter("strength",.6 if variant=="baseline" else .75)
					renderer._grade_material.set_shader_parameter("daylight",renderer._lighting_display.daylight)
					for key in materials:
						var material: ShaderMaterial=materials[key]
						material.shader=baseline if variant=="baseline" else candidate_shader
						for name in original_parameters[key]: material.set_shader_parameter(name,original_parameters[key][name])
						var name: String=str(key).trim_prefix("edge_")
						if baseline_colors.has(name):
							material.set_shader_parameter("base_color",Color(str(baseline_colors[name])) if variant=="baseline" else Color({"dirt":"b18a5e","grass":"80a963","stone":"afb9ac"}[name]))
					for frame in range(4): await process_frame
					RenderingServer.force_draw()
					var id: String="%sx%s-%s-%s-%s"%[size.x,size.y,place.id,condition.id,variant]
					root.get_texture().get_image().save_png(output+"/"+id+".png")
					report[id]={"shader":FileAccess.get_sha256(baseline_shader_path) if variant=="baseline" else "candidate-runtime","materialCount":materials.size(),"renderSize":renderer.viewport_3d.size,"sunEnergy":renderer.sunlight.light_energy,"ambientEnergy":renderer.environment.ambient_light_energy}
			renderer.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MOODBOARD LAND MATERIAL RENDER PASS: 24 paired 844x390/667x375 captures; visual review required")
	scene.free()
	quit()
