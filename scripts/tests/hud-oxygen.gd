extends SceneTree
func _initialize() -> void: call_deferred("run")

func _portrait_stats(hud:CanvasLayer,view:Rect2,scale:float) -> void:
	var instrument:Control=hud.get("_instrument")
	var panel:=instrument.get_global_rect()
	assert(view.encloses(panel),"Portrait stats must fit inside the actual expanded viewport")
	assert(panel.size.x*scale<=301 and panel.size.y*scale<=170,"Readable portrait rows must remain compact")
	var labels:Array=[]
	for key in ["_oxygen_caption","_oxygen_text","_oxygen_max","_depth_caption","_depth","_bag","_oxygen_loss"]:
		var label:Label=hud.get(key)
		if not label.visible: continue
		assert(label.get_theme_font_size("font_size")*label.get_global_transform().get_scale().x*scale>=16,"Every portrait stat needs16physical pixels")
		assert(panel.grow(.01).encloses(label.get_global_rect()),"Stat text must stay inside its actual artwork frame: "+key)
		for line in label.text.split("\n"):
			assert(label.get_theme_font("font").get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x<=label.size.x,"Every stat line must fit without clipping or ellipsis: "+key)
		for other in labels:
			assert(not label.get_global_rect().intersects(other.get_global_rect()),"Portrait stat fields must not overlap")
		labels.append(label)
	var bar:Rect2=instrument.get_global_transform()*instrument.bar_rect
	for label in labels:
		assert(not bar.intersects(label.get_global_rect()),"The oxygen bar must not pass through a stat line")
	for control in [hud.get("_dpad"),hud.get("_action"),hud.get("_net"),hud.get("_action_plate")]:
		if control.visible:
			assert(not panel.intersects(control.get_global_rect()),"Portrait stats must leave joystick/action areas clear")

func run() -> void:
	var artwork=load("res://scripts/HudSkin.gd")
	assert(artwork.assets_ready(),"All actual HUD kit frames must be imported; a flat fallback is not visual delivery")
	assert(artwork.panel("dark") is StyleBoxTexture)
	assert(artwork.panel("paper") is StyleBoxTexture)
	for state in ["normal","hover","pressed","selected"]:
		assert(artwork.button(state) is StyleBoxTexture)
	assert(artwork.button("normal").texture!=artwork.button("pressed").texture)
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
			assert(not hud.get("_objective").visible,"Full mission is available through its button, not a persistent four-line banner")
			assert(not hud.get("_utility_plate").visible,"Utility hit targets do not require another oversized outer frame")
			if not diving:
				assert(hud.get("_identity_plate").size.y*scale<=70,"Two-row land identity must stay below70physical pixels")
				var focus:=Rect2(view.size*Vector2(.46,.35),view.size*Vector2(.08,.31))
				for chrome in [hud.get("_identity_plate"),hud.get("_weather_plate"),hud.get("_action_plate"),hud.get("_dpad")]:
					assert(not focus.intersects(chrome.get_global_rect()),"Default land HUD must leave the central player area unobstructed")
			var sound:Button=hud.get("_sound_button")
			assert(sound.icon!=null,"Mute status uses the actual colored sound icon with accessible tooltip")
			assert(not sound.tooltip_text.is_empty())
			assert(sound.get_theme_font("font").get_string_size(sound.text,HORIZONTAL_ALIGNMENT_LEFT,-1,sound.get_theme_font_size("font_size")).x<=sound.size.x-4,"Sound label must fit without truncation")
			var menu:Rect2=root.get_node("ViewportLayout").host_control_bounds()
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
				if physical.x<physical.y: _portrait_stats(hud,view,scale)
				else:
					assert(hud.get("_instrument").size.y==140 and hud.get("_instrument").bar_rect==Rect2(49,87,96,16),"Landscape instrument artwork and default height stay unchanged")
	# Actual browser fixture f695ff9d: portrait390x844, O2 100/100,
	# depth2m, bag0/12kg, rainy night18:40 and the dock-return action.
	root.size=Vector2i(390,844)
	for frame in range(5): await process_frame
	state.merge({"diving":true,"oxygen":100,"maxOxygen":100,"depth":2,"weight":0,"capacity":12,"area":"Dangkalan Segaran","action":"Naik: Tangga pulang ke Bandar Hujung","clock":"18:40","weather":"Hujan ringan","canInteract":true,"canNet":false},true)
	hud.update_state(state)
	_portrait_stats(hud,root.get_visible_rect(),root.get_final_transform().x.length())
	state.oxygen=80
	hud.update_state(state)
	assert(hud.get("_oxygen_loss").visible)
	_portrait_stats(hud,root.get_visible_rect(),root.get_final_transform().x.length())
	if OS.get_environment("HUD_PORTRAIT_CAPTURE")=="1":
		assert(DisplayServer.get_name()!="headless")
		await process_frame
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute("res://../artifacts/godot/hud-portrait")
		root.get_texture().get_image().save_png("res://../artifacts/godot/hud-portrait/ocean390-stats.png")
	var retained_style:StyleBox=hud.get("_utilities")[0].get_theme_stylebox("normal")
	hud.update_state(state)
	assert(hud.get("_utilities")[0].get_theme_stylebox("normal")==retained_style,"State polling must not allocate utility-frame resources every layout")
	var objective_received: Array=[]
	hud.objective_requested.connect(func(text: String):objective_received.append(text))
	hud.get("_objective_toggle").pressed.emit()
	assert(objective_received==[state.objective],"Collapsed objective button still opens the complete real mission")
	for clock in ["08:35","20:35"]:
		state.clock=clock
		hud.update_state(state)
		hud.set_modal(true)
		for element in [hud.get("_identity_plate"),hud.get("_region"),hud.get("_weather_plate"),hud.get("_sound_button")]:
			assert(not element.visible,"Night/day serving and dialogue must hide decorative gameplay chrome")
		hud.set_modal(false)
	hud.free()
	print("HUD OXYGEN PASS: inclusive35/15 thresholds, labels, authoritative loss delta, no feedback replay, capacity guard, reduced motion, expiry, modal and surface states;667/844landscape+390portrait48px targets/16px text; actual ocean390fixture and loss fields fit/disjoint/frame-contained, compact rows, joystick/action clearance; landscape artwork retained")
	quit()
