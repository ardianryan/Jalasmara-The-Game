extends SceneTree

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	root.size=Vector2i(667,375)
	root.get_node("CalendarSync").set_process(false)
	var state=root.get_node("GameState")
	state.player={"inventory":[{"fragmentId":"klorofil","stars":3,"quantity":1}]}
	state.homestead={"pantry":{"kangkung":1}}
	state.shift={"customers":[{"id":"ui_recipe","customer":"Warga","complaint":"Racikan","fragmentId":"klorofil"}],"served":[]}
	var scene=load("res://scripts/Main.gd").new()
	var hud=load("res://scripts/GameHud.gd").new()
	root.add_child(hud)
	scene.hud=hud
	scene.nala=load("res://scripts/Player.gd").new()
	scene.ui=Control.new()
	hud.add_child(scene.ui)
	scene._kedai_customer()
	for frame in range(4): await process_frame
	var check:CheckButton=scene.modal.find_children("*","CheckButton",true,false)[0]
	assert(root.gui_get_focus_owner()==check,"Kedai must focus the enabled garden option without requiring a pointer")
	var scale:float=root.get_final_transform().x.length()
	assert(check.size.y*scale>=56 and check.get_theme_font_size("font_size")*scale>=16)
	var key:=InputEventKey.new()
	key.keycode=KEY_SPACE
	key.physical_keycode=KEY_SPACE
	key.pressed=true
	root.push_input(key)
	await process_frame
	key.pressed=false
	root.push_input(key)
	await process_frame
	assert(check.button_pressed,"Space must toggle the garden option")
	key.keycode=KEY_TAB
	key.physical_keycode=KEY_TAB
	key.pressed=true
	root.push_input(key)
	await process_frame
	assert(root.gui_get_focus_owner().text.contains("3 bintang"),"Tab reaches the fragment action")
	state.homestead.pantry.kangkung=0
	scene._kedai_customer()
	for frame in range(4): await process_frame
	assert(root.gui_get_focus_owner().text.contains("3 bintang"),"Disabled pantry option must not trap focus")
	state.shift.served=["ui_recipe"]
	scene._kedai_customer()
	for frame in range(4): await process_frame
	assert(root.gui_get_focus_owner().text=="Tutup kedai · pulang beristirahat","Completed service must focus the close action")
	scene.nala.free()
	hud.free()
	scene.free()
	state.player={}
	state.shift={}
	var audio=root.get_node("AudioManager")
	audio.set_process(false)
	for child in audio.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream=null
	await create_timer(.1).timeout
	print("KEDAI FOCUS PASS: actual667x375 panel, enabled first action, Space/Tab, disabled-stock skip,56pxgardencontrol/16pxtext and completed-shift close focus; no network calls")
	quit()
