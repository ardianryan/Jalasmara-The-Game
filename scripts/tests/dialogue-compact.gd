extends SceneTree

const SHORT:="Permukaan yang tenang."
const LONG:="Perhatikan **akar yang tergenang**. Daun menguning bukan selalu berarti kurang pupuk. Amati pori media dan aliran air, lalu bandingkan dengan hutan pesisir. "
const OUTPUT:="res://../artifacts/godot/dialogue-compact"

func _initialize() -> void:
	call_deferred("run")

func settle() -> void:
	for frame in range(5): await process_frame

func run() -> void:
	var capture:=OS.get_environment("DIALOGUE_CAPTURE")=="1"
	var state:Node=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	root.get_node("EnvironmentState").reduced_motion=false
	var background:=TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var backdrop:=OS.get_environment("DIALOGUE_BACKDROP")
	if not backdrop.is_empty(): background.texture=ImageTexture.create_from_image(Image.load_from_file(backdrop))
	root.add_child(background)
	var presenter=load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(presenter)
	var advances:Array=[]
	presenter.advance_requested.connect(func(): advances.append(true))
	var reports:Array=[]
	if capture: DirAccess.make_dir_recursive_absolute(OUTPUT)
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=physical
		await settle()
		for entry in [[SHORT,"neutral","short"],[LONG,"thinking","paragraph"],[LONG.repeat(8)+"CATATAN UTUH","shock","long"]]:
			presenter.present("Mang Ujang",entry[0],entry[1])
			await settle()
			var logical:Rect2=root.get_visible_rect()
			var scale:float=root.get_final_transform().x.length()
			var before:Vector2=presenter.size
			assert(logical.grow(1).encloses(presenter.get_global_rect()))
			assert(presenter.text_view.get_theme_font_size("normal_font_size")*scale>=(17.99 if physical.x>=1024 else 15.99))
			assert(presenter.text_view.get_theme_font_size("normal_font_size")*scale<=24,"Body must remain readable without desktop inflation")
			var action:Rect2=presenter.next_button.get_global_rect()
			assert(action.size.y*scale>=47.99 and action.size.x*scale>=47.99)
			assert(presenter.get_global_rect().grow(1).encloses(action),"Action hit target must stay inside the panel")
			var cap:=.38 if physical.x<physical.y else .32 if physical.y>480 else .34 if entry[2]=="short" else .42
			assert(presenter.size.y/logical.size.y<=cap+.003,"Dialogue must leave the world visible: "+str(presenter.size/logical.size))
			var key:=InputEventKey.new()
			key.pressed=true
			key.physical_keycode=KEY_SPACE
			var prior:=advances.size()
			presenter._input(key)
			await settle()
			assert(presenter.text_view.visible_characters==-1 and advances.size()==prior)
			assert(presenter.size==before,"Typewriter reveal must not grow the tray")
			if entry[2]=="long":
				assert(presenter.text_view.get_parsed_text().ends_with("CATATAN UTUH"))
				presenter.get("_scroll").scroll_vertical=100000
				await settle()
				assert(presenter.get("_scroll").scroll_vertical>0,"Long authored text must remain scrollable")
			var touch:=InputEventScreenTouch.new()
			touch.index=0
			touch.position=action.get_center()
			touch.pressed=true
			root.push_input(touch,true)
			await process_frame
			touch.pressed=false
			root.push_input(touch,true)
			await process_frame
			assert(advances.size()==prior+1,"Action button advances once after the reveal")
			var tag:="%sx%s-%s"%[physical.x,physical.y,entry[2]]
			reports.append({"tag":tag,"panelFraction":presenter.size.y/logical.size.y,"bodyPx":presenter.text_view.get_theme_font_size("normal_font_size")*scale,"actionPx":action.size.y*scale,"debug":presenter.debug_state()})
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OUTPUT+"/"+tag+".png")
	print("DIALOGUE COMPACT PASS ",JSON.stringify(reports))
	if capture: FileAccess.open(OUTPUT+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(reports,"  "))
	presenter.free()
	background.free()
	quit()
