extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(480,270)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	root.add_child(viewport)
	var world_root := Node3D.new()
	world_root.scale.y = 1.0/cos(deg_to_rad(12.0))
	viewport.add_child(world_root)
	var geometry = load("res://scripts/hybrid/TerrainGeometry.gd").new()
	world_root.add_child(geometry)
	geometry.configure(JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/hybrid-world.json")))
	assert(geometry.layered_band_count > 400)
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("174650")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("a7c1b7")
	settings.ambient_light_energy = 0.85
	environment.environment = settings
	viewport.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-28,-32,0)
	light.light_color = Color("f8e4bc")
	light.light_energy = 1.65
	viewport.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1550
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.far = 15000
	var center := Vector3(1050,-880/cos(deg_to_rad(12.0)),0)
	camera.position = center+Vector3(0,sin(deg_to_rad(12.0))*5000,cos(deg_to_rad(12.0))*5000)
	viewport.add_child(camera)
	camera.look_at(center)
	camera.current = true
	for frame in range(6): await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	image.save_png("res://../assets/source-3d/terrain-layers-gpu.png")
	print("LAYERED TERRAIN GPU PASS ",geometry.debug_status())
	quit()
