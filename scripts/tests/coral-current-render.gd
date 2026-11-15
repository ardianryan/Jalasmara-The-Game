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
		swim_sprite.animate(false,true,1,0)

class Source extends Node2D:
	var camera: Camera2D
	var nala: Swimmer
	var entities: Node2D

var output := "res://../artifacts/godot/coral-current-motion"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	call_deferred("run")

func _capture(label: String, ocean: Node2D) -> void:
	for frame in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "/" + label + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	root.size = Vector2i(667,375)
	var state := root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"appearance":"male_default","coins":700,"progress":{"day":2,"stage":"dive"}}
	state.adventure = {"discoveries":[],"puzzles":[]}
	state.dive = {"id":"coral-motion-proof","oxygen":77,"loot":[],"targets":[]}
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.visual_minutes = 600
	clock.elapsed_seconds = 0
	clock.reduced_motion = false
	root.get_node("RenderQuality").set_profile("balanced",false)
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
	var ocean: Node2D = load("res://scripts/hybrid/HybridOcean.gd").new()
	source.add_child(ocean)
	ocean.setup(source)
	source.nala.position = Vector2(1550,620)
	source.camera.position = source.nala.position
	source.camera.force_update_scroll()
	for frame in range(30): await process_frame
	var terrain: Node3D = ocean.terrain_geometry
	assert(is_instance_valid(terrain))
	assert(terrain._coral_pivots.size() > 0)
	terrain.set_process(false)
	var motion = load("res://scripts/CoralCurrentMotion.gd")
	var report := {"counts":{"coral":terrain._coral_pivots.size()},"frames":[],"playerOxygen":state.dive.oxygen}
	for viewport in [Vector2i(667,375),Vector2i(844,390)]:
		root.size = viewport
		for sample in [{"id":"still","time":-1.0},{"id":"sway-a","time":0.0},{"id":"sway-b","time":2.5}]:
			var max_tip := 0.0
			var moved := 0
			for entry in terrain._coral_pivots:
				var angle: float = 0.0 if sample.time < 0 else motion.angle(float(sample.time),entry.position,8.0)
				entry.node.rotation.z = angle
				max_tip = maxf(max_tip,absf(angle) * float(entry.size.y))
				if absf(angle) > 0.005: moved += 1
			var name := "%s-%dx%d" % [sample.id,viewport.x,viewport.y]
			await _capture(name,ocean)
			report.frames.append({"id":name,"moved":moved,"maxTipWorldPixels":max_tip})
	assert(state.dive.oxygen == 77 and state.player.coins == 700)
	FileAccess.open(output + "/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("CORAL CURRENT RENDER PASS: ",report.frames.size()," actual-size frames, rooted sway, unchanged resources")
	source.queue_free()
	await process_frame
	quit()
