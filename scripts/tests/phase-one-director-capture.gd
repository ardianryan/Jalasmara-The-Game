extends SceneTree

const OUTPUT := "res://../artifacts/godot/phase-one-director-qa/"
const SIZES := [Vector2i(667, 375), Vector2i(844, 390)]
const SEQUENCE_IDS := [
	"prologue", "first_dive", "first_kedai", "first_service", "garden_crisis",
	"saras_visit", "cave_warning", "earthquake", "boss_intro",
	"boss_phase_two", "victory", "epilogue",
]
const SCENE_TO_SEQUENCE := {
	"0.1": ["prologue"], "0.2": ["prologue"],
	"0.3": ["prologue"], "0.4": ["prologue"],
	"1.1": ["first_dive"], "1.2": ["first_kedai", "first_service"],
	"2.1": ["garden_crisis"], "2.2": ["saras_visit"],
	"3.1": ["cave_warning"], "3.2": ["earthquake"],
	"4.1": ["boss_intro"], "4.2": ["boss_phase_two"],
	"4.3": ["victory"], "4.4": ["victory"],
	"4.5": ["epilogue"], "4.6": ["epilogue"],
}

func _initialize() -> void:
	_run.call_deferred()

func _scene_number(shot: String) -> String:
	if shot.length() < 3 or shot.substr(1, 1) != ".": return ""
	var number := shot.substr(0, 3)
	return number if number.substr(0, 1).is_valid_int() and number.substr(2, 1).is_valid_int() else ""

func _distinct_middle_colors(image: Image) -> int:
	var colors := {}
	var width := image.get_width()
	var height := image.get_height()
	var step := maxi(4, floori(float(mini(width, height)) / 52.0))
	for y in range(int(height * .17), int(height * .58), step):
		for x in range(int(width * .10), int(width * .90), step):
			colors[image.get_pixel(x, y).to_html(false)] = true
			if colors.size() >= 16: return colors.size()
	return colors.size()

func _check_controls(frame: Control, dialogue: Control, physical: Vector2i, label: String) -> void:
	var view := root.get_visible_rect().grow(1)
	var scale := root.get_final_transform().x.length()
	var skip: Button = frame.skip_button
	var next: Button = dialogue.next_button
	assert(view.encloses(skip.get_global_rect()), "Skip outside %s at %s" % [label, physical])
	assert(view.encloses(dialogue.get_global_rect()), "Dialogue outside %s at %s" % [label, physical])
	assert(dialogue.get_global_rect().grow(1).encloses(next.get_global_rect()), "Next outside dialogue: " + label)
	assert(not skip.get_global_rect().intersects(next.get_global_rect()), "Skip overlaps next: " + label)
	assert(not skip.disabled and skip.visible and skip.focus_mode != Control.FOCUS_NONE, "Skip inaccessible: " + label)
	assert(not next.disabled and next.visible and next.focus_mode != Control.FOCUS_NONE, "Next inaccessible: " + label)
	assert(skip.size.x * scale >= 47.99 and skip.size.y * scale >= 47.99, "Skip target below 48 px: " + label)
	assert(next.size.x * scale >= 47.99 and next.size.y * scale >= 47.99, "Next target below 48 px: " + label)
	assert(dialogue.text_view.get_theme_font_size("normal_font_size") * scale >= 15.99, "Dialogue body below 16 px: " + label)
	assert(dialogue.nameplate.get_theme_font_size("font_size") * scale >= 15.99, "Speaker name below 16 px: " + label)
	assert(view.encloses(frame.title_label.get_global_rect()), "Cinematic title outside viewport: " + label)
	assert(view.encloses(frame.shot_label.get_global_rect()), "Shot label outside viewport: " + label)
	assert(view.encloses(frame.progress_label.get_global_rect()), "Progress label outside viewport: " + label)

