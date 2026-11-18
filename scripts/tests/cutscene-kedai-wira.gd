extends SceneTree

const SIZES := [Vector2i(667,375),Vector2i(844,390)]
const TIMES := {"entry":0.0,"offer":0.85,"settled":2.25}
const OUTPUT := "res://../artifacts/godot/cutscene-kedai-wira/"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture:=OS.get_environment("CINEMATIC_CAPTURE")=="1"
	if capture:
		assert(DisplayServer.get_name()!="headless")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var environment: Node=root.get_node("EnvironmentState")
	var audio: Node=root.get_node("AudioManager")
	var previous_motion: bool=environment.reduced_motion
	var previous_mute: bool=audio.muted
	environment.reduced_motion=false
	audio.muted=true
	var story=load("res://scripts/PhaseOneCutscenes.gd")
	var sequence: Dictionary=story.sequence("first_kedai")
	var beat: Dictionary=sequence.lines[0]
	var frame: Control=load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control=load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var checked:=0
	for physical in SIZES:
		root.size=physical
		for settle in range(4): await process_frame
		for label in TIMES:
			frame.present(str(sequence.title),beat,1,sequence.lines.size(),"first_kedai")
			dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
			dialogue.text_view.visible_characters=-1
			frame._process(float(TIMES[label]))
			for settle in range(3): await process_frame
			assert(frame.title_label.get_global_rect().end.y < dialogue.get_global_rect().position.y)
			assert(frame.action_layer.motif_id=="first_kedai" and frame.action_layer.motif_beat==1)
			if capture:
				RenderingServer.force_draw(false)
				var image: Image=root.get_texture().get_image()
				assert(image.get_size()==physical)
				var path:=OUTPUT+"kedai-01-%s-%dx%d.png" % [label,physical.x,physical.y]
				assert(image.save_png(ProjectSettings.globalize_path(path))==OK)
			checked+=1
	environment.reduced_motion=true
	frame.present(str(sequence.title),beat,1,sequence.lines.size(),"first_kedai")
	frame._process(.4)
	assert(frame.action_layer.motif_id=="first_kedai")
	environment.reduced_motion=previous_motion
	audio.muted=previous_mute
	dialogue.free()
	frame.free()
	print("CUTSCENE KEDAI WIRA PASS: %d native-size timing checks and reduced-motion state" % checked)
	quit()
