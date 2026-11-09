extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(844,390)
	var state=root.get_node("GameState")
	var saved:Dictionary=state.dive.duplicate(true)
	state.dive={"id":"ui-only","challenge":{"id":"ui-question","question":{"prompt":"Bagaimana cara menjaga lingkungan perairan bandar?","options":["Mengamati sumber pencemaran sebelum memilih cara penanganannya.","Membuang limbah ke sungai.","Mengabaikan perubahan warna air.","Mencampur bahan pembersih tanpa mengetahui sifat senyawanya."]}}}
	var scene=load("res://scripts/Main.gd").new()
	var hud=load("res://scripts/GameHud.gd").new()
	hud.touch_enabled=true
	root.add_child(hud)
	scene.hud=hud
	scene.nala=load("res://scripts/Player.gd").new()
	scene.ui=Control.new()
	hud.add_child(scene.ui)
	scene.network_busy=true
	scene._show_quiz()
	await process_frame
	var buttons:Array=scene.modal.find_children("*","Button",true,false)
	assert(buttons.size()==4)
	for i in range(4):
		var button:Button=buttons[i]
		assert(button.custom_minimum_size.y>=82)
		assert(button.shortcut.events[0].physical_keycode==KEY_1+i)
		var label:Label=button.get_child(0)
		assert(label.get_theme_font_size("font_size")>=24)
		assert(label.get_theme_font("font").resource_path.ends_with("nunito-sans-latin-400-normal.woff2"))
		assert(label.mouse_filter==Control.MOUSE_FILTER_IGNORE and label.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART)
	var fired:Array[int]=[]
	for i in range(4):
		var index:=i
		buttons[i].pressed.connect(func():fired.append(index))
	buttons[2].grab_focus()
	assert(root.gui_get_focus_owner()==buttons[2],"Quiz answers must accept keyboard focus")
	for i in range(4):
		var key:=InputEventKey.new()
		key.physical_keycode=KEY_1+i
		key.keycode=KEY_1+i
		key.pressed=true
		root.push_input(key)
		await process_frame
		key.pressed=false
		root.push_input(key)
	assert(fired==[0,1,2,3],"Keyboard shortcuts must invoke their exact answer once")
	var tab:=InputEventKey.new()
	tab.keycode=KEY_TAB
	tab.physical_keycode=KEY_TAB
	tab.pressed=true
	root.push_input(tab)
	await process_frame
	assert(root.gui_get_focus_owner()==buttons[3],"Tab must advance to option4")
	var enter:=InputEventKey.new()
	enter.keycode=KEY_ENTER
	enter.physical_keycode=KEY_ENTER
	enter.pressed=true
	root.push_input(enter)
	await process_frame
	enter.pressed=false
	root.push_input(enter)
	assert(fired.back()==3 and fired.size()==5,"Enter must choose focused option once")
	for size in [Vector2i(844,390),Vector2i(667,375),Vector2i(390,844)]:
		root.size=size
		for frame in range(4): await process_frame
		scene._layout_modal()
		buttons[3].grab_focus()
		for frame in range(4): await process_frame
		var transform:Transform2D=root.get_final_transform()
		var visible:Rect2=root.get_visible_rect()
		assert(visible.grow(2).encloses(scene.modal.get_global_rect()),"Quiz modal must fit portrait and landscape")
		for button in buttons:
			assert(button.get_rect().size.x>=285)
			var label:Label=button.get_child(0)
			assert(label.size.x>200 and label.size.y>=24)
			assert(label.get_theme_font_size("font_size")*transform.x.length()>=16.0)
			assert(button.size.y*transform.x.length()>=56.0)
		var scroll:ScrollContainer=scene.modal.get_child(0)
		assert(scroll.follow_focus and scroll.get_global_rect().grow(2).encloses(buttons[3].get_global_rect()),"Focused lower answer must scroll into view")
		print("NARROW QUIZ ",size," logical ",visible.size," transform ",transform," firstAnswer ",buttons[0].get_global_rect()," focus ",root.gui_get_focus_owner().get_class())
	assert(scene.nala.frozen and hud.get("_modal"))
	hud.set_modal(false)
	hud.update_state({"diving":true,"oxygen":15,"maxOxygen":100,"canInteract":true,"canNet":true,"action":"Amati"})
	var controls:Array=hud.get("_utilities").duplicate()
	controls.append_array([hud.get("_sound_button"),hud.get("_net"),hud.get("_action")])
	controls.append_array(hud.get("_dpad").get_children())
	var scale:float=root.get_final_transform().x.length()
	for control in controls:
		assert(minf(control.size.x,control.size.y)*scale>=48.0,"Touch controls must remain48physicalpx")
		assert(root.get_visible_rect().encloses(control.get_global_rect()),"HUD control must remain on logicalscreen")
	print("NARROW TOUCH HUD PASS ",controls.size()," controls >=48px atportrait; critical warning remains visible")
	state.dive.challenge.question.options=["Air","Tanah","Cahaya","Udara"]
	scene._show_quiz()
	for frame in range(4): await process_frame
	scene._layout_modal()
	for frame in range(4): await process_frame
	var short_buttons:Array=scene.modal.find_children("*","Button",true,false)
	assert(short_buttons.size()==4)
	for button in short_buttons:
		assert(button.size.y*scale>=56.0,"Even single-word answers need56physicalpx touch targets")
	print("SHORT ANSWER TOUCH PASS minimum ",short_buttons[0].size.y*scale,"physicalpx at667x375")
	state.dive=saved
	scene.nala.free()
	hud.free()
	scene.free()
	print("QUIZ LAYOUT PASS: actual Main modal at844x390/667x375/390x844,56px short-answer targets,16px body,24px Nunito, wrapping, keyboard1..4/Tab/Enter, focused-row scrolling, pause; no network calls")
	quit()
