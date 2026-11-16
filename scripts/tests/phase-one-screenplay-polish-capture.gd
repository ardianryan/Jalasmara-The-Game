extends SceneTree

const OUTPUT := "res://../artifacts/godot/phase-one-screenplay-polish/"
const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const CASES := [
	{"id":"prologue","beat":1,"backdrop":"prologue"},
	{"id":"prologue","beat":3,"backdrop":"prologue"},
	{"id":"first_service","beat":2,"backdrop":"kedai-interior"},
	{"id":"epilogue","beat":1,"backdrop":"kedai-interior"},
]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture := OS.get_environment("CINEMATIC_CAPTURE")=="1"
	if capture:
		assert(DisplayServer.get_name()!="headless","Native framebuffer required for screenplay capture")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var state: Node = root.get_node("GameState")
	var environment: Node = root.get_node("EnvironmentState")
	var audio: Node = root.get_node("AudioManager")
	var previous_muted: bool = audio.muted
	audio.muted = true
	state.player = {"appearance":"female_nusantara"}
	environment.reduced_motion = false
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var count := 0
	for physical in SIZES:
		root.size = physical
		for settle in range(4): await process_frame
		for scene_case in CASES:
			var id: String = scene_case.id
			var beat_index: int = scene_case.beat
			var sequence: Dictionary = story.sequence(id)
			var beat: Dictionary = sequence.lines[beat_index-1]
			frame.present(str(sequence.title),beat,beat_index,sequence.lines.size(),id)
			dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
			dialogue.text_view.visible_characters = -1
			frame._process(1.2)
			for settle in range(3): await process_frame
			assert(frame.action_layer.has_directed_action(id,beat_index),"Missing directed action: %s %d" % [id,beat_index])
			assert(frame.backdrop_key==scene_case.backdrop,"Wrong backdrop for %s %d" % [id,beat_index])
			assert(frame.backdrop!=null,"Missing backdrop for %s %d" % [id,beat_index])
			if capture:
				await RenderingServer.frame_post_draw
				var image: Image = root.get_texture().get_image()
				assert(image.get_width()==physical.x and image.get_height()==physical.y,"Wrong capture size")
				var filename := "%s-%02d-%dx%d.png" % [id,beat_index,physical.x,physical.y]
				assert(image.save_png(ProjectSettings.globalize_path(OUTPUT+filename))==OK,"Could not save "+filename)
			count += 1
	frame.free()
	dialogue.free()
	environment.reduced_motion = false
	audio.muted = previous_muted
	print("PHASE ONE SCREENPLAY POLISH PASS: %d scenes at 667×375 and 844×390" % count)
	quit()
