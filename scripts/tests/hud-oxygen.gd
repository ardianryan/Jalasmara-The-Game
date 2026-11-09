extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var hud=load("res://scripts/GameHud.gd").new()
	root.add_child(hud)
	hud.set_process(false)
	var state={"diving":true,"oxygen":100,"maxOxygen":100,"reducedMotion":false}
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.status=="normal")
	assert(hud.debug_layout().oxygen.lossText=="")
	state.oxygen=36
	hud.update_state(state)
	assert(not hud.debug_layout().oxygen.warning)
	state.oxygen=35
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.status=="low" and hud.debug_layout().oxygen.warning)
	assert(hud.get("_warning").text=="O2 MENIPIS - CARI TANGGA")
	state.oxygen=15
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.status=="critical")
	assert(hud.debug_layout().oxygen.lossText=="-20 O2")
	hud._process(.5)
	var remaining:float=hud.get("_loss_seconds")
	hud.update_state(state)
	assert(is_equal_approx(hud.get("_loss_seconds"),remaining),"Repeated state must not renew feedback")
	state.reducedMotion=true
	hud.update_state(state)
	hud._process(.1)
	assert(hud.debug_layout().oxygen.reducedMotion and hud.get("_instrument").loss_feedback==0)
	hud.set_modal(true)
	assert(not hud.debug_layout().oxygen.visible and not hud.debug_layout().oxygen.warning)
	hud.set_modal(false)
	hud._process(2)
	assert(hud.debug_layout().oxygen.lossText=="" and not hud.get("_oxygen_loss").visible)
	state.maxOxygen=120
	state.oxygen=10
	hud.update_state(state)
	assert(hud.debug_layout().oxygen.lossText=="","Capacity changes must not appear as damage")
	state.diving=false
	hud.update_state(state)
	assert(not hud.debug_layout().oxygen.visible)
	hud.touch_enabled=true
	state.merge({"canInteract":true,"canNet":true,"action":"Amati Taman Sel","coins":525,"weight":4,"capacity":12,"objective":"Amati kebun apung lalu bandingkan dengan hutan dan laut.","clock":"08:35","weather":"Hujan ringan"},true)
	for physical in [Vector2i(667,375),Vector2i(844,390),Vector2i(390,844)]:
		root.size=physical
		for frame in range(5): await process_frame
		var view:=root.get_visible_rect()
		var scale:=root.get_final_transform().x.length()
		var ratio:=1.0/scale
		for diving in [false,true]:
			state.diving=diving
			hud.update_state(state)
			for frame in range(3): await process_frame
			var controls:Array=hud.get("_utilities").duplicate()
			controls.append_array([hud.get("_sound_button"),hud.get("_net"),hud.get("_action"),hud.get("_objective_toggle")])
			for control in controls:
				if not control.visible: continue
				assert(minf(control.size.x,control.size.y)*scale>=48,"Every visible HUD button needs48physical pixels")
				assert(view.grow(1).encloses(control.get_global_rect()),"HUD controls remain within physical screen")
			for label in [hud.get("_warning"),hud.get("_action_label"),hud.get("_resources"),hud.get("_weather")]:
				assert(label.get_theme_font_size("font_size")*scale>=16,"Primary HUD text needs16physical pixels")
				assert(label.size.y>=label.get_theme_font("font").get_height(label.get_theme_font_size("font_size")),"Readable text needs a complete line box")
			var sound:Button=hud.get("_sound_button")
			assert(sound.get_theme_font("font").get_string_size(sound.text,HORIZONTAL_ALIGNMENT_LEFT,-1,sound.get_theme_font_size("font_size")).x<=sound.size.x-4,"Sound label must fit without truncation")
			var menu:=Rect2(Vector2(view.size.x/2-44*ratio,0),Vector2(88*ratio,52*ratio))
			for plate in [hud.get("_identity_plate"),hud.get("_utility_plate")]:
				assert(not menu.intersects(plate.get_global_rect()),"HUD must leave the DOM Menu target clear")
			assert(hud.get("_action_plate").visible)
			assert(hud.get("_weather_plate").visible)
			if diving:
				var bag:Label=hud.get("_bag")
				assert(bag.get_theme_font_size("font_size")*bag.get_global_transform().get_scale().x*scale>=16)
				for text_line in bag.text.split("\n"):
					assert(bag.get_theme_font("font").get_string_size(text_line,HORIZONTAL_ALIGNMENT_LEFT,-1,bag.get_theme_font_size("font_size")).x<=bag.size.x,"Bag amount and kg must fit without ellipsis")
				assert(hud.get("_warning_plate").visible)
				assert(not hud.get("_warning_plate").get_global_rect().intersects(hud.get("_dpad").get_global_rect()),"Critical warning must not overlap the joystick")
	hud.free()
	print("HUD OXYGEN PASS: inclusive35/15 thresholds, labels, authoritative loss delta, no feedback replay, capacity guard, reduced motion, expiry, modal and surface states;667/844landscape+390portrait48px targets/16px text, contrast backing, Menu clearance, joystick clearance")
	quit()
