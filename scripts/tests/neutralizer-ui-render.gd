extends SceneTree

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	print("NEUTRALIZER FIXTURE START")
	var destination := "res://../artifacts/godot/neutralizer/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(destination))
	var backdrop := TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = load("res://resources/art/cinematics-v1/tamansari.png")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(backdrop)
	for dimensions in [Vector2i(960,540),Vector2i(667,375)]:
		print("NEUTRALIZER FIXTURE SIZE ",dimensions)
		root.size = dimensions
		var hud = load("res://scripts/GameHud.gd").new()
		hud.touch_enabled = dimensions.x < 900
		root.add_child(hud)
		hud.update_state({"area":"Pelataran Kuno Tamansari","diving":true,"bossMode":true,"oxygen":126,"maxOxygen":220,"depth":100.0,"weight":0,"capacity":24,"coins":410,"objective":"Netralisir katup racun Gajah Mina, lalu kunci resonansi dengan Jala Kognisi.","action":"Tembak kapsul penetral, lalu kunci dengan jala","canInteract":false,"canShoot":true,"canNet":true})
		print("NEUTRALIZER FIXTURE HUD READY")
		for i in range(6): await process_frame
		print("NEUTRALIZER FIXTURE FRAMES READY")
		await RenderingServer.frame_post_draw
		var path := destination+"hud-boss-%dx%d.png" % [dimensions.x,dimensions.y]
		assert(root.get_texture().get_image().save_png(path)==OK)
		hud.free()
		await process_frame
	print("NEUTRALIZER HUD RENDER PASS: keyboard and compact touch action labels over owned Tamansari fixture")
	quit()
