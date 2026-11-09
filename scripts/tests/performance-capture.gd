extends SceneTree

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var diagnostics=load("res://scripts/Diagnostics.gd")
	diagnostics.set_enabled(false)
	diagnostics.set_capture(false)
	assert(diagnostics.performance_sample().is_empty())
	diagnostics.set_capture(true)
	assert(diagnostics.capture_enabled())
	assert(not diagnostics.enabled(),"Device capture must not enable full game/account/world snapshots")
	var sample:Dictionary=diagnostics.performance_sample(root.get_node("ViewportLayout"))
	for key in ["fps","processMs","physicsMs","drawCalls","renderObjects","quality"]:
		assert(sample.has(key),"Opt-in capture needs real Godot monitor values")
	for key in ["player","world","email","inventory","homestead","calendar"]:
		assert(not sample.has(key),"Device metrics must not include account or progress state")
	diagnostics.set_capture(false)
	assert(diagnostics.performance_sample().is_empty(),"Stopping capture must stop release monitor sampling")
	diagnostics.set_enabled(true)
	diagnostics.set_capture(true)
	diagnostics.set_capture(false)
	assert(diagnostics.enabled(),"Stopping device capture must preserve independently enabled QA diagnostics")
	diagnostics.set_enabled(false)
	var layout=root.get_node("ViewportLayout")
	var saved_control:Rect2=layout.get("_host_control")
	var hud=load("res://scripts/GameHud.gd").new()
	hud.touch_enabled=true
	root.add_child(hud)
	for size in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=size
		layout.set("_host_control",Rect2())
		for frame in range(5): await process_frame
		hud.update_state({"area":"Bandar Hujung","coins":525,"diving":false,"action":"Bicara dengan Mbah Wira","canInteract":true,"clock":"20:30","weather":"Hujan ringan"})
		for frame in range(3): await process_frame
		var menu:Rect2=layout.host_control_bounds()
		assert(root.get_visible_rect().encloses(menu),"Host menu must stay on screen")
		assert(not menu.intersects(hud.get("_identity_plate").get_global_rect()),"Night identity must leave the host Menu free")
		for button in hud.get("_utilities"):
			assert(not menu.intersects(button.get_global_rect()),"Host menu must leave every utility touch target free")
		var scale:float=root.get_final_transform().x.length()
		print("HOST MENU METRICS ",size," physical ",menu.size*scale," logical ",menu," transform ",root.get_final_transform())
		assert(menu.size.x*scale>=63.9 and menu.size.y*scale>=47.9,"Host reservation matches the CSS64x48 target within subpixel viewport rounding")
	layout.set("_host_control",saved_control)
	hud.free()
	print("DEVICE CAPTURE PASS: opt-in real monitors without full snapshots, stop restores QA state, compact host Menu clearance at667/844/390/1440")
	quit()
