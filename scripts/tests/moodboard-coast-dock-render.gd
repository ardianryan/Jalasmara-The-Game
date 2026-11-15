extends SceneTree

var output := "res://../artifacts/godot/moodboard-coast-dock"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(844,390)
	var state := root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"appearance":"male_nusantara","coins":200,"inventory":[],"progress":{"day":2,"stage":"dive","tutorial":true}}
	state.dive = {}
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused = true
	clock.authoritative = true
	clock.visual_minutes = 600
	clock.set("_server_rain",false)
	clock.set("_rain_amount",0)
	clock._process(0)
	var stage := Node2D.new()
	root.add_child(stage)
	var player: Node2D = load("res://scripts/Player.gd").new()
	stage.add_child(player)
	player.set_physics_process(false)
	player.visible = false
	player.position = Vector2(900,1360)
	var camera := Camera2D.new()
	camera.zoom = Vector2(1.15,1.15)
	stage.add_child(camera)
	var renderer: Node2D = load("res://scripts/land/LandWorld3D.gd").new()
	stage.add_child(renderer)
	renderer.setup(stage,player,camera,"hub")
	renderer.set_process(false)
	renderer._update_view(0,true)
	renderer._process(0.5)
	for frame in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output+"/dock-844x390.png")
	var materials = load("res://scripts/land/LandMaterials.gd").new()
	var dock_material: ShaderMaterial = materials.get_material("dock")
	var report := {"renderer":renderer.debug_status(),"dockMaterialKind":dock_material.get_shader_parameter("kind"),"viewport":[844,390]}
	assert(report.dockMaterialKind == 11,"Hub dock must use the isolated authored pixel material")
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MOODBOARD COAST DOCK RENDER PASS")
	stage.free()
	quit()
