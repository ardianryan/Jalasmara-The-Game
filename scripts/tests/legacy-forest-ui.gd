extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var script=load("res://scripts/Forest.gd")
	var scene=Node2D.new()
	root.add_child(scene)
	# Attaching after ready exercises UI without starting a forest session or calling the API.
	scene.set_script(script)
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.avatar=script.ForestAvatar.new()
	scene._build_ui()
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844)]:
		root.size=physical
		for frame in range(4): await process_frame
		scene._show_characters()
		for frame in range(6): await process_frame
		var scale:=root.get_final_transform().x.length()
		assert(root.get_visible_rect().grow(2).encloses(scene.dialog.get_global_rect()),"Forest selector fits portrait and landscape")
		assert(scene.dialog_text.get_theme_font_size("normal_font_size")*scale>=16)
		var buttons=scene.dialog.find_children("*","Button",true,false)
		assert(buttons.size()==5)
		for button in buttons:
			assert(button.size.y*scale>=56)
			assert(button.get_theme_font_size("font_size")*scale>=16)
			assert(button.get_theme_color("font_hover_color")==Color("f4ebd9"))
		assert(scene.get("_dialog_scroll").follow_focus)
		scene._close_dialog()
		assert(not scene.modal_open)
	scene.avatar.free()
	scene.free()
	print("FOREST LEGACY UI PASS: real selector667/844landscape+390portrait,56px controls/16px body, five choices, focus scroll and close without API")
	quit()
