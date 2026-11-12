extends SceneTree
var folder := "res://../artifacts/godot/plan04-ui/"
func _initialize() -> void: call_deferred("run")
func settle(frames := 5) -> void:
	for frame in range(frames): await process_frame
	await RenderingServer.frame_post_draw
func capture(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(folder+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var state=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"coins":525,"appearance":"male_nusantara","progress":{"day":2,"stage":"dive","missions":["daun_kuning","air_keruh","takaran"]},"inventory":[{"fragmentId":"klorofil","stars":3,"quantity":2},{"fragmentId":"ekosistem","stars":2,"quantity":1},{"fragmentId":"rasio","stars":3,"quantity":4}]}
	state.catalog={"fragments":[{"id":"klorofil","name":"Benih Hayati","subject":"Biologi","description":"Ingatan tentang respirasi akar, fotosintesis, osmosis, dan perputaran unsur hara.","weight":1},{"id":"ekosistem","name":"Jejak Ekosistem","subject":"Lingkungan","description":"Hubungan produsen, konsumen, dan pengurai di Palung Smara.","weight":1},{"id":"rasio","name":"Keong Rasio","subject":"Matematika","description":"Perbandingan takaran dalam kehidupan warga.","weight":1}],"recipes":[{"id":"daun_kuning","day":1,"customer":"Bu Darmi","fragmentId":"klorofil","complaint":"Daun kebun apung menguning.","solution":"Periksa akar, cahaya, air, dan unsur hara."}]}
	state.adventure={"discoveries":["garden_leaf","garden_root","forest_canopy","nitrogen"],"keyItems":[]}
	state.homestead={"permit":false}
	var background:=TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var own_capture:=Image.load_from_file(ProjectSettings.globalize_path("res://../artifacts/godot/land-3d/kedai.png"))
	if own_capture!=null: background.texture=ImageTexture.create_from_image(own_capture)
	root.add_child(background)
	for physical in [Vector2i(960,540),Vector2i(667,375),Vector2i(390,844)]:
		root.size=physical
		await settle()
		var tag:="%dx%d" % [physical.x,physical.y]
		var hud=load("res://scripts/GameHud.gd").new()
		hud.touch_enabled=physical.x<900
		root.add_child(hud)
		var hud_state={"area":"Bandar Hujung","coins":525,"weight":4.0,"capacity":12.0,"objective":"Amati kebun apung Bu Darmi, bandingkan dengan hutan pesisir, lalu selami Hutan Lamun Wringin.","action":"Bicara dengan Mbah Wira","canInteract":true,"canNet":false,"diving":false,"clock":"08:35","weather":"Cerah"}
		hud.update_state(hud_state)
		hud.set_navigation(state.world,"hub",Vector2(595,650))
		await capture(tag+"-hud-land")
		hud_state.merge({"area":"Dangkalan Segaran","diving":true,"oxygen":31,"maxOxygen":120,"canNet":true,"depth":24,"action":"Amati Taman Sel"},true)
		hud.update_state(hud_state)
		await capture(tag+"-hud-dive")
		hud.message("Ikan Lentera Alkalin tertangkap · 3 bintang · 2/24 kg")
		await capture(tag+"-hud-dive-notice")
		hud.set_modal(true)
		var layer:=CanvasLayer.new()
		layer.layer=20
		root.add_child(layer)
		var dialogue=load("res://scripts/DialoguePresenter.gd").new()
		layer.add_child(dialogue)
		dialogue.present("Mbah Wira","Perhatikan **akar yang tergenang**. Daun menguning bukan selalu berarti kurang pupuk. Amati pori media dan aliran air, lalu bandingkan dengan hutan pesisir.")
		dialogue.text_view.visible_characters=-1
		await capture(tag+"-dialogue")
		dialogue.free()
		var book=load("res://scripts/FieldBook.gd").new()
		layer.add_child(book)
		book.set("_tab",1)
		book.set("_detail_open",physical.x<900)
		book._rebuild()
		await capture(tag+"-field-book")
		book.free()
		var inventory=load("res://scripts/InventoryView.gd").new()
		inventory.configure(state.player,{"weight":3,"capacity":12,"loot":[{"fragmentId":"klorofil","stars":2}]})
		layer.add_child(inventory)
		await capture(tag+"-inventory")
		inventory.free()
		layer.free()
		hud.free()
		await settle()
	print("PLAN04 UI RENDER PASS: 18 native component captures over owned reference screenshot; UI fixtures, not live-level performance measurements")
	quit()
