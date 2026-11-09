extends SceneTree

func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for frame in range(8): await process_frame
func find_button(scene,prefix:String) -> Button:
	for button in scene.modal.find_children("*","Button",true,false):
		if button.text.begins_with(prefix): return button
	return null
func run() -> void:
	root.get_node("CalendarSync").set_process(false)
	var state:=root.get_node("GameState")
	state.dive={}
	state.player={"inventory":[{"fragmentId":"klorofil","stars":3,"quantity":1}],"progress":{"day":2}}
	state.catalog={"fragments":JSON.parse_string(FileAccess.get_file_as_string("res://../scripts/fixtures/ui-fragments.json"))}
	state.homestead={"pantry":{"kangkung":1,"jahe":2,"ikan_seruni":1}}
	state.homestead_definitions={"servings":{"kangkung":{"itemId":"kangkung","name":"Kangkung kebun"},"jahe":{"itemId":"jahe","name":"Jahe pesisir"},"ikan_seruni":{"itemId":"ikan_seruni","name":"Ikan seruni budidaya"}}}
	var recipes:Array=JSON.parse_string(FileAccess.get_file_as_string("res://../scripts/fixtures/ui-recipes.json"))
	var actual_recipe:Dictionary={}
	for recipe in recipes:
		if recipe.id=="akar": actual_recipe=recipe
	for recipe in recipes: assert(actual_recipe.complaint.length()>=recipe.complaint.length(),"Use the longest actual authored complaint")
	state.shift={"id":"ui-only","customers":[actual_recipe],"served":[]}
	var api:=root.get_node("ApiClient")
	var original_script:Script=api.get_script()
	api.set_script(load("res://../scripts/tests/support/ui-api-capture.gd"))
	var scene=load("res://scripts/Main.gd").new()
	var hud=load("res://scripts/GameHud.gd").new()
	root.add_child(hud)
	scene.hud=hud
	scene.nala=load("res://scripts/Player.gd").new()
	scene.status=Label.new()
	scene.ui=Control.new()
	hud.add_child(scene.ui)
	var capture:=OS.get_environment("UI_CAPTURE")=="1"
	var output:="res://../artifacts/godot/overnight-ui"
	if capture: DirAccess.make_dir_recursive_absolute(output)
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844),Vector2i(1440,900)]:
		root.size=physical
		await settle()
		scene._kedai_customer()
		await settle()
		var scale:float=root.get_final_transform().x.length()
		var rect:Rect2=scene.modal.get_global_rect()
		var initial_scroll:ScrollContainer=scene.modal.find_children("*","ScrollContainer",true,false)[0]
		var context:Control=scene.modal.get_meta("service_header")
		for label in context.get_children():
			assert(not initial_scroll.is_ancestor_of(label),"Customer context must stay outside the option scroller")
			assert(rect.grow(1).encloses(label.get_global_rect()),"Pinned customer text stays inside the panel")
		assert(root.get_visible_rect().grow(1).encloses(rect))
		print("SERVICE RECT ",physical," ",rect," scale ",scale," min ",scene.modal.get_combined_minimum_size())
		assert(rect.size.x*scale<=421,"Night tray has a420physicalpx width cap")
		assert(rect.get_area()/root.get_visible_rect().get_area()<=.60,"Night service must leave most world area visible")
		for label in scene.modal.find_children("*","Label",true,false): assert(label.get_theme_font_size("font_size")*scale>=16)
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/night-service-%sx%s.png"%[physical.x,physical.y])
		var check:=scene.modal.find_children("*","CheckButton",true,false)[0] as CheckButton
		assert(root.gui_get_focus_owner()==check,"Pantry checkbox remains first usable control")
		var select:OptionButton
		for control in scene.modal_box.find_children("*","OptionButton",true,false): select=control
		assert(select!=null and select.item_count==3)
		assert(select.get_item_metadata(1)=="jahe")
		assert(select.get_popup().get_theme_font_size("font_size")*scale>=16,"Pantry popup keeps readable body text")
		assert(select.get_popup().get_theme_constant("v_separation")*scale>=28,"Popup rows preserve touch spacing")
		check.button_pressed=true
		select.select(1)
		var recipe:=find_button(scene,"Benih Hayati")
		var before:int=api.get("calls").size()
		recipe.pressed.emit()
		recipe.pressed.emit()
		await settle()
		assert(api.get("calls").size()==before+1,"An in-flight serving cannot submit twice")
		var request:Dictionary=api.get("calls").back()
		assert(request.path=="/kedai/serve" and request.body.gardenItemId=="jahe" and request.body.gardenIngredient)
		assert(request.body.fragmentId=="klorofil" and request.body.stars==3)
		var notes:=find_button(scene,"Baca bukti lapangan")
		notes.grab_focus()
		notes.pressed.emit()
		await settle()
		assert(notes.text=="Tutup bukti lapangan")
		for label in context.get_children(): assert(scene.modal.get_global_rect().grow(1).encloses(label.get_global_rect()),"Expanded notes cannot hide customer context")
		assert(root.get_visible_rect().grow(1).encloses(scene.modal.get_global_rect()))
		var scroll:ScrollContainer=scene.modal.find_children("*","ScrollContainer",true,false)[0]
		assert(scroll.get_global_rect().grow(2).encloses(notes.get_global_rect()),"Expanded notes keep their focused toggle reachable")
		if capture:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output+"/night-service-notes-%sx%s.png"%[physical.x,physical.y])
		scene._close()
	# Existing kangkung-only Space/Tab path has no extra dropdown stop.
	state.homestead.pantry={"kangkung":1}
	scene._kedai_customer()
	await settle()
	assert(scene.modal.find_children("*","CheckButton",true,false)[0] is CheckButton)
	assert(scene.modal_box.find_children("*","OptionButton",true,false).is_empty())
	scene._close()
	scene.nala.free()
	scene.status.free()
	hud.free()
	scene.free()
	api.set_script(original_script)
	print("NIGHT SERVICE UI PASS:4physicalviewports,420px tray cap, readable text, notes/focus,3pantrychoices, actual button→jahe payload and duplicate-input guard; captured mock only, no server transaction")
	quit()
