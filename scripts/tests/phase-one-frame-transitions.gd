extends SceneTree

const OUTPUT := "res://../artifacts/godot/phase-one-tone-motion/"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var capture := OS.get_environment("CINEMATIC_TONE_CAPTURE") == "1"
	if capture:
		assert(DisplayServer.get_name() != "headless", "Tone captures require a native renderer")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.size = Vector2i(667, 375)
	var environment: Node = root.get_node("EnvironmentState")
	environment.reduced_motion = false
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	var dialogue: Control
	if capture:
		dialogue = load("res://scripts/DialoguePresenter.gd").new()
		root.add_child(dialogue)
	await process_frame
	assert(frame.shade.color.a == 0.0, "An unopened cinematic must not flash white")
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var opening: Dictionary = story.sequence("prologue").lines[0]
	frame.present("Kabut", opening, 1, 12, "prologue")
	assert(frame.shade.color == frame.shade_target, "First shot must start at its authored tone")
	if capture:
		dialogue.present(str(opening.name), str(opening.text))
		dialogue.text_view.visible_characters = -1
		await _save_frame("harbor-opening")
	var polluted: Dictionary = story.sequence("prologue").lines[1]
	frame.present("Kabut", polluted, 2, 12, "prologue")
	var previous: float = frame.shade.color.a
	frame._process(0.1)
	assert(frame.shade.color.a > previous and frame.shade.color.a < frame.shade_target.a, "Pollution grade must move smoothly")
	frame.hide()
	var victory: Dictionary = story.sequence("victory").lines[0]
	frame.present("Pemulihan", victory, 1, 3, "victory")
	assert(frame.boss_previous.visible and frame.boss_art.modulate.a < 0.01, "Corrupted boss should begin the healing transition")
	if capture:
		dialogue.present(str(victory.name), str(victory.text))
		dialogue.text_view.visible_characters = -1
		await _save_frame("healing-start")
	frame._process(0.6)
	assert(frame.boss_art.modulate.a > 0.0 and frame.boss_art.modulate.a < 0.89, "Healed boss should crossfade, not pop")
	if capture: await _save_frame("healing-mid")
	frame._process(0.7)
	assert(not frame.boss_previous.visible and is_equal_approx(frame.boss_art.modulate.a, 0.89), "Corrupted boss must disappear after healing")
	if capture: await _save_frame("healing-settled")
	var sealing: Dictionary = story.sequence("victory").lines[1]
	frame.present("Pipa Tersumbat", sealing, 2, 3, "victory")
	frame._process(1.2)
	assert(frame.boss_art.anchor_right <= 0.67, "Mina must clear the painted pipe outlet during the seal")
	if capture:
		dialogue.present(str(sealing.name), str(sealing.text))
		dialogue.text_view.visible_characters = -1
		await _save_frame("pipe-outlet-clear")
	var surface: Dictionary = story.sequence("victory").lines[2]
	frame.present("Ingatan Kembali", surface, 3, 3, "victory")
	assert(frame.surface_fog.visible, "The surface fog must overlay the returning harbor")
	if capture:
		dialogue.present(str(surface.name), str(surface.text))
		dialogue.text_view.visible_characters = -1
	frame._process(0.45)
	if capture:
		await _save_frame("harbor-fog-start")
	frame._process(0.95)
	if capture: await _save_frame("harbor-fog-mid")
	frame._process(1.8)
	assert(not frame.surface_fog.visible, "The fog must leave no permanent draw pass after clearing")
	if capture: await _save_frame("harbor-fog-clear")
	environment.reduced_motion = true
	frame.present("Pemulihan", victory, 1, 3, "victory")
	frame._process(0.0)
	assert(not frame.boss_previous.visible and is_equal_approx(frame.boss_art.modulate.a, 0.89), "Reduced motion must show the settled healed state")
	frame.free()
	if is_instance_valid(dialogue): dialogue.free()
	environment.reduced_motion = false
	print("PHASE ONE FRAME TRANSITIONS PASS: initial tone, pollution fade, boss healing, reduced motion")
	quit()

func _save_frame(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	assert(image != null and image.get_width() == 667 and image.get_height() == 375, "Tone capture viewport mismatch")
	assert(image.save_png(ProjectSettings.globalize_path(OUTPUT + name + ".png")) == OK, "Could not save tone capture " + name)
