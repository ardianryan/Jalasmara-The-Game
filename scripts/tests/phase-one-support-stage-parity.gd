extends SceneTree

const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const OUTPUT := "res://../artifacts/godot/phase-one-support-stage-parity/"
const CASES := [
	{"id":"prologue","beat":5,"label":"refusal"},
	{"id":"garden_crisis","beat":2,"label":"garden_children"},
	{"id":"earthquake","beat":2,"label":"balai"},
	{"id":"epilogue","beat":1,"label":"feast"},
	{"id":"epilogue","beat":2,"label":"feast_witnesses"},
	{"id":"epilogue","beat":3,"label":"celebration"},
]

func _initialize() -> void:
	_run.call_deferred()

func _ink_height(texture: Texture2D, region: Rect2i, display_height: float) -> float:
	var ink := texture.get_image().get_region(region).get_used_rect()
	return float(ink.size.y) / float(region.size.y) * display_height

func _run() -> void:
	var action = load("res://scripts/CinematicActionLayer.gd")
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var capture := OS.get_environment("CINEMATIC_CAPTURE") == "1"
	assert(not capture or DisplayServer.get_name() != "headless", "Native renderer required for support staging capture")
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var environment: Node = root.get_node("EnvironmentState")
	var audio: Node = root.get_node("AudioManager")
	var old_muted: bool = audio.muted
	var old_motion: bool = environment.reduced_motion
	audio.muted = true
	environment.reduced_motion = false
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var checks := 0
	var captures := 0
	for physical in SIZES:
		root.size = physical
		for settle in range(4): await process_frame
		for index in range(6):
			var lean: float = frame.action_layer._stage_lean(2.0,index,.04)
			assert(absf(lean) <= .04, "Stage actor tilt exceeds the small pixel-motion budget")
			checks += 1
		environment.reduced_motion = true
		assert(frame.action_layer._stage_lean(2.0,1) == 0.0, "Reduced motion must stop actor lean")
		environment.reduced_motion = false
		checks += 1
		var unit: float = frame.action_layer._unit(frame.action_layer.size) * root.get_final_transform().y.length()
		var refusal_x: Array = action.REFUSAL_CHILD_X
		assert(refusal_x.size() == 5 and refusal_x[0] >= .05 and refusal_x[-1] <= .43, "Five children must fit on the refusal pier")
		for i in range(1, refusal_x.size()):
			assert(float(refusal_x[i]) - float(refusal_x[i-1]) >= .085, "Refusal children have overlapping floor marks")
			checks += 1
		var feast_x: Array = action.FEAST_SUPPORT_X
		assert(feast_x.size() == 6 and feast_x[0] >= .06 and feast_x[-1] <= .50, "Six residents must remain in the Kedai stage")
		for i in range(1, feast_x.size()):
			assert(float(feast_x[i]) - float(feast_x[i-1]) >= .08, "Feast residents have overlapping floor marks")
			checks += 1
		var child_height := _ink_height(action.CHILD_ATLAS, Rect2i(96,0,96,128), 44.0 * action.REFUSAL_CHILD_SCALE * unit)
		assert(child_height >= 65.0 and child_height <= 95.0, "Refusal child still miniature or oversized: %.1f" % child_height)
		var lurah_height := _ink_height(action.NPC_FACES["lurah"], Rect2i(0,0,64,64), 40.0 * action.BALAI_BACKGROUND_LURAH_SCALE * unit)
		assert(lurah_height >= 75.0 and lurah_height <= 105.0, "Balai Lurah still miniature or oversized: %.1f" % lurah_height)
		for role in ["ratih","tedi","wira"]:
			var feast_height := _ink_height(action.NPC_FACES[role], Rect2i(0,0,64,64), 40.0 * action.FEAST_BACKGROUND_SCALE * unit)
			assert(feast_height >= 58.0 and feast_height <= 90.0, "Feast resident %s unreadable: %.1f" % [role,feast_height])
			checks += 1
		assert(physical.y * .64 - lurah_height > 56.0, "Balai Lurah crosses top letterbox")
		assert(physical.y * .68 < dialogue.position.y * root.get_final_transform().y.length() + 5.0, "Feast floor would enter dialogue")
		checks += 4
		for scene_case in CASES:
			var sequence: Dictionary = story.sequence(scene_case.id)
			var beat: Dictionary = sequence.lines[int(scene_case.beat)-1]
			frame.present(str(sequence.title), beat, scene_case.beat, sequence.lines.size(), scene_case.id)
			dialogue.present(str(beat.name), str(beat.text), str(beat.get("emotion","neutral")))
			dialogue.text_view.visible_characters = -1
			frame._process(2.0)
			for settle in range(4): await process_frame
			assert(frame.action_layer.has_directed_action(scene_case.id, scene_case.beat), "Missing scene action")
			assert(frame.title_label.get_global_rect().end.y < dialogue.get_global_rect().position.y, "Title/dialogue collision")
			checks += 2
			if capture:
				RenderingServer.force_draw(false)
				var image: Image = root.get_texture().get_image()
				var path := OUTPUT + "%s-%dx%d.png" % [scene_case.label,physical.x,physical.y]
				assert(image.save_png(ProjectSettings.globalize_path(path)) == OK, "Could not save " + path)
				captures += 1
				frame._process(.65)
				for settle in range(2): await process_frame
				RenderingServer.force_draw(false)
				image = root.get_texture().get_image()
				path = OUTPUT + "%s-late-%dx%d.png" % [scene_case.label,physical.x,physical.y]
				assert(image.save_png(ProjectSettings.globalize_path(path)) == OK, "Could not save " + path)
				captures += 1
	environment.reduced_motion = old_motion
	audio.muted = old_muted
	dialogue.free()
	frame.free()
	print("PHASE ONE SUPPORT STAGE PASS: %d checks, %d native captures" % [checks,captures])
	quit()
