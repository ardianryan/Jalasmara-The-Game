extends SceneTree

const BACKDROP := "res://../docs/visual/moodboard-daylight/land-night-667x375.png"
const LINE := "Selama **air pasang** berubah, baca tanda pada batu dan periksa jalur warga sebelum membuka Kedai Waras lagi. Ingat, seluruh rakit di pesisir saling terhubung."

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var output:=OS.get_environment("HUD_AUDIT_OUTPUT")
	if output.is_empty(): output="res://../artifacts/godot/hud-dialogue-night-audit"
	var expect_fixed:=OS.get_environment("HUD_AUDIT_EXPECT_FIXED")!="0"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var source:=Image.load_from_file(ProjectSettings.globalize_path(BACKDROP))
	assert(source!=null and not source.is_empty())
	var world: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	root.get_node("GameState").world=world
	root.get_node("EnvironmentState").reduced_motion=true
	var observations: Array=[]
	for fixture in [{"size":Vector2i(667,375),"touch":true},{"size":Vector2i(844,390),"touch":false}]:
		root.size=fixture.size
		for frame in range(4): await process_frame
		var backdrop:=TextureRect.new()
		backdrop.texture=ImageTexture.create_from_image(source)
		backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		backdrop.stretch_mode=TextureRect.STRETCH_SCALE
		backdrop.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(backdrop)
		var hud=load("res://scripts/GameHud.gd").new()
		hud.touch_enabled=fixture.touch
		root.add_child(hud)
		hud.set_process(false)
		hud.set_navigation(world,"hub",Vector2(1000,1200))
		hud.update_state({"area":"Bandar Hujung","coins":110,"weight":0,"capacity":12,"clock":"20:38","weather":"Hujan ringan","canInteract":true,"action":"Bicara dengan Mbah Wira","diving":false})
		hud.message("Kedai Waras sudah buka. Bicaralah dengan Mbah Wira untuk melayani warga.")
		for frame in range(4): await process_frame
		var scale:=root.get_final_transform().x.length()
		var status:Control=hud.get("_status_panel")
		assert(status.visible)
		assert(bool(status.get("compact_notice")),"Short landscape land notice must use the compact wood and brass treatment")
		assert(status.get_global_rect().size.y*scale<=60.0,"Night notice must leave the play field visible")
		assert(hud.status_label.text=="Kedai Waras sudah buka.","The duplicate instruction belongs in the action prompt, not the notice")
		assert(hud.status_label.tooltip_text=="Kedai Waras sudah buka. Bicaralah dengan Mbah Wira untuk melayani warga.","The notice must retain its full text")
		var action:Button=hud.get("_action")
		var prompt:Control=hud.get("_action_plate")
		var prompt_label:Label=hud.get("_action_label")
		var sound:Button=hud.get("_sound_button")
		assert(minf(action.get_global_rect().size.x,action.get_global_rect().size.y)*scale>=48.0 if fixture.touch else true)
		assert(minf(sound.get_global_rect().size.x,sound.get_global_rect().size.y)*scale>=48.0 if fixture.touch else true)
		assert(bool(prompt.get("compact_notice")),"Action prompt must use the tactile wood and brass plate")
		assert(prompt.get_global_rect().size.x*scale<=252.0,"Action prompt must not become a wide horizontal strip")
		assert(prompt.get_global_rect().end.y<action.get_global_rect().position.y,"Prompt must stay above the action button")
		assert(prompt_label.get_theme_font("font").get_multiline_string_size(prompt_label.text,HORIZONTAL_ALIGNMENT_RIGHT,prompt_label.size.x,prompt_label.get_theme_font_size("font_size")).y<=prompt_label.size.y,"Action text must fit the plate")
		var tag:="%sx%s"%[fixture.size.x,fixture.size.y]
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/"+tag+"-gameplay.png")
		hud.set_modal(true)
		hud.message("Pemberitahuan ini tidak boleh menutup dialog.")
		if expect_fixed: assert(not status.visible,"HUD notice must hide while the dialogue or Kedai modal is open")
		else: assert(status.visible,"Baseline must reproduce the HUD notice leaking over a modal")
		var dialogue=load("res://scripts/DialoguePresenter.gd").new()
		root.add_child(dialogue)
		dialogue.present("Ki Lurah Wirabhumi",LINE,"thinking")
		for frame in range(5): await process_frame
		var viewport:=root.get_visible_rect()
		assert(viewport.grow(1).encloses(dialogue.get_global_rect()))
		var button_rect:Rect2=dialogue.next_button.get_global_rect()
		assert(dialogue.get_global_rect().grow(1).encloses(button_rect))
		assert(minf(button_rect.size.x,button_rect.size.y)*scale>=48.0)
		var body_px:float=dialogue.text_view.get_theme_font_size("normal_font_size")*scale
		assert(body_px>=16.0)
		var bounds:Rect2=dialogue.get_global_rect()
		observations.append({"size":[fixture.size.x,fixture.size.y],"touch":fixture.touch,"statusHidden":not status.visible,"statusRect":status.get_global_rect(),"dialogueRect":bounds,"actionPx":minf(action.get_global_rect().size.x,action.get_global_rect().size.y)*scale,"dialogueButtonPx":minf(button_rect.size.x,button_rect.size.y)*scale,"dialogueBodyPx":body_px,"dialogueViewportFraction":bounds.size.y/viewport.size.y})
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/"+tag+"-dialogue.png")
		dialogue.free()
		hud.message("Pemberitahuan baru selama modal harus menunggu hingga dialog ditutup.")
		hud.set_modal(false)
		assert(status.visible,"Unexpired notice must return after closing the modal")
		hud.free()
		backdrop.free()
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"  "))
	print("HUD DIALOGUE NIGHT AUDIT PASS: ",JSON.stringify(observations))
	quit()
