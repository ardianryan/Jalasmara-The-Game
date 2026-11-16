extends SceneTree

const OUTPUT := "res://../artifacts/godot/phase-one-portrait-fallback"
const LINE := "Di kedalaman 300 meter, PT Cakrawala Sintetis menancapkan bor Reaktor Inti Samudra. Pantas kakekmu menyelam ke sana dan belum kembali, Nala."
const RESIDENTS := [
	{"name":"Ki Lurah Wirabhumi","id":"npc_ki_lurah_wirabhumi","appearance":0},
	{"name":"Saras","id":"npc_saras","appearance":5},
	{"name":"Kinasih","id":"npc_kid_kinasih","appearance":8},
	{"name":"Gito","id":"npc_kid_gito","appearance":10},
]

func _initialize() -> void:
	_run.call_deferred()

func _settle() -> void:
	for frame in range(8): await process_frame

func _run() -> void:
	var state:Node=root.get_node("GameState")
	state.player={"appearance":"female_nusantara"}
	root.get_node("EnvironmentState").reduced_motion=true
	var backdrop:=TextureRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.texture=load("res://resources/art/cinematics-v2/griya-map-room.png")
	root.add_child(backdrop)
	var dialogue:Control=load("res://scripts/DialoguePresenter.gd").new()
	root.add_child(dialogue)
	var capture:=OS.get_environment("PORTRAIT_CAPTURE")=="1"
	if capture: DirAccess.make_dir_recursive_absolute(OUTPUT)
	for physical in [Vector2i(667,375),Vector2i(844,390)]:
		root.size=physical
		await _settle()
		for residents in [[],RESIDENTS]:
			state.world={} if residents.is_empty() else {"surface_hub":{"residents":residents}}
			for speaker in ["Ki Lurah Wirabhumi","Saras","Kinasih","Gito"]:
				dialogue.present(speaker,LINE,"thinking")
				await _settle()
				var portrait:TextureRect=dialogue.portrait
				assert(portrait.texture!=null and portrait.visible,"Missing cut-in portrait: "+speaker)
				assert((dialogue.get("_portrait_slot") as Control).visible,"Portrait slot must be visible: "+speaker)
				var screen:=root.get_visible_rect().grow(1)
				var panel:=dialogue.get_global_rect()
				var bust:=portrait.get_global_rect()
				var button:Rect2=dialogue.next_button.get_global_rect()
				var text:Rect2=dialogue.text_view.get_global_rect()
				var scale:float=root.get_final_transform().x.length()
				assert(screen.encloses(panel) and screen.encloses(bust),"Panel and bust must stay on screen: "+speaker)
				assert(panel.grow(1).encloses(button),"Continue button must stay in panel: "+speaker)
				assert(bust.end.x<text.position.x,"Bust cannot cover the dialogue text: "+speaker)
				assert(button.size.x*scale>=47.99 and button.size.y*scale>=47.99,"Continue must remain touch-sized")
				if capture and speaker in ["Ki Lurah Wirabhumi","Kinasih"]:
					dialogue.text_view.visible_characters=-1
					await RenderingServer.frame_post_draw
					var source:="world" if not residents.is_empty() else "empty"
					root.get_texture().get_image().save_png(OUTPUT+"/%s-%s-%sx%s.png"%[speaker.to_snake_case(),source,physical.x,physical.y])
				print("PORTRAIT ",physical," world=",not residents.is_empty()," speaker=",speaker," bust=",bust," text=",text," button=",button)
	dialogue.free()
	backdrop.free()
	print("PHASE ONE PORTRAIT FALLBACK PASS")
	quit()
