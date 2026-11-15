extends SceneTree

class Swimmer extends Node2D:
	var velocity := Vector2.ZERO
	var direction := 1
	var swim_sprite: Sprite2D
	func _ready() -> void:
		swim_sprite = load("res://scripts/CharacterVisual.gd").new()
		add_child(swim_sprite)
		swim_sprite.set_appearance("male_default")
		swim_sprite.set_outfit("diving")
		swim_sprite.animate(false, true, 1, 0)

class Source extends Node2D:
	var camera: Camera2D
	var nala: Swimmer
	var entities: Node2D
	var boss_motion = load("res://scripts/BossMotion.gd").new()

var output := "res://../artifacts/godot/pollution-bubbles"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	call_deferred("run")

func _capture(name: String) -> Image:
	for frame in range(7): await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(output + "/" + name + ".png")
	return image

func _purple_pixels(image: Image) -> int:
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
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"appearance": "male_default", "coins": 700, "progress": {"day": 3, "stage": "boss", "bossDefeated": false}}
	state.adventure = {"discoveries": [], "puzzles": []}
	state.dive = {}
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(3, "boss")
	clock.visual_minutes = 600
	clock.elapsed_seconds = 0
	clock.reduced_motion = false
	clock.clock_paused = false
	root.get_node("RenderQuality").set_profile("balanced", false)
	var report := {"surface": [], "underwater": []}
	for viewport in [Vector2i(667, 375), Vector2i(844, 390)]:
		root.size = viewport
		var stage := Node2D.new()
		root.add_child(stage)
		var player: Node2D = load("res://scripts/Player.gd").new()
		stage.add_child(player)
		player.set_physics_process(false)
		player.visible = false
		player.position = Vector2(1490, 1340)
		var camera := Camera2D.new()
		camera.zoom = Vector2(1.05, 1.05)
		stage.add_child(camera)
		var renderer: Node2D = load("res://scripts/land/LandWorld3D.gd").new()
		stage.add_child(renderer)
		renderer.setup(stage, player, camera, "hub")
		renderer.set_process(false)
		renderer._update_view(0, true)
		renderer._process(0.5)
		var pollution: Node3D = renderer.water_node.pollution_surface
		pollution.set_focus(player.position)
		pollution._process(0.2)
		assert(pollution.debug_status().visibleBubbles == 18, "Every surface bubble must land on water")
		await _capture("surface-before-%dx%d" % [viewport.x, viewport.y])
		report.surface.append({"viewport": [viewport.x, viewport.y], "before": pollution.debug_status()})
		state.player.progress.bossDefeated = true
		pollution._process(1.0)
		pollution._process(1.0)
		assert(pollution.debug_status().visibleBubbles == 0, "Victory must clear surface plume")
		await _capture("surface-after-%dx%d" % [viewport.x, viewport.y])
		report.surface[-1].after = pollution.debug_status()
		stage.free()
		state.player.progress.bossDefeated = false
	var source := Source.new()
	root.add_child(source)
	source.nala = Swimmer.new()
	source.add_child(source.nala)
	source.nala.visible = false
	source.camera = Camera2D.new()
	source.camera.zoom = Vector2.ONE
	source.add_child(source.camera)
	source.entities = load("res://scripts/Entities.gd").new()
	source.entities.player = source.nala
	source.add_child(source.entities)
	source.entities.visible = false
	state.dive = {"id": "pollution-proof", "mode": "boss", "hits": 0, "oxygen": 77, "loot": [], "targets": []}
	source.nala.position = Vector2(4660, 2630)
	source.camera.position = source.nala.position
	source.camera.force_update_scroll()
	var ocean: Node2D = load("res://scripts/hybrid/HybridOcean.gd").new()
	source.add_child(ocean)
	ocean.setup(source)
	for viewport in [Vector2i(667, 375), Vector2i(844, 390)]:
		root.size = viewport
		for frame in range(20): await process_frame
		var water: Node3D = ocean.pollution_underwater
		water._process(1.0)
		assert(water.debug_status().strength > 0.98)
		assert(water.debug_status().visibleBubbles > 0, "Underwater valve plume should be visible")
		var before_image: Image = await _capture("underwater-before-%dx%d" % [viewport.x, viewport.y])
		var before_pixels := _purple_pixels(before_image)
		assert(before_pixels > 12, "Underwater plume must visibly survive at actual display size")
		report.underwater.append({"viewport": [viewport.x, viewport.y], "before": water.debug_status()})
		state.player.progress.bossDefeated = true
		water._process(1.0)
		water._process(1.0)
		assert(water.debug_status().strength == 0.0)
		var after_image: Image = await _capture("underwater-after-%dx%d" % [viewport.x, viewport.y])
		assert(_purple_pixels(after_image) < before_pixels / 2, "Victory must remove most visible purple plume pixels")
		report.underwater[-1].after = water.debug_status()
		state.player.progress.bossDefeated = false
		water.set_active(false)
		water.set_active(true)
	assert(state.dive.oxygen == 77 and state.player.coins == 700)
	FileAccess.open(output + "/results.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("POLLUTION BUBBLES RENDER PASS: 2 viewports, surface and underwater, authoritative before/after")
	source.free()
	quit()