func _run() -> void:
	var capture := OS.get_environment("CINEMATIC_CAPTURE") == "1"
	var strict_composition := OS.get_environment("CINEMATIC_REQUIRE_COMPOSITION") == "1"
	if capture: DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var story = load("res://scripts/PhaseOneCutscenes.gd")
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	var dialogue: Control = load("res://scripts/DialoguePresenter.gd").new()
	var environment: Node = root.get_node("EnvironmentState")
	var state: Node = root.get_node("GameState")
	state.set("world", {"surface_hub": {"residents": [
		{"id": "npc_ki_lurah_wirabhumi", "name": "Ki Lurah Wirabhumi", "appearance": 0},
		{"id": "npc_saras", "name": "Saras", "appearance": 5},
		{"id": "npc_kid_kinasih", "name": "Kinasih", "appearance": 8},
		{"id": "npc_kid_gito", "name": "Gito", "appearance": 10},
	]}})
	state.set("player", {"appearance": "male_default"})
	root.add_child(frame)
	root.add_child(dialogue)
	var skip_signals: Array = []
	frame.skip_requested.connect(func(): skip_signals.append(true))
	var scene_coverage := {}
	var records: Array = []
	var missing_backdrops: Array = []
	for physical in SIZES:
		root.size = physical
		for settle in range(4): await process_frame
		assert(root.size == physical, "Window must use the requested physical size")
		for id in SEQUENCE_IDS:
			var sequence: Dictionary = story.sequence(id)
			assert(not sequence.is_empty() and sequence.has("lines"), "Missing sequence: " + id)
			var lines: Array = sequence.lines
			for beat_zero in range(lines.size()):
				var beat: Dictionary = lines[beat_zero]
				var index := beat_zero + 1
				var shot := str(beat.get("shot", ""))
				var scene := _scene_number(shot)
				var tag := "%s-%02d-%dx%d" % [id, index, physical.x, physical.y]
				assert(not shot.is_empty() and not str(beat.get("text", "")).is_empty(), "Empty authored beat: " + tag)
				if not scene.is_empty():
					assert(SCENE_TO_SEQUENCE.has(scene), "Unexpected numbered scene: " + scene)
					assert((SCENE_TO_SEQUENCE[scene] as Array).has(id), "Scene assigned to wrong sequence: " + tag)
					scene_coverage[scene] = true
				environment.reduced_motion = false
				frame.present(str(sequence.title), beat, index, lines.size(), id)
				dialogue.present(str(beat.get("name", "")), str(beat.text), str(beat.get("emotion", "neutral")))
				for settle in range(3): await process_frame
				dialogue.text_view.visible_characters = -1
				_check_controls(frame, dialogue, physical, tag)
				assert(frame.visible and frame.motif_id == id and frame.motif_beat == index, "Beat not presented: " + tag)
				assert(frame.progress_label.text == "%d / %d" % [index, lines.size()], "Beat progress wrong: " + tag)
				assert(not dialogue.text_view.get_parsed_text().is_empty(), "Dialogue text invisible: " + tag)
				if id != "first_dive" and frame.backdrop == null: missing_backdrops.append(tag)
				await RenderingServer.frame_post_draw
				var image: Image = root.get_texture().get_image()
				assert(image != null and image.get_width() > 0 and image.get_height() > 0, "No rendered frame: " + tag)
				var colors := _distinct_middle_colors(image)
				if id == "first_dive": assert(colors >= 2, "First-dive action frame is blank: " + tag)
				if strict_composition and id != "first_dive":
					assert(frame.backdrop != null, "Required scenic backdrop missing: " + tag)
					assert(colors >= 8, "Scenic frame is visually blank: " + tag)
				if capture:
					frame._process(1.2)
					for settle in range(2): await process_frame
					await RenderingServer.frame_post_draw
					var motion_image: Image = root.get_texture().get_image()
					assert(motion_image.save_png(ProjectSettings.globalize_path(OUTPUT + tag + ".png")) == OK, "Could not save " + tag)
				records.append({"tag": tag, "scene": scene, "shot": shot, "backdropKey": frame.backdrop_key, "backdrop": frame.backdrop != null, "middleColors": colors, "raster": [image.get_width(), image.get_height()]})
				environment.reduced_motion = true
				frame.present(str(sequence.title), beat, index, lines.size(), id)
				dialogue.present(str(beat.get("name", "")), str(beat.text), str(beat.get("emotion", "neutral")))
				for settle in range(2): await process_frame
				_check_controls(frame, dialogue, physical, tag + " reduced")
				assert(not frame.living_plate.visible, "Reduced motion kept shader plate active: " + tag)
				assert(dialogue.text_view.visible_characters == -1, "Reduced motion hid text: " + tag)
		var before := skip_signals.size()
		var touch := InputEventScreenTouch.new()
		touch.index = 0
		touch.position = frame.skip_button.get_global_rect().get_center()
		touch.pressed = true
		root.push_input(touch, true)
		await process_frame
		touch.pressed = false
		root.push_input(touch, true)
		await process_frame
		assert(skip_signals.size() == before + 1, "Skip touch does not dispatch at %s" % physical)
	assert(scene_coverage.size() == SCENE_TO_SEQUENCE.size(), "Incomplete 16-scene matrix: " + JSON.stringify(scene_coverage))
	if strict_composition: assert(missing_backdrops.is_empty(), "Scenic beats without backdrops: " + JSON.stringify(missing_backdrops))
	if capture:
		var report := FileAccess.open(ProjectSettings.globalize_path(OUTPUT + "results.json"), FileAccess.WRITE)
		assert(report != null, "Could not write director QA report")
		report.store_string(JSON.stringify({"strictComposition": strict_composition, "records": records, "missingBackdrops": missing_backdrops}, "  "))
		report.close()
	if not missing_backdrops.is_empty(): print("DIRECTOR QA GAP: ", JSON.stringify(missing_backdrops))
	print("PHASE ONE DIRECTOR QA PASS: %d frames, 12 sequences, 16 numbered scenes, 667x375 and 844x390; strict composition=%s" % [records.size(), strict_composition])
	environment.reduced_motion = false
	dialogue.free()
	frame.free()
	quit()
