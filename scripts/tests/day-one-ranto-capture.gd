extends SceneTree

const OUTPUT := "res://../artifacts/godot/day-one-ranto/"
const SIZES := [Vector2i(667,375),Vector2i(844,390)]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state: Node = root.get_node("GameState")
	state.player = {"appearance":"female_nusantara"}
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(frame)
	root.add_child(dialogue)
	var action_script = load("res://scripts/CinematicActionLayer.gd")
	var portrait: Texture2D = action_script.ranto_portrait_texture()
	assert(portrait.get_width()==160 and portrait.get_height()==160,"Ranto portrait must retain its curated 160px source grid")
	var capture := OS.get_environment("CINEMATIC_CAPTURE")=="1"
	if capture:
		assert(DisplayServer.get_name()!="headless","Native framebuffer required for Ranto proof")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for customer in ["Pak Ranto","Bu Darmi"]:
		state.shift = {"customers":[{"id":"daun_kuning","customer":customer}],"served":[]}
		var sequence: Dictionary = load("res://scripts/PhaseOneCutscenes.gd").sequence("first_service",customer)
		assert(str(sequence.lines[0].name)==customer,"Dialogue must follow the saved shift customer")
		for physical in SIZES:
			root.size = physical
			for settle in range(4): await process_frame
			frame.present(str(sequence.title),sequence.lines[0],1,sequence.lines.size(),"first_service")
			dialogue.present(str(sequence.lines[0].name),str(sequence.lines[0].text),"shock")
			dialogue.text_view.visible_characters=-1
			frame._process(1.2)
			for settle in range(3): await process_frame
			assert(frame.action_layer.motif_id=="first_service" and frame.action_layer.motif_beat==1)
			if capture:
				await RenderingServer.frame_post_draw
				var image: Image = root.get_texture().get_image()
				var tag := ("ranto" if customer=="Pak Ranto" else "legacy-darmi")+"-%dx%d.png" % [physical.x,physical.y]
				assert(image.save_png(ProjectSettings.globalize_path(OUTPUT+tag))==OK,"Could not save "+tag)
	frame.free()
	dialogue.free()
	print("DAY ONE RANTO PASS: fresh Pak Ranto portrait, legacy Darmi saved shift, 667×375 and 844×390")
	quit()
