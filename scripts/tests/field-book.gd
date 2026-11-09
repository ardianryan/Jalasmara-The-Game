extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.get_node("EnvironmentState").reduced_motion=true
	var capture:=OS.get_environment("UI_CAPTURE")=="1"
	var output:="res://../artifacts/godot/overnight-ui"
	if capture: DirAccess.make_dir_recursive_absolute(output)
	var script=load("res://scripts/FieldBook.gd")
	assert(script!=null)
	var state={"player":{"coins":123,"progress":{"day":1,"missions":[]},"inventory":[{"fragmentId":"klorofil","quantity":1,"stars":3}]},"world":{"landmarks":[{"id":"nitrogen","name":"Koral Nitrogen","text":"Unsur hara."}]},"catalog":{"fragments":[{"id":"klorofil","name":"Benih Hayati","description":"Biologi tumbuhan."}],"recipes":[{"id":"daun_kuning","fragmentId":"klorofil","day":1}]},"adventure":{"discoveries":[]},"homestead":{}}
	assert(not script.entries_for(state,"Biota")[0].unlocked)
	state.adventure.discoveries.append("nitrogen")
	assert(script.entries_for(state,"Biota")[0].unlocked)
	assert(script.knows_fragment(state,"klorofil"))
	state.player.inventory=[]
	state.player.progress.missions=["daun_kuning"]
	assert(script.knows_fragment(state,"klorofil"),"Consumed learned fragment remains known after a completed recipe")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.catalog.fragments=JSON.parse_string(FileAccess.get_file_as_string("res://../scripts/fixtures/ui-fragments.json"))
	root.get_node("GameState").catalog=state.catalog
	var book=script.new()
	book.configure(state)
	root.add_child(book)
	await process_frame
	await process_frame
	assert(book.get_child_count()>0)
	var inventory=load("res://scripts/InventoryView.gd").new()
	inventory.configure(state.player,{"weight":2,"capacity":12,"loot":[{"fragmentId":"klorofil","stars":2}]})
	root.add_child(inventory)
	await process_frame
	assert(inventory.get("_items").size()==1)
	assert(inventory.get("_items")[0].temporary)
	for physical in [Vector2i(960,540),Vector2i(667,375),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=physical
		for frame in range(5): await process_frame
		book._rebuild()
		inventory._build()
		for frame in range(3): await process_frame
		assert(root.get_visible_rect().grow(2).encloses(book.get("_panel").get_global_rect()),"Book panel must fit portrait and landscape")
		assert(root.get_visible_rect().grow(2).encloses(inventory.get_child(1).get_global_rect()),"Inventory panel must fit portrait and landscape")
		var ratio:float=root.get_visible_rect().size.x/float(root.size.x)
		assert(float(book.get("_font_size"))/ratio>=16,"Book body text remains at least16 physical pixels")
		assert(float(book.get("_font_size"))/ratio<=24,"Book text must not inflate on desktop")
		assert(float(inventory.get("_body_size"))/ratio>=16,"Inventory body text remains at least16 physical pixels")
		assert(float(inventory.get("_body_size"))/ratio<=24,"Inventory text must not inflate on desktop")
		assert(float(book.get("_target"))/ratio>=48)
		assert(float(inventory.get("_target"))/ratio>=48)
		inventory.hide()
		for tab in range(4):
			book.set("_tab",tab)
			book.set("_detail_open",true)
			book._rebuild()
			for frame in range(5): await process_frame
			assert(root.get_visible_rect().grow(2).encloses(book.get("_panel").get_global_rect()),"All book tabs and detail retain viewport bounds")
			for button in book.find_children("*","Button",true,false):
				assert(button.size.y/ratio>=47.99,"Book navigation remains touch sized")
				if button.text=="Daftar":
					var frame_style:StyleBox=button.get_theme_stylebox("normal")
					var text_width:float=button.get_theme_font("font").get_string_size(button.text,HORIZONTAL_ALIGNMENT_LEFT,-1,button.get_theme_font_size("font_size")).x
					assert(text_width+frame_style.get_margin(SIDE_LEFT)+frame_style.get_margin(SIDE_RIGHT)<=button.size.x,"Back label must fit one complete row on portrait")
			if capture:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(output+"/book-%sx%s-tab%s.png"%[physical.x,physical.y,tab])
		book.hide()
		inventory.show()
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/inventory-%sx%s.png"%[physical.x,physical.y])
		book.show()
	book.free()
	inventory.free()
	print("FIELD BOOK INVENTORY PASS: real discovery locks, consumed concept persistence, instantiated responsive controls and temporary loot")
	quit()
