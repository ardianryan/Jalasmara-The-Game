extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var environment: Node = root.get_node("EnvironmentState")
	var previous_reduced: bool = environment.reduced_motion
	environment.reduced_motion = false
	var frame: Control = load("res://scripts/CutsceneFrame.gd").new()
	root.add_child(frame)
	root.size = Vector2i(667, 375)
	await process_frame
	frame.present("Terjun", {"shot": "Perahu", "tone": "teal"}, 1, 2, "first_dive")
	assert(frame.backdrop_key == "segaran-entry" and frame.backdrop != null)
	assert(not frame.outgoing_plate.visible, "First shot must appear without an empty transition")
	frame._process(0.20)
	var entry_texture: Texture2D = frame.backdrop
	var entry_pan: Vector2 = frame.shot_pan
	frame.present("Segaran", {"shot": "Bawah air", "tone": "teal"}, 2, 2, "first_dive")
	assert(frame.backdrop_key == "segaran-underwater" and frame.backdrop != entry_texture)
	assert(frame.outgoing_plate.visible and frame.outgoing_plate.texture == entry_texture, "Old shot must cover the new shot at the start")
	assert(frame.outgoing_plate.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(frame.outgoing_plate.get_index() < frame.upper.get_index(), "Transition must stay below title and skip controls")
	assert(is_zero_approx(frame.transition_elapsed) and is_zero_approx(frame._transition_progress()))
	frame._process(0.19)
	var half_opacity: float = frame.outgoing_plate.modulate.a
	assert(half_opacity > 0.35 and half_opacity < 0.65, "Backdrop must visibly blend at the midpoint")
	assert(frame.shot_pan.distance_to(entry_pan) > 0.1, "Camera reframing must advance between shots")
	var rect: Rect2 = frame._backdrop_rect()
	assert(rect.position.x <= 0.0 and rect.position.y <= 0.0 and rect.end.x >= 667.0 and rect.end.y >= 375.0, "Reframing exposed an image edge")
	frame._process(0.19)
	assert(not frame.outgoing_plate.visible and frame.outgoing_plate.texture == null, "Finished transition must release its old texture")
	assert(is_equal_approx(frame._transition_progress(), 1.0))
	frame.present("Segaran", {"shot": "Masih di air", "tone": "teal"}, 2, 2, "first_dive")
	assert(not frame.outgoing_plate.visible, "Same backdrop must not restart the transition")
	root.size = Vector2i(844, 390)
	await process_frame
	frame._process(0.50)
	rect = frame._backdrop_rect()
	assert(rect.position.x <= 0.0 and rect.position.y <= 0.0 and rect.end.x >= 844.0 and rect.end.y >= 390.0, "Wide landscape exposed an image edge")
	environment.reduced_motion = true
	frame.present("Terjun", {"shot": "Perahu", "tone": "teal"}, 1, 2, "first_dive")
	assert(not frame.outgoing_plate.visible and frame.outgoing_plate.texture == null, "Reduced motion must skip the transition")
	assert(frame.shot_pan == Vector2.ZERO and not frame.living_plate.visible, "Reduced motion must keep a still plate")
	environment.reduced_motion = false
	frame.present("Segaran", {"shot": "Bawah air", "tone": "teal"}, 2, 2, "first_dive")
	assert(frame.outgoing_plate.visible)
	environment.reduced_motion = true
	frame._process(0.01)
	assert(not frame.outgoing_plate.visible and frame.outgoing_plate.texture == null, "Enabling reduced motion must cancel an active transition")
	assert(frame.shot_pan == Vector2.ZERO)
	frame.free()
	environment.reduced_motion = previous_reduced
	print("PHASE ONE BACKDROP TRANSITION PASS: first/same/different plates, midpoint, completion, 667x375/844x390 and reduced motion")
	quit()
