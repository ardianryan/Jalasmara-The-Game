extends SceneTree

const OUTPUT := "res://../artifacts/godot/cutscene-acting-followup/"
const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const CASES := [
	{"id":"garden_crisis","beat":2,"times":[.08,.28,.52,1.28]},
	{"id":"victory","beat":3,"times":[.20,.84,1.08,2.50]},
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture := OS.get_environment("CINEMATIC_CAPTURE") == "1"
	if capture:
		assert(DisplayServer.get_name() != "headless", "Native renderer is required")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var environment: Node = root.get_node("EnvironmentState")
	var audio: Node = root.get_node("AudioManager")
	var previous_motion: bool = environment.reduced_motion
	var previous_mute: bool = audio.muted
	environment.reduced_motion = false
	audio.muted = true
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var captures := 0
	for physical in SIZES:
		root.size = physical
		for settle in range(4): await process_frame
		for scene_case in CASES:
			var sequence: Dictionary = story.sequence(scene_case.id)
			var beat: Dictionary = sequence.lines[int(scene_case.beat)-1]
			for index in range(scene_case.times.size()):
				frame.present(str(sequence.title),beat,scene_case.beat,sequence.lines.size(),scene_case.id)
				dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
				dialogue.text_view.visible_characters = -1
				frame._process(float(scene_case.times[index]))
				for settle in range(3): await process_frame
				assert(frame.title_label.get_global_rect().end.y < dialogue.get_global_rect().position.y)
				if capture:
					RenderingServer.force_draw(false)
					var image: Image = root.get_texture().get_image()
					assert(image.get_size() == physical)
					var path := OUTPUT + "%s-t%d-%dx%d.png" % [scene_case.id,index,physical.x,physical.y]
					assert(image.save_png(ProjectSettings.globalize_path(path)) == OK)
					captures += 1
	environment.reduced_motion = previous_motion
	audio.muted = previous_mute
	dialogue.free()
	frame.free()
	print("CUTSCENE ACTING FOLLOWUP PASS: %d captures" % captures)
	quit()
