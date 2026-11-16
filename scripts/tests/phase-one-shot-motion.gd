extends SceneTree

const OUTPUT := "res://../artifacts/godot/phase-one-shot-motion/"
const SHOTS := [
	["prologue", 4], ["prologue", 5], ["prologue", 7],
	["first_dive", 1], ["first_service", 1], ["garden_crisis", 2],
	["cave_warning", 2], ["earthquake", 1], ["boss_intro", 1],
	["boss_phase_two", 1], ["victory", 1], ["victory", 2], ["victory", 3],
	["epilogue", 2], ["epilogue", 4], ["epilogue", 7]
]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var capture := OS.get_cmdline_user_args().has("--capture")
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	var environment := root.get_node("EnvironmentState")
	environment.set("reduced_motion", false)
	for physical in [Vector2i(667,375),Vector2i(844,390)]:
		root.size = physical
		await process_frame
		for shot in SHOTS:
			var id: String = shot[0]
			var beat: int = shot[1]
			frame.present("Phase 1", {"shot":"Directed action", "tone":"teal"}, beat, 8, id)
			assert(frame.action_layer.has_directed_action(id,beat),"No action: %s/%d" % [id,beat])
			assert(frame.action_layer.motif_id == id and frame.action_layer.motif_beat == beat)
			frame._process(2.8)
			await process_frame
			RenderingServer.force_draw()
			if capture:
				var image := root.get_texture().get_image()
				if image != null:
					image.save_png(OUTPUT + "%s-%d-%dx%d.png" % [id,beat,physical.x,physical.y])
				else:
					push_warning("Capture unavailable with the current renderer")
			assert(frame.action_layer.size.x > 0 and frame.action_layer.size.y > 0)
		assert(frame.action_layer.has_directed_action("epilogue",4))
	environment.set("reduced_motion",true)
	frame.present("Reduced motion",{"shot":"Still","tone":"warm"},1,3,"boss_intro")
	frame._process(.1)
	assert(not frame.living_plate.visible)
	assert(is_equal_approx(frame.action_layer.elapsed,3.0))
	assert(frame.boss_art.visible and frame.boss_art.modulate.a > .8)
	environment.set("reduced_motion",false)
	frame.free()
	print("PHASE ONE SHOT MOTION PASS: %d shots at two viewports + reduced motion" % SHOTS.size())
	quit()
