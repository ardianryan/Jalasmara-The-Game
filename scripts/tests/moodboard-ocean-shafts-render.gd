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

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var variant := OS.get_environment("OCEAN_SHAFT_VARIANT")
	if variant.is_empty(): variant = "candidate"
	var directory := "res://../artifacts/godot/moodboard-ocean-shafts/" + variant
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var state = root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"appearance":"male_default", "coins":700, "progress":{"day":2,"stage":"dive"}}
	state.adventure = {"discoveries":[],"puzzles":[]}
	state.dive = {"id":"ocean-proof","oxygen":77,"loot":[],"targets":[]}
	var clock = root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.visual_minutes = 600
	clock.elapsed_seconds = 0
	clock.reduced_motion = false
	clock.clock_paused = false
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
	var ocean = load("res://scripts/hybrid/HybridOcean.gd").new()
	source.add_child(ocean)
	ocean.setup(source)
	for tick in range(32): await process_frame
	assert(is_instance_valid(ocean.headlamp), "Ocean renderer did not initialize")
	for size in [Vector2i(844,390),Vector2i(667,375)]:
		root.size = size
		for sample in [
			{"id":"reef", "center":Vector2(1550,620)},
			{"id":"passage", "center":Vector2(750,900)},
		]:
			source.nala.position = sample.center
			source.camera.position = sample.center
			source.camera.force_update_scroll()
			for tick in range(16):
				source.nala.swim_sprite.animate(false,true,1,0)
				await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory + "/%dx%d-%s.png" % [size.x,size.y,sample.id])
	assert(state.dive.oxygen == 77 and state.player.coins == 700)
	print("OCEAN SHAFT RENDER PASS: four actual-size captures; resources and route unchanged")
	source.queue_free()
	await process_frame
	quit()
