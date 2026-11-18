extends SceneTree

const OUTPUT := "res://../artifacts/godot/cutscene-market-reaction/"
const SIZES := [Vector2i(667, 375), Vector2i(844, 390)]
const TIMES := [.08, .48, 1.18, 2.4]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture := OS.get_environment("CINEMATIC_CAPTURE") == "1"
	if capture:
		assert(DisplayServer.get_name() != "headless")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var environment: Node = root.get_node("EnvironmentState")
	var audio: Node = root.get_node("AudioManager")
	var prior_motion: bool = environment.reduced_motion
	var prior_mute: bool = audio.muted
	audio.muted = true
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var sequence: Dictionary = story.sequence("prologue")
	var beat: Dictionary = sequence.lines[2]
	var checked := 0
	for physical in SIZES:
		root.size = physical
		for settle in range(4): await process_frame
		for reduced in [false, true]:
			environment.reduced_motion = reduced
			for index in range(TIMES.size()):
				frame.present(str(sequence.title), beat, 3, sequence.lines.size(), "prologue")
				dialogue.present(str(beat.name), str(beat.text), str(beat.get("emotion", "neutral")))
				dialogue.text_view.visible_characters = -1
				frame._process(float(TIMES[index]))
				for settle in range(3): await process_frame
				assert(frame.title_label.get_global_rect().end.y < dialogue.get_global_rect().position.y)
				if capture:
					RenderingServer.force_draw(false)
					var image: Image = root.get_texture().get_image()
					assert(image.get_size() == physical)
					var suffix := "reduced" if reduced else "normal"
					var path := OUTPUT + "market-%s-t%d-%dx%d.png" % [suffix, index, physical.x, physical.y]
					assert(image.save_png(ProjectSettings.globalize_path(path)) == OK)
				checked += 1
	environment.reduced_motion = prior_motion
	audio.muted = prior_mute
	dialogue.free()
	frame.free()
	print("CUTSCENE MARKET REACTION PASS: %d checks" % checked)
	quit()
