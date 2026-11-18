extends SceneTree

const Pollution = preload("res://scripts/hybrid/PollutionUnderwater.gd")
const TILT := deg_to_rad(12.0)
const DISTANCE := 2200.0

var output := "res://../artifacts/godot/pollution-valve-camera"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	call_deferred("run")

func _capture(path: String) -> Image:
	for frame in range(4):
		await process_frame
		RenderingServer.force_draw(false)
	var image: Image = root.get_texture().get_image()
	image.save_png(path)
	return image

func _count_purple(image: Image) -> int:
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color := image.get_pixel(x, y)
			if color.r > color.g * 1.3 and color.b > color.g * 1.3 and color.r > 0.24 and color.b > 0.27:
				count += 1
	return count

func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state := root.get_node("GameState")
	state.player = {"progress": {"day": 3, "stage": "boss", "bossDefeated": false}}
	state.adventure = {"discoveries": [], "puzzles": []}
	state.dive = {"id": "valve-proof", "mode": "boss", "hits": 0, "oxygen": 77, "loot": [], "targets": []}
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(3, "boss")
	clock.visual_minutes = 600
	clock.elapsed_seconds = 0
	clock.reduced_motion = false
	clock.clock_paused = false
	var world := {"landmarks": [{"id": "corporate_pipe", "x": 4420, "y": 2520}], "puzzles": [{"id": "valve", "x": 4650, "y": 2630}]}
	var viewport := SubViewport.new()
	viewport.size = Vector2i(480, 270)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("092f3a")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("87b5b3")
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = environment
	viewport.add_child(atmosphere)
	var sunlight := DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-24, -25, -12)
	sunlight.light_color = Color("f0eee1")
	sunlight.light_energy = 1.35
	sunlight.shadow_enabled = false
	viewport.add_child(sunlight)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.near = 5
	camera.far = 4500
	camera.current = true
	viewport.add_child(camera)
	var world_root := Node3D.new()
	world_root.scale.y = 1.0 / cos(TILT)
	viewport.add_child(world_root)
	# Match OceanActors._mirror_props: atlas cell 1, valve visual offset, size, depth and filtering.
	var atlas: Texture2D = load("res://resources/art/ocean-props-atlas.png")
	var cell := atlas.get_size() / Vector2(4, 2)
	var valve_frame := AtlasTexture.new()
	valve_frame.atlas = atlas
	valve_frame.region = Rect2(Vector2(cell.x, 0), cell)
	valve_frame.filter_clip = true
	var valve := Sprite3D.new()
	valve.texture = valve_frame
	valve.pixel_size = 1.0
	valve.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	valve.shaded = true
	valve.transparent = true
	valve.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	valve.alpha_scissor_threshold = 0.5
	valve.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	valve.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	valve.position = Vector3(4650, -(2630 + 82), 10)
	valve.scale = Vector3(140.0 / cell.x, 135.0 / cell.y, 1)
	world_root.add_child(valve)
	var plume := Pollution.new()
	world_root.add_child(plume)
	plume.configure(world)
	var focus := Vector2(4660, 2630)
	plume.set_focus(focus)
	var center := Vector3(focus.x, -focus.y / cos(TILT), 0)
	camera.position = center + Vector3(0, sin(TILT) * DISTANCE, cos(TILT) * DISTANCE)
	camera.look_at(center, Vector3.UP)
	var display := TextureRect.new()
	display.texture = viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(display)
	for size in [Vector2i(667, 375), Vector2i(844, 390)]:
		root.size = size
		display.size = Vector2(size)
		camera.size = float(size.y)
		plume._process(1.0)
		assert(plume.debug_status().visibleBubbles == 12)
		var before := await _capture(output + "/before-%dx%d.png" % [size.x, size.y])
		assert(_count_purple(before) > 200, "Valve plume must remain visible at actual display size")
		state.player.progress.bossDefeated = true
		plume._process(1.0)
		plume._process(1.0)
		assert(plume.debug_status().visibleBubbles == 0)
		var after := await _capture(output + "/after-%dx%d.png" % [size.x, size.y])
		assert(_count_purple(after) == 0, "Victory must clear all purple source bubbles")
		print("VALVE CAMERA %dx%d: before=%d after=%d" % [size.x, size.y, _count_purple(before), _count_purple(after)])
		state.player.progress.bossDefeated = false
		plume._process(1.0)
	quit()
