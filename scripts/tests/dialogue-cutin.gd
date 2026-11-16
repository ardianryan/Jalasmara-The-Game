extends SceneTree

const OUTPUT := "res://../artifacts/godot/dialogue-cutin"
const LONG := "Ingatan bukanlah benda mati, Nala. Ia mengalir seperti air pasang. **Kabut Nir-Aksara** menidurkan akal sehat warga kita. "

func _initialize() -> void:
	_run.call_deferred()

func _settle() -> void:
	for frame in range(6): await process_frame

func _run() -> void:
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var scene:=TextureRect.new()
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	scene.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	scene.texture=load("res://resources/art/cinematics-v2/kedai-interior.png")
	root.add_child(scene)
	var dialogue:Control=load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(dialogue)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=physical
		await _settle()
		dialogue.present("Mbah Wira",LONG,"thinking")
		await _settle()
		dialogue.text_view.visible_characters=-1
		await _settle()
		dialogue._refresh_scroll_hint()
		var portrait:Control=dialogue.portrait
		var viewport:Rect2=root.get_visible_rect()
		var panel:Rect2=dialogue.get_global_rect()
		var portrait_rect:Rect2=portrait.get_global_rect()
		var button:Rect2=dialogue.next_button.get_global_rect()
		var scale:float=root.get_final_transform().x.length()
		var scroll_bar:VScrollBar=(dialogue.get("_scroll") as ScrollContainer).get_v_scroll_bar()
		var hint:Label=dialogue.get("_scroll_hint")
		if scroll_bar.max_value-scroll_bar.page>1 and hint.get_meta("has_space",false):
			assert(hint.visible,"Overflow must have a visible scroll hint when space permits")
		assert(viewport.grow(1).encloses(panel),"Dialogue panel must stay on screen")
		assert(viewport.grow(1).encloses(portrait_rect),"Comic cut-in must not leave the screen")
		assert(portrait_rect.position.y<panel.position.y-8*viewport.size.x/physical.x,"Portrait must protrude above the wooden frame")
		assert(panel.grow(1).encloses(button),"Continue target must stay inside the frame")
		assert(button.size.x*scale>=47.99 and button.size.y*scale>=47.99,"Continue target must stay touch-sized")
		assert(dialogue.text_view.get_theme_font_size("normal_font_size")*scale>=15.99,"Dialogue body must stay readable")
		assert(panel.size.y/viewport.size.y<=(.30 if physical.x<physical.y else .32)+.003,"Dialogue must leave the world visible")
		print("CUTIN GEOMETRY ",physical," panel=",panel," portrait=",portrait_rect," button=",button," fraction=",panel.size.y/viewport.size.y)
		if OS.get_environment("DIALOGUE_CAPTURE")=="1":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT+"/mbah-%sx%s.png"%[physical.x,physical.y])
		dialogue.present("Mbah Wira",LONG.repeat(8),"shock")
		await _settle()
		var scroll:ScrollContainer=dialogue.get("_scroll")
		var bar:=scroll.get_v_scroll_bar()
		assert(bar.max_value-bar.page>1.0,"Long authored lines must remain scrollable")
		var key:=InputEventKey.new()
		key.pressed=true
		key.physical_keycode=KEY_PAGEDOWN
		dialogue._input(key)
		assert(scroll.scroll_vertical>0,"Keyboard must reach hidden dialogue text")
		assert(scroll.get_v_scroll_bar().max_value-scroll.get_v_scroll_bar().page>scroll.scroll_vertical,"Long dialogue must have multiple readable pages")
		root.get_node("EnvironmentState").reduced_motion=true
		dialogue.present("Mbah Wira",LONG,"angry")
		assert(dialogue.portrait.scale==Vector2.ONE,"Reduced motion must disable the portrait bounce")
		root.get_node("EnvironmentState").reduced_motion=false
		dialogue.present("Ki Lurah Wirabhumi",LONG,"neutral")
		await _settle()
		assert(dialogue.get_global_rect().grow(1).encloses(dialogue.nameplate.get_global_rect()),"Long speaker names must fit in the panel")
		assert(dialogue.get_global_rect().grow(1).encloses(dialogue.next_button.get_global_rect()),"Long speaker names must leave the action reachable")
	dialogue.free()
	scene.free()
	print("DIALOGUE CUT-IN PASS: protruding portraits, compact tactile frame, 16px text, 48px actions, keyboard scroll, reduced motion")
	quit()
