extends SceneTree

const OUTPUT := "res://../artifacts/godot/victory-dock/"
const SIZES := [Vector2i(667,375),Vector2i(844,390)]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture := OS.get_environment("CINEMATIC_CAPTURE") == "1"
	if capture:
		assert(DisplayServer.get_name() != "headless", "Victory dock capture needs the native renderer")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var sequence: Dictionary = story.sequence("victory")
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(dialogue)
	dialogue.hide()
	for physical in SIZES:
		root.size = physical
		for settle in range(4): await process_frame
		frame.present(str(sequence.title), sequence.lines[2], 3, sequence.lines.size(), "victory")
		var berth: Rect2 = frame.action_layer._victory_berth(Vector2(physical))
		assert(berth.position.x > physical.x * .4 and berth.end.x < physical.x * .7)
		assert(berth.position.y > physical.y * .58 and berth.end.y < physical.y * .74)
		assert(berth.size.x > 120.0 and berth.size.y > 44.0)
		for seconds in [0.12,1.4,3.1]:
			frame.present(str(sequence.title), sequence.lines[2], 3, sequence.lines.size(), "victory")
			frame._process(seconds)
			for settle in range(3): await process_frame
			if capture:
				await RenderingServer.frame_post_draw
				var image: Image = root.get_texture().get_image()
				assert(image.get_width() == physical.x and image.get_height() == physical.y)
				var path := OUTPUT + "victory-t%02d-%dx%d.png" % [int(seconds*10.0),physical.x,physical.y]
				assert(image.save_png(ProjectSettings.globalize_path(path)) == OK, "Cannot save " + path)
		var beat: Dictionary = sequence.lines[2]
		dialogue.present(str(beat.name),str(beat.text),str(beat.get("emotion","neutral")))
		dialogue.show()
		dialogue.text_view.visible_characters = -1
		for settle in range(3): await process_frame
		if capture:
			await RenderingServer.frame_post_draw
			var image: Image = root.get_texture().get_image()
			var path := OUTPUT + "victory-dialogue-%dx%d.png" % [physical.x,physical.y]
			assert(image.save_png(ProjectSettings.globalize_path(path)) == OK, "Cannot save " + path)
		dialogue.hide()
	frame.free()
	dialogue.free()
	print("PHASE ONE VICTORY DOCK PASS")
	quit()
