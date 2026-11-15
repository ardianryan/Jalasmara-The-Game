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

var output := "res://../artifacts/godot/ocean-pipe-grounding"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	call_deferred("run")

func run() -> void:
	assert(DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var state := root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"appearance":"male_default", "coins":700, "progress":{"day":3,"stage":"dive","bossDefeated":false}}
	state.adventure = {"discoveries":[],"puzzles":[]}
	state.dive = {"id":"pipe-proof", "oxygen":77, "loot":[], "targets":[]}
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(3,"dive")
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
	var ocean: Node2D = load("res://scripts/hybrid/HybridOcean.gd").new()
	source.add_child(ocean)
	ocean.setup(source)
	for viewport in [Vector2i(667,375),Vector2i(844,390)]:
		root.size = viewport
		for sample in [
			{"id":"valve", "at":Vector2(4660,2630)},
			{"id":"leak", "at":Vector2(4200,2470)},
		]:
			source.nala.position = sample.at
			source.camera.position = sample.at
			source.camera.force_update_scroll()
			for frame in range(22): await process_frame
			assert(is_instance_valid(ocean.actors), "Production ocean actors must initialize")
			assert(ocean.actors.sprites.has("puzzle:valve"), "Valve visual must be present")
			assert(ocean.actors.sprites.has("hazard:leak_cave"), "Leak visual must be present")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output + "/%s-%dx%d.png" % [sample.id,viewport.x,viewport.y])
	assert(state.dive.oxygen == 77 and state.player.coins == 700)
	print("OCEAN PIPE GROUNDING RENDER PASS: valve and leak, two actual-size viewports, resources unchanged")
	source.queue_free()
	await process_frame
	quit()
