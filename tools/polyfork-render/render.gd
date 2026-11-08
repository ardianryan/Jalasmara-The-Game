extends SceneTree

func _initialize() -> void:
	call_deferred("render_asset")

func render_asset() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: godot --path tools/polyfork-render --script render.gd -- INPUT.glb OUTPUT.png [SIZE=128]")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		printerr("PNG rendering requires a graphics display; omit --headless.")
		quit(1)
		return
	var input := ProjectSettings.globalize_path(args[0])
	var output := ProjectSettings.globalize_path(args[1])
	var pixels := clampi(int(args[2]), 32, 512) if args.size() > 2 else 128
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var error := document.append_from_file(input, state)
	if error != OK:
		printerr("GLB could not be read: ", error)
		quit(1)
		return
	var model := document.generate_scene(state)
	if model == null:
		printerr("GLB did not produce a scene.")
		quit(1)
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(pixels, pixels)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	viewport.add_child(model)
	_prepare_materials(model)
	await process_frame
	var bounds: AABB = _bounds(model)
	if bounds.size.length() < 0.001:
		printerr("The model has no visible mesh bounds.")
		quit(1)
		return
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0,0,0,0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	viewport.add_child(world_environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-30,0)
	light.light_energy = 0.65
	viewport.add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(bounds.size.y, Vector2(bounds.size.x,bounds.size.z).length()) * 1.4
	camera.near = 0.01
	camera.far = bounds.size.length() * 20 + 10
	viewport.add_child(camera)
	var center := bounds.get_center()
	camera.position = center + Vector3(1,1.15,1).normalized() * (bounds.size.length() * 3 + 1)
	camera.look_at(center, Vector3.UP)
	camera.current = true
	for frame in range(4):
		await process_frame
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var alpha_pixels := 0
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x,y)
			if color.a > 0.1:
				alpha_pixels += 1
				image.set_pixel(x,y,color.linear_to_srgb())
	if alpha_pixels < 10 or alpha_pixels >= pixels * pixels:
		printerr("Render is empty or lacks transparency; inspect the graphics backend.")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	error = image.save_png(output)
	if error != OK:
		printerr("PNG could not be saved: ", error)
		quit(1)
		return
	print("Saved ", output, " (", pixels, "x", pixels, "; visible pixels ", alpha_pixels, ")")
	quit()

func _bounds(node: Node) -> AABB:
	var result := AABB()
	var found := false
	if node is MeshInstance3D:
		result = node.global_transform * node.get_aabb()
		found = true
	for child in node.get_children():
		var child_bounds := _bounds(child)
		if child_bounds.size.length() > 0.001:
			result = result.merge(child_bounds) if found else child_bounds
			found = true
	return result

func _prepare_materials(node: Node) -> void:
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count():
			var source: Material = node.get_active_material(surface)
			var material := source.duplicate() as StandardMaterial3D if source is StandardMaterial3D else StandardMaterial3D.new()
			material.vertex_color_use_as_albedo = true
			material.vertex_color_is_srgb = false
			material.albedo_color = Color.WHITE
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			node.set_surface_override_material(surface, material)
	for child in node.get_children():
		_prepare_materials(child)
