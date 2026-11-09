extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
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
	for physical in [Vector2i(960,540),Vector2i(667,375),Vector2i(390,844)]:
		root.size=physical
		for frame in range(5): await process_frame
		book._rebuild()
		inventory._build()
		for frame in range(3): await process_frame
		assert(root.get_visible_rect().grow(2).encloses(book.get("_panel").get_global_rect()),"Book panel must fit portrait and landscape")
		assert(root.get_visible_rect().grow(2).encloses(inventory.get_child(1).get_global_rect()),"Inventory panel must fit portrait and landscape")
		var ratio:float=root.get_visible_rect().size.x/float(root.size.x)
		assert(float(book.get("_font_size"))/ratio>=16,"Book body text remains at least16 physical pixels")
		assert(float(inventory.get("_body_size"))/ratio>=16,"Inventory body text remains at least16 physical pixels")
		assert(float(book.get("_target"))/ratio>=48)
		assert(float(inventory.get("_target"))/ratio>=48)
	book.free()
	inventory.free()
	print("FIELD BOOK INVENTORY PASS: real discovery locks, consumed concept persistence, instantiated responsive controls and temporary loot")
	quit()
