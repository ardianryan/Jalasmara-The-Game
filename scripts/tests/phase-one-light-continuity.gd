extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var environment: Node = root.get_node("EnvironmentState")
	var original_minutes: float = environment.visual_minutes
	var original_presented_minutes: float = environment._presented_minutes
	var original_daylight: float = environment._presented_daylight
	var original_initialized: bool = environment._presentation_initialized
	var original_reduced: bool = environment.reduced_motion
	environment.reduced_motion = false
	environment._presentation_initialized = true
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	root.size = Vector2i(667, 375)
	await process_frame
	var prior_target := Color.TRANSPARENT
	for minute in [390.0, 720.0, 1020.0, 1260.0]:
		environment.visual_minutes = minute
		environment._presented_minutes = minute
		environment._presented_daylight = environment.daylight_for_minutes(minute)
		frame.present("Kedai Waras", {"shot":"Balai pesisir", "tone":"warm"}, 2, 3, "first_service")
		assert(frame.scene_is_land)
		assert(frame.shade_target.a > 0.0)
		if not prior_target.is_equal_approx(Color.TRANSPARENT):
			assert(not frame.shade_target.is_equal_approx(prior_target), "Land tint must follow presented daylight")
		prior_target = frame.shade_target
	frame.present("Palung", {"shot":"Bawah air", "tone":"deep"}, 1, 2, "boss_intro")
	assert(not frame.scene_is_land)
	assert(frame.shade_target.is_equal_approx(Color(0.02,0.08,0.19,0.46)), "Narrative deep tint must remain intact")
	frame.call("fade_out")
	assert(frame.visible and frame.exiting)
	assert(frame.skip_button.disabled, "Closing cutscene must release the skip target")
	frame._process(0.17)
	assert(frame.modulate.a > 0.3 and frame.modulate.a < 0.7, "Exit midpoint must reveal the playable world gradually")
	frame._process(0.17)
	assert(not frame.visible)
	frame.present("Kedai", {"shot":"Hangat", "tone":"warm"}, 1, 2, "first_service")
	assert(frame.visible and not frame.exiting and is_equal_approx(frame.modulate.a, 1.0))
	assert(not frame.skip_button.disabled, "New cutscene must restore the skip target")
	frame.call("fade_out")
	environment.reduced_motion = true
	frame._process(0.016)
	assert(not frame.visible, "Changing reduced motion during an exit must finish immediately")
	frame.present("Kedai", {"shot":"Hangat", "tone":"warm"}, 1, 2, "first_service")
	frame.call("fade_out")
	assert(not frame.visible, "Reduced motion must return to gameplay without a fade")
	frame.free()
	environment.visual_minutes = original_minutes
	environment._presented_minutes = original_presented_minutes
	environment._presented_daylight = original_daylight
	environment._presentation_initialized = original_initialized
	environment.reduced_motion = original_reduced
	print("PHASE ONE LIGHT CONTINUITY PASS: four times, narrative tint, fade midpoint, reentry, reduced motion")
	quit()
