extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var phase := OS.get_environment("HUD_FOOTPRINT_PHASE")
	if phase.is_empty(): phase="after"
	assert(phase in ["before", "after"])
	var output := "res://../artifacts/godot/overnight-hud-footprint/" + phase
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var report: Dictionary = {}
	for physical in [Vector2i(1440,900), Vector2i(667,375), Vector2i(390,844)]:
		root.size = physical
		for frame in range(3): await process_frame
		var hud = load("res://scripts/GameHud.gd").new()
		hud.touch_enabled = physical.x < 1000
		root.add_child(hud)
		hud.set_process(false)
		hud.update_state({"area":"Bandar Hujung","coins":525,"weight":4,"capacity":12,"clock":"20:35","weather":"Hujan ringan","canInteract":true,"action":"Bicara dengan Ki Lurah Wirabhumi","diving":false})
		for frame in range(3): await process_frame
		var scale := root.get_final_transform().x.length()
		var view := root.get_visible_rect()
		var metrics: Dictionary = {"physicalViewport":[physical.x,physical.y],"scale":scale,"logicalViewport":[view.size.x,view.size.y],"controls":{},"labels":{}}
		for key in ["_identity_plate","_action","_sound_button","_dpad","_weather_plate","_action_plate"]:
			var control: Control = hud.get(key)
			var rect := control.get_global_rect()
			metrics.controls[key] = {"position":[rect.position.x*scale,rect.position.y*scale],"size":[rect.size.x*scale,rect.size.y*scale],"visible":control.visible}
			assert(view.grow(1).encloses(rect),"Persistent HUD controls must remain inside the viewport: " + key)
		for key in ["_region","_resources","_weather","_action_label"]:
			var label: Label = hud.get(key)
			var font_pixels := label.get_theme_font_size("font_size")*scale
			metrics.labels[key] = font_pixels
			assert(font_pixels >= (16 if hud.touch_enabled else 18),"Persistent text must stay readable: " + key)
			if phase == "after":
				assert(font_pixels <= 21,"Persistent body should not upscale to30px desktop text: " + key)
		if phase == "after":
			for control in [hud.get("_sound_button"),hud.get("_action")]:
				assert(minf(control.size.x,control.size.y)*scale >= 48)
				assert(maxf(control.size.x,control.size.y)*scale <= 65,"Standalone controls must remain compact physical targets")
			assert(hud.get("_identity_plate").size.y*scale <= 83)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/%dx%d-night.png"%[physical.x,physical.y])
		hud.update_state({"area":"Dangkalan Segaran","coins":525,"weight":4,"capacity":12,"clock":"20:35","weather":"Hujan ringan","canInteract":true,"action":"Naik ke dermaga","diving":true,"oxygen":80,"maxOxygen":100,"depth":42})
		for frame in range(2): await process_frame
		var instrument:Control=hud.get("_instrument")
		var stats:=instrument.get_global_rect()
		metrics.controls.oxygen={"position":[stats.position.x*scale,stats.position.y*scale],"size":[stats.size.x*scale,stats.size.y*scale]}
		if phase=="after" and not hud.touch_enabled:
			assert(stats.size.x*scale<=301 and stats.size.y*scale<=170,"Desktop instrument must retain compact, measured physical rows")
			assert(hud.get("_bag").get_theme_font_size("font_size")*instrument.scale.x*scale>=16)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output+"/%dx%d-ocean.png"%[physical.x,physical.y])
		hud.set_modal(true)
		for key in ["_identity_plate","_action","_weather_plate","_action_plate"]:
			assert(not hud.get(key).visible,"Night service reading must hide the persistent gameplay HUD")
		report["%dx%d"%[physical.x,physical.y]] = metrics
		hud.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("HUD FOOTPRINT ",phase," PASS ",JSON.stringify(report))
	quit()
