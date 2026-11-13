extends Node2D
const PlayerScript = preload("res://scripts/Player.gd")
const WorldScript = preload("res://scripts/World.gd")
const EntitiesScript = preload("res://scripts/Entities.gd")
const BODY_FONT = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const BossMotionScript = preload("res://scripts/BossMotion.gd")
const PHYSICAL_GAIT_RELEASE_ENABLED := false
var land_renderer: Node2D
var nala: CharacterBody2D
var terrain: Node2D
var entities: Node2D
var camera: Camera2D
var hud: CanvasLayer
var ui: Control
var top_label: Label
var objective: Label
var hint: Label
var oxygen: ProgressBar
var money: Label
var modal: PanelContainer
var modal_box: VBoxContainer
var status: Label
var nearby: Dictionary = {}
var network_busy := false
var syncing := false
var sync_clock := 0.0
var refresh_clock := 0.0
var modal_open := false
var net_started := false
var net_released := false
var net_target: Dictionary = {}
var net_time := 0.0
var chain_lines: Array = []
var chain_end: Callable
var phase_seen := ""
var attacks: Array = []
var boss_motion = BossMotionScript.new()
var touch_enabled := false
var flash := 0.0
var last_status := ""
var surface_clock := 0.0
var environment: Node
var dive_lamp: PointLight2D
var port_lamps: Array[PointLight2D] = []
var snapshot_at := 0
var surface_actors: Array[Node2D] = []
var hybrid: Node2D
var world_foley: Node
var previous_outfit := "daily"
var _gait_retry_after_ms := 0
var homestead_ui: CanvasLayer
var field_panel: Control
func _ready() -> void:
	y_sort_enabled = true
	_setup_input()
	terrain = WorldScript.new()
	nala = PlayerScript.new()
	nala.position = _surface_point()
	nala.frozen = true
	add_child(nala)
	world_foley = preload("res://scripts/WorldFoley.gd").new()
	add_child(world_foley)
	world_foley.configure(nala,"hub")
	camera = Camera2D.new()
	camera.zoom = Vector2(.88,.88)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = 6144
	camera.limit_bottom = 3584
	nala.add_child(camera)
	entities = EntitiesScript.new()
	entities.player = nala
	add_child(entities)
	_build_ui()
	environment = preload("res://scripts/EnvironmentEffects.gd").new()
	add_child(environment)
	environment.configure("hub")
	var auth: Dictionary = await ApiClient.get_api("/auth/session")
	if auth.get("user") == null:
		_show_message("Silakan masuk", "Buka Jalasmara melalui halaman login terlebih dahulu.")
		_report_startup_failure()
		return
	var result: Dictionary = await GameState.refresh()
	if not result.get("ok",false):
		_show_message("Koneksi belum tersambung",str(result.get("error","Coba muat ulang halaman.")))
		_report_startup_failure()
		return
	if GameState.homestead.get("inside",false) and GameState.dive.is_empty():
		get_tree().change_scene_to_file("res://scenes/homestead.tscn")
		return
	add_child(terrain)
	move_child(terrain,0)
	nala.surface_traversal.configure(GameState.world.get("landMaps",{}).get("hub",{}))
	nala.land_mask = Callable(terrain,"is_walkable")
	terrain.add_foreground_to(self)
	hybrid = load("res://scripts/hybrid/HybridOcean.gd").new()
	add_child(hybrid)
	hybrid.setup(self)
	_add_lights()
	for district in GameState.world.surface_hub.districts:
		var actor = preload("res://scripts/HubActor.gd").new()
		actor.actor_name = str(district.npc)
		actor.position = Vector2(float(district.x),float(district.y))
		actor.player = nala
		actor.walkable = Callable(terrain,"is_walkable")
		var activity: Dictionary = GameState.world.surface_hub.get("districtActivities",{}).get(str(district.npc),{})
		if not activity.is_empty(): actor.configure_activity(activity)
		add_child(actor)
		surface_actors.append(actor)
	_ensure_residents()
	GameState.changed.connect(_ensure_residents)
	nala.position = _surface_point()
	_restore_player_movement()
	if GameState.dive.is_empty() and is_instance_valid(terrain.scenery) and terrain.scenery.has_method("nearest_walkable"):
		nala.position = terrain.scenery.nearest_walkable(nala.position)
	if str(GameState.surface.get("area","hub"))=="forest" and GameState.dive.is_empty():
		get_tree().change_scene_to_file("res://scenes/forest.tscn")
		return
	nala.land_path.reset(nala.position)
	land_renderer = preload("res://scripts/land/LandWorld3D.gd").new()
	add_child(land_renderer)
	land_renderer.setup(self,nala,camera,"hub")
	nala.input_transform=land_renderer.input_motion
	nala.visual_motion_transform=land_renderer.visual_locomotion
	nala.land_distance_transform=land_renderer.ground_travel_distance
	homestead_ui=preload("res://scripts/HomesteadUI.gd").new()
	add_child(homestead_ui)
	homestead_ui.configure(self,false)
	if not GameState.dive.is_empty():
		await ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":false})
		_enter_water(GameState.dive)
		if GameState.dive.has("challenge"):
			_show_quiz()
	_update_hud()
	if get_tree().has_meta("surface_change_notice"):
		status.text = str(get_tree().get_meta("surface_change_notice"))
		hud.message(status.text)
		get_tree().remove_meta("surface_change_notice")
	if not GameState.shift.is_empty() and GameState.dive.is_empty():
		_kedai_customer()
	elif not GameState.player.has("appearance") and GameState.dive.is_empty():
		_show_character(true)
	elif not GameState.player.progress.get("tutorial",false):
		_story_intro()
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		window.jalasmaraReady = true
		window.parent.postMessage(JavaScriptBridge.get_interface("JSON").parse('{"type":"jalasmara:ready"}'),str(window.location.origin))
func _ensure_residents() -> void:
	var cycle := int(GameState.player.get("progress",{}).get("day",1))
	for resident in GameState.world.get("surface_hub",{}).get("residents",[]):
		var existing: Node2D = null
		for actor in surface_actors:
			if actor.actor_name==resident.name: existing = actor
		if int(resident.cycle)>cycle:
			if existing!=null:
				surface_actors.erase(existing)
				existing.queue_free()
			continue
		if existing!=null: continue
		var actor = preload("res://scripts/HubActor.gd").new()
		actor.actor_name = resident.name
		actor.appearance_index = resident.appearance
		actor.custom_sheet = load("res://resources/art/village-residents-v1.png")
		actor.custom_grid = Vector2i(3,2)
		for point in resident.route: actor.route.append(Vector2(float(point[0]),float(point[1])))
		actor.position = actor.route[0]
		actor.player = nala
		actor.walkable = Callable(terrain,"is_walkable")
		actor.configure_activity(resident)
		actor.set_meta("conversation",resident.line)
		actor.set_meta("evening_conversation",resident.evening)
		add_child(actor)
		surface_actors.append(actor)

func set_interaction_modal(active: bool) -> void:
	modal_open=active
	if is_instance_valid(hud): hud.set_modal(active)
	_restore_player_movement()

func _service_movement_locked() -> bool:
	return not GameState.shift.is_empty() and GameState.dive.is_empty()

func _restore_player_movement() -> void:
	if not is_instance_valid(nala): return
	nala.frozen=modal_open or _service_movement_locked()
	if nala.frozen:
		nala.velocity=Vector2.ZERO
		nala.touch=Vector2.ZERO

func _setup_input() -> void:
	var bindings = {"left":[KEY_A,KEY_LEFT],"right":[KEY_D,KEY_RIGHT],"up":[KEY_W,KEY_UP],"down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"net":[KEY_SPACE],"map":[KEY_M],"journal":[KEY_J],"inventory":[KEY_I],"character":[KEY_C]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
func _build_ui() -> void:
	hud = preload("res://scripts/GameHud.gd").new()
	add_child(hud)
	hud.interact_requested.connect(_interact)
	hud.net_pressed.connect(_start_net)
	hud.net_released.connect(func(): net_released = true)
	hud.map_requested.connect(_show_map)
	hud.journal_requested.connect(_show_journal)
	hud.inventory_requested.connect(_show_inventory)
	hud.character_requested.connect(func(): _show_character(false))
	hud.objective_requested.connect(func(text: String): _show_message("Tujuan perjalanan",text))
	hud.move_changed.connect(func(direction: Vector2): nala.touch = direction)
	status = hud.status_label
	hint = Label.new()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = hud.root_control.theme
	hud.add_child(ui)
	get_viewport().size_changed.connect(_layout_modal)
	ViewportLayout.host_pause_changed.connect(func(paused: bool):
		if not GameState.dive.is_empty():
			ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":paused or modal_open})
	)
func _report_startup_failure() -> void:
	if not OS.has_feature("web"): return
	var window=JavaScriptBridge.get_interface("window")
	window.parent.postMessage(JavaScriptBridge.get_interface("JSON").parse('{"type":"jalasmara:loading","version":1,"phase":"error","downloadedBytes":0,"totalBytes":null}'),str(window.location.origin))

func _ui_font() -> int:
	return preload("res://scripts/UiMetrics.gd").body(self,hud)
func _ui_target() -> float:
	return preload("res://scripts/UiMetrics.gd").target(self,hud)
func _button(parent: Node,text: String,callback: Callable) -> Button:
	var b := Button.new()
	b.text=text
	b.custom_minimum_size.y=_ui_target()
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_override("font",BODY_FONT)
	b.add_theme_font_size_override("font_size",_ui_font())
	preload("res://scripts/HudSkin.gd").apply_button(b)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
func _label(parent: Node,text: String,size := 16) -> Label:
	var label := Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.set_meta("base_font_size",size)
	label.add_theme_font_size_override("font_size",maxi(ceili(size*preload("res://scripts/UiMetrics.gd").ratio(self,hud)),_ui_font()))
	if size<=19: label.add_theme_font_override("font",BODY_FONT)
	parent.add_child(label)
	return label
func _open(title: String, pause_reading := true, compact := false) -> VBoxContainer:
	if modal:
		modal.queue_free()
	modal_open = true
	hud.set_modal(true)
	nala.frozen = true
	modal = PanelContainer.new()
	modal.theme = hud.root_control.theme.duplicate()
	modal.theme.set_color("font_color","Label",Color("302d2a"))
	modal.theme.set_color("default_color","RichTextLabel",Color("302d2a"))
	modal.position = Vector2(155,84)
	modal.size = Vector2(650,420)
	modal.set_meta("compact_result",compact)
	modal.add_theme_stylebox_override("panel",preload("res://scripts/HudSkin.gd").panel("paper"))
	ui.add_child(modal)
	call_deferred("_layout_modal")
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.custom_minimum_size = Vector2.ZERO
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	modal.add_child(scroll)
	modal_box = VBoxContainer.new()
	modal_box.custom_minimum_size.x = 0
	modal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_box.add_theme_constant_override("separation",12)
	scroll.add_child(modal_box)
	_label(modal_box,title,23)
	if pause_reading and not GameState.dive.is_empty():
		ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":true})
	return modal_box

func _layout_modal() -> void:
	if not is_instance_valid(modal) or not modal.is_inside_tree() or modal.get_meta("dialogue",false): return
	var view:=modal.get_viewport().get_visible_rect().size
	var ratio:=preload("res://scripts/UiMetrics.gd").ratio(self,hud)
	var safe:=ViewportLayout.insets()
	var top:=ceilf(60*ratio)+safe.y
	var dimensions:=Vector2(minf(680 if modal.get_meta("compact_result",false) else 900,view.x-32-safe.x-safe.z),minf(800 if view.x<800 else 520,view.y-top-16-safe.w))
	var service:=bool(modal.get_meta("service_tray",false))
	if service:
		var edge:=ceilf(16*ratio)
		var frame:StyleBox=modal.get_theme_stylebox("panel")
		frame.content_margin_left=maxf(22,edge)
		frame.content_margin_right=maxf(22,edge)
		dimensions=Vector2(minf(420*ratio,view.x-edge*2-safe.x-safe.z),minf(view.y-top-edge-safe.w,view.y*(.62 if view.x<view.y else .76)))
	modal.size=dimensions
	modal.position=Vector2((view.x-dimensions.x)/2,top)
	if service:
		modal.position=Vector2(safe.x+(view.x-safe.x-safe.z-dimensions.x)*.5 if view.x<view.y else view.x-safe.z-ceilf(16*ratio)-dimensions.x,view.y-dimensions.y-ceilf(16*ratio)-safe.w)
		modal_box.add_theme_constant_override("separation",ceili(8*ratio))
		var header:BoxContainer=modal.get_meta("service_header",null)
		if is_instance_valid(header):
			header.add_theme_constant_override("separation",ceili(4*ratio))
			(header.get_parent() as BoxContainer).add_theme_constant_override("separation",ceili(8*ratio))
		for row in modal_box.find_children("*","HBoxContainer",true,false): row.add_theme_constant_override("separation",ceili(8*ratio))
	var scroll:=_modal_scroll(modal)
	if is_instance_valid(scroll):
		scroll.custom_minimum_size=Vector2.ZERO
		if is_instance_valid(modal_box): modal_box.custom_minimum_size.x=0
	for label in modal.find_children("*","Label",true,false):
		if label.has_meta("base_font_size"): label.add_theme_font_size_override("font_size",maxi(ceili(int(label.get_meta("base_font_size"))*ratio),_ui_font()))
	for button in modal.find_children("*","Button",true,false):
		button.custom_minimum_size.y=_ui_target()
		preload("res://scripts/HudSkin.gd").apply_button(button)
		button.add_theme_font_size_override("font_size",_ui_font())
		if button is OptionButton:
			var popup:PopupMenu=button.get_popup()
			popup.add_theme_font_override("font",BODY_FONT)
			popup.add_theme_font_size_override("font_size",_ui_font())
			popup.add_theme_constant_override("v_separation",ceili(28*ratio))
	for grid in modal.find_children("*","GridContainer",true,false):
		if grid.get_meta("quiz_answers",false): _layout_quiz_answers(grid,dimensions.x-50)
	if modal.get_meta("compact_result",false) or service:
		modal.set_meta("fit_max_height",dimensions.y)
		_fit_compact_modal.call_deferred(modal)
	_reveal_modal_focus.call_deferred(modal)
func _modal_scroll(target:PanelContainer) -> ScrollContainer:
	for scroll in target.find_children("*","ScrollContainer",true,false): return scroll as ScrollContainer
	return null
func _reveal_modal_focus(target: PanelContainer) -> void:
	if not is_instance_valid(target) or not target.is_inside_tree(): return
	var tree:=target.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(target) or target!=modal or not target.is_inside_tree(): return
	var focused:=target.get_viewport().gui_get_focus_owner()
	var scroll:=_modal_scroll(target)
	if is_instance_valid(scroll) and is_instance_valid(focused) and scroll.is_ancestor_of(focused):
		scroll.ensure_control_visible(focused)
func _fit_compact_modal(target: PanelContainer) -> void:
	# Wrapped labels need the final container width before their height is meaningful.
	if not is_instance_valid(target) or not target.is_inside_tree(): return
	var tree:=target.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(target) or target!=modal or not target.is_inside_tree(): return
	var frame:StyleBox=target.get_theme_stylebox("panel")
	var content_height:=modal_box.get_combined_minimum_size().y+frame.get_margin(SIDE_TOP)+frame.get_margin(SIDE_BOTTOM)
	var header:Control=target.get_meta("service_header") if target.has_meta("service_header") else null
	if is_instance_valid(header):
		content_height+=header.get_combined_minimum_size().y+(target.get_child(0) as VBoxContainer).get_theme_constant("separation")
	var maximum:=float(target.get_meta("fit_max_height",target.size.y))
	target.size.y=minf(maximum,content_height)
	var view:=target.get_viewport().get_visible_rect().size
	var top:=ceilf(60*preload("res://scripts/UiMetrics.gd").ratio(self,hud))+ViewportLayout.insets().y
	if target.get_meta("service_tray",false):
		target.position.y=view.y-target.size.y-ceilf(16*preload("res://scripts/UiMetrics.gd").ratio(self,hud))-ViewportLayout.insets().w
	else:
		target.position.y=top+maxf(0,(view.y-top-16-ViewportLayout.insets().w-target.size.y)/2)

func _layout_quiz_answers(answers: GridContainer,width: float) -> void:
	var view:=preload("res://scripts/UiMetrics.gd").viewport(self,hud).get_visible_rect().size
	answers.columns=1 if view.x<800 else 2
	var column_width:float=(width-12*(answers.columns-1))/answers.columns
	var ratio:=preload("res://scripts/UiMetrics.gd").ratio(self,hud)
	var padding:=Vector2(ceilf(14*ratio),ceilf(12*ratio))
	for answer in answers.get_children():
		var option_label:Label=answer.get_child(0)
		option_label.add_theme_font_size_override("font_size",_ui_font())
		option_label.offset_left=padding.x
		option_label.offset_right=-padding.x
		option_label.offset_top=padding.y
		option_label.offset_bottom=-padding.y
		var measured:=BODY_FONT.get_multiline_string_size(option_label.text,HORIZONTAL_ALIGNMENT_LEFT,maxf(80,column_width-padding.x*2),_ui_font())
		answer.custom_minimum_size=Vector2(0,maxf(_ui_target(),measured.y+padding.y*2))
func _close() -> void:
	if not GameState.shift.is_empty() and GameState.dive.is_empty() and not _can_resume_kedai("Mbah Wira"):
		_kedai_customer()
		return
	if is_instance_valid(field_panel):
		field_panel.queue_free()
		field_panel = null
	if modal:
		modal.queue_free()
		modal = null
	modal_open = false
	hud.set_modal(false)
	_restore_player_movement()
	if not GameState.dive.is_empty():
		ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":ViewportLayout.host_paused})
func _show_message(title: String, text: String) -> void:
	var box := _open(title,true,text.length()<=240 and text.count("\n")<=3)
	_label(box,text)
	_button(box,"Kembali",_close).grab_focus()
func _talk(lines: Array, done := Callable()) -> void:
	chain_lines = lines.duplicate()
	chain_end = done
	_next_line()
func _next_line() -> void:
	if chain_lines.is_empty():
		_close()
		if chain_end.is_valid():
			chain_end.call()
		return
	var line: Dictionary = chain_lines.pop_front()
	if is_instance_valid(modal): modal.queue_free()
	modal_open = true
	hud.set_modal(true)
	nala.frozen = true
	modal = preload("res://scripts/DialoguePresenter.gd").new()
	modal.theme = hud.root_control.theme
	ui.add_child(modal)
	modal.advance_requested.connect(_next_line)
	modal.present(str(line.name),str(line.text),str(line.get("emotion","neutral")))
	if not GameState.dive.is_empty():
		ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":true})
func _story_intro() -> void:
	_talk([
		{"name":"Babak 1 · Kabut dan Kopi Pahit","text":"Bandar Hujung terapung di atas ingatan yang tenggelam. Kabut Nir-Aksara membuat warga lupa ilmu yang dahulu mereka kuasai. Kapal Nala rusak, dan uang sewanya hampir habis."},
		{"name":"Beno","emotion":"happy","text":"Kapalmu bisa kuperbaiki. Gratis? Hampir. Bantu Mbah Wira membuka Kedai Waras, dan jangan sentuh tuas merah di bengkelnya."},
		{"name":"Nala","emotion":"thinking","text":"Baik. Utang kapal dibayar dengan kopi. Sejauh ini rencana hidupku makin masuk akal."},
		{"name":"Mbah Wira","text":"Di bawah dermaga ada ingatan yang mengkristal. Berenanglah. Amati taman tua itu. Tidak semua ilmu datang dari menjawab pertanyaan: banyak yang hanya perlu kamu temukan."},
		{"name":"Petualangan dimulai","text":"WASD / arah: bergerak. E: bicara atau mengamati. Tahan lalu lepas spasi: Jala Kognisi. M: peta, J: jurnal, I: tas. Datangi tangga selam di kanan Galangan Bubat; kembali ke tangga untuk naik."}
	],func():
		await ApiClient.call_api("/game/tutorial",{})
		await GameState.refresh()
		_update_hud()
	)
func _limit_gait_velocity(at: Vector2, speed: Vector2, delta: float) -> Vector2:
	return preload("res://scripts/NalaPhysicalMotion.gd").limit_velocity(land_renderer,at,speed,delta)

func _limit_gait_position(from: Vector2, to: Vector2, delta: float) -> Vector2:
	return preload("res://scripts/NalaPhysicalMotion.gd").limit_position(land_renderer,from,to,delta)

func _gait_capacity(current: bool) -> bool:
	if not PHYSICAL_GAIT_RELEASE_ENABLED: return false
	if str(RenderQuality.get_profile().get("effective","low"))!="balanced": return false
	var fps:=Engine.get_frames_per_second()
	if current:
		if fps<38:
			_gait_retry_after_ms=Time.get_ticks_msec()+30000
			return false
		return true
	return Time.get_ticks_msec()>=_gait_retry_after_ms and fps>=55

func _process(delta: float) -> void:
	EnvironmentState.clock_paused = modal_open or ViewportLayout.host_paused or GameState.dive.has("challenge")
	if not nala:
		return
	var physical_gait: bool = is_instance_valid(land_renderer) and land_renderer.active and GameState.dive.is_empty() and nala.swim_sprite.appearance=="male_nusantara" and nala.outfit in ["daily","explorer"] and _gait_capacity(bool(nala.get_meta("nala_physical_walk_pilot",false)))
	if physical_gait!=bool(nala.get_meta("nala_physical_walk_pilot",false)):
		nala.set_meta("nala_lower_body_pilot",physical_gait)
		nala.set_meta("nala_physical_walk_pilot",physical_gait)
		nala.land_velocity_transform=Callable(self,"_limit_gait_velocity") if physical_gait else Callable()
		nala.land_position_transform=Callable(self,"_limit_gait_position") if physical_gait else Callable()
	terrain.camera_point = nala.position
	if not GameState.player.is_empty():
		EnvironmentState.update_story(int(GameState.player.progress.day),str(GameState.player.progress.stage))
	var submerged := not GameState.dive.is_empty()
	var hybrid_active: bool = is_instance_valid(hybrid) and hybrid.is_active()
	nala.hybrid_visual = hybrid_active or (is_instance_valid(land_renderer) and land_renderer.active)
	entities.visible = not hybrid_active
	if is_instance_valid(terrain.scenery):
		terrain.scenery.visible = not hybrid_active
	if terrain.is_inside_tree() and terrain.underwater != submerged:
		terrain.set_mode(submerged)
		if not submerged:
			terrain.add_foreground_to(self)
	var light_state := EnvironmentState.snapshot()
	var clouds := float(light_state.clouds)
	var daylight := float(light_state.daylight)
	environment.configure("sea" if submerged else "hub")
	if environment.has_method("update_depth"):
		environment.update_depth(maxf(0,(nala.position.y-400)/28))
	if dive_lamp:
		dive_lamp.visible = submerged and not hybrid_active
		var facing := 1.0 if nala.direction >= 0 else -1.0
		dive_lamp.position = Vector2(32.0 * facing,-8.0)
		dive_lamp.rotation = 0.0 if facing > 0 else PI
		dive_lamp.energy = lerpf(0.3,0.85,clampf((nala.position.y-400)/2300,0,1))
	for i in port_lamps.size():
		var lamp := port_lamps[i]
		lamp.visible = not submerged
		var warmth := clampf((0.92-daylight)*1.3+clouds*0.13,0.035,0.9)
		lamp.energy = warmth*(1.0+sin(Time.get_ticks_msec()*0.0023+i*1.7)*0.035)
	camera.limit_right = int(GameState.world.get("hub",{}).get("width",2400)) if not submerged else int(GameState.world.get("width",6144))
	camera.limit_bottom = int(GameState.world.get("hub",{}).get("height",1600)) if not submerged else int(GameState.world.get("height",3584))
	for actor in surface_actors:
		actor.set_meta("land_hidden",is_instance_valid(land_renderer) and land_renderer.active)
		actor.visible = not submerged and not bool(actor.get_meta("land_hidden",false))
	terrain.gardens_restored = GameState.player.get("progress",{}).get("day",1)>=3
	terrain.solved = GameState.adventure.get("puzzles",[])
	flash = maxf(0,flash-delta)
	queue_redraw()
	if GameState.player.is_empty():
		return
	if not GameState.dive.is_empty() and int(GameState.player.get("progress",{}).get("day",1))>=3:
		var boss_active := str(GameState.dive.get("mode",""))=="boss"
		boss_motion.advance(delta,str(GameState.dive.get("id","")),int(GameState.dive.get("hits",0)),_required_hits() if boss_active else 0,modal_open or ViewportLayout.host_paused,boss_active and nala.position.distance_to(BossMotionScript.ANCHOR)<650,bool(GameState.player.get("progress",{}).get("bossDefeated",false)))
	if nala.outfit!=previous_outfit:
		previous_outfit = nala.outfit
		if not submerged:
			hud.message("Bilik Beno · Baju selam, tabung, dan jala terpasang." if nala.outfit=="diving" else "Bilik Beno · Kembali mengenakan baju harian.")
	_find_nearby()
	if Engine.get_process_frames()%10==0:
		_update_hud()
	if status.text != last_status:
		last_status = status.text
		hud.message(last_status)
	if GameState.dive.is_empty() and not modal_open:
		surface_clock += delta
		var moved_on_surface: bool = nala.position.distance_to(_surface_point()) > 0.5 or bool(nala.land_path.needs_flush())
		if moved_on_surface and (surface_clock>1.3 or (bool(nala.land_path.needs_flush()) and surface_clock>1.0)) and not network_busy and not syncing:
			surface_clock = 0
			_sync_surface()
	entities.nearest = str(nearby.get("id",""))
	if OS.has_feature("web") and preload("res://scripts/Diagnostics.gd").enabled() and Time.get_ticks_msec()-snapshot_at>=100:
		snapshot_at = Time.get_ticks_msec()
		var snapshot := {"x":nala.position.x,"y":nala.position.y,"stage":GameState.player.get("progress",{}).get("stage",""),"modal":modal_open,"nearby":str(nearby.get("id","")),"diving":not GameState.dive.is_empty()}
		if is_instance_valid(modal) and modal.has_method("debug_state"): snapshot["dialogue"] = modal.debug_state()
		snapshot["performance"] = preload("res://scripts/Diagnostics.gd").performance_sample(nala)
		snapshot["service"] = _service_debug_status()
		snapshot["outfit"] = nala.outfit
		snapshot["equipment"] = nala.equipment
		snapshot["audio"] = AudioManager.debug_status()
		snapshot["flashlight2d"] = _flashlight_status_2d()
		snapshot["weather"] = EnvironmentState.snapshot()
		snapshot["homestead"] = GameState.homestead
		snapshot["calendar"] = GameState.calendar
		snapshot["homePanel"] = homestead_ui.is_open if is_instance_valid(homestead_ui) else false
		snapshot["land"] = land_renderer.debug_status() if is_instance_valid(land_renderer) else {}
		snapshot["traversal"] = nala.traversal_state
		snapshot["occlusion"] = terrain.scenery.debug_status() if is_instance_valid(terrain) and is_instance_valid(terrain.scenery) and terrain.scenery.has_method("debug_status") else {}
		snapshot["foley"] = world_foley.debug_status() if is_instance_valid(world_foley) else {}
		snapshot["life"] = entities.wildlife.debug_status() if is_instance_valid(entities.wildlife) and entities.wildlife.has_method("debug_status") else {}
		snapshot["hybrid"] = hybrid.debug_status() if is_instance_valid(hybrid) else {"active":false}
		if hud.has_method("debug_layout"):
			snapshot["hud"] = hud.debug_layout()
		JavaScriptBridge.get_interface("window").jalasmaraSnapshot = JavaScriptBridge.get_interface("JSON").parse(JSON.stringify(snapshot))
	if modal_open and is_instance_valid(modal) and modal.get_meta("world_map",false) and Input.is_action_just_pressed("map"):
		_close()
		return
	if not modal_open and not ViewportLayout.host_paused:
		if Input.is_action_just_pressed("interact"):
			_interact()
		if Input.is_action_just_pressed("net"):
			_start_net()
		if Input.is_action_just_released("net"):
			net_released = true
		if Input.is_action_just_pressed("map"):
			_show_map()
		if Input.is_action_just_pressed("journal"):
			_show_journal()
		if Input.is_action_just_pressed("inventory"):
			_show_inventory()
		if Input.is_action_just_pressed("character"):
			_show_character(false)
	if net_started:
		net_time += delta
		if net_released and net_time>.3 and not network_busy:
			_finish_net()
	if not GameState.dive.is_empty():
		sync_clock += delta
		refresh_clock += delta
		if sync_clock>2 and not network_busy and not syncing and not modal_open:
			sync_clock = 0
			_sync_position()
		if refresh_clock>6 and not network_busy and not syncing:
			refresh_clock = 0
			_refresh_dive()
		var max_y := 1090 if int(GameState.player.progress.day)==1 else 2070 if int(GameState.player.progress.day)==2 else 3470
		if nala.position.y>max_y:
			nala.position.y = max_y
			nala.velocity.y = minf(nala.velocity.y,0)
			status.text = "Arus terlalu kuat. Bantu warga untuk membuka jalur kedalaman berikutnya."
		if not modal_open and not ViewportLayout.host_paused and not network_busy and flash<=0:
			for hazard in GameState.world.get("hazards",[]):
				if nala.position.distance_to(Vector2(float(hazard.x),float(hazard.y)))<float(hazard.radius)+18:
					flash = 3.1
					_hazard_hit()
					break
		if not modal_open and not ViewportLayout.host_paused and GameState.dive.get("mode","")=="boss" and nala.position.distance_to(BossMotionScript.ANCHOR)<650:
			_boss_tick(delta)
		else:
			for shot in attacks:
				shot.node.queue_free()
			attacks.clear()
func _draw() -> void:
	if boss_motion.telegraph and not GameState.dive.is_empty():
		var source: Vector2 = boss_motion.attack_origin()
		draw_arc(source,34,0,TAU,24,Color("ffd166"),2)
		draw_line(source,source+Vector2(-210,0),Color("ef805f",0.72),3)
	if is_instance_valid(hybrid) and hybrid.is_active() and not modal_open and nearby.get("kind","")=="biota":
		var target: Vector2 = entities.target_position(nearby)
		for side in [-1,1]:
			var edge := target+Vector2(side*39,-15)
			draw_line(edge,edge+Vector2(0,30),Color("f0d48a"),2)
			draw_line(edge,edge+Vector2(-side*9,0),Color("f0d48a"),2)
			draw_line(edge+Vector2(0,30),edge+Vector2(-side*9,30),Color("f0d48a"),2)
	if net_started and nala:
		var radius := 20.0+minf(net_time,2)*40
		draw_arc(nala.position,radius,-PI,PI,40,Color("e7cc8b"),2)
	if flash>0 and nala:
		draw_circle(nala.position,28,Color(0.9,0.4,0.3,.25))
func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and is_instance_valid(homestead_ui) and homestead_ui.is_open:
		homestead_ui.close()
		get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F6 and is_instance_valid(hybrid):
		hybrid.enabled = not hybrid.enabled
	if event.is_action_pressed("ui_cancel") and modal_open and chain_lines.is_empty() and not GameState.dive.has("challenge"):
		_close()
func _find_nearby() -> void:
	nearby = {}
	var best := 140.0
	var objects: Array = []
	if GameState.dive.is_empty():
		var home: Dictionary=GameState.world.get("homestead",{})
		if home.get("door") is Dictionary:
			objects.append({"id":"home_enter","kind":"homestead","name":"Griya Sasmita","x":home.door.x,"y":home.door.y,"radius":100.0})
		for plot in home.get("gardenPlots",[]):
			var at: Dictionary=plot.get("interaction",{})
			objects.append({"id":str(plot.id),"kind":"homestead","name":"Petak Kebun Nala","x":at.get("x",0),"y":at.get("y",0),"radius":75.0})
		var pen:Dictionary=home.get("fishPen",{})
		if pen.get("interaction") is Dictionary:
			objects.append({"id":"fish_pen","kind":"homestead","name":"Keramba Nala","x":pen.interaction.x,"y":pen.interaction.y,"radius":75.0})
		if home.get("permitBoard") is Dictionary:
			objects.append({"id":"balai","kind":"homestead","name":"Papan Balai Wirabhumi","x":home.permitBoard.x,"y":home.permitBoard.y,"radius":100.0})
		if home.get("market") is Dictionary:
			objects.append({"id":"market","kind":"homestead","name":"Pasar Bibit Ratih","x":home.market.x,"y":home.market.y,"radius":100.0})
		for actor in surface_actors:
			if actor.has_meta("conversation"):
				var text: String = actor.get_meta("evening_conversation") if float(EnvironmentState.snapshot().daylight)<.45 else actor.get_meta("conversation")
				objects.append({"id":actor.actor_name,"x":actor.position.x,"y":actor.position.y,"name":actor.actor_name,"kind":"resident","radius":80.0,"text":text})
		for district in GameState.world.get("surface_hub",{}).get("districts",[]):
			var actor_position := Vector2(float(district.x),float(district.y))
			for actor in surface_actors:
				if actor.actor_name==str(district.npc): actor_position=actor.position
			objects.append({"id":district.id,"x":actor_position.x,"y":actor_position.y,"name":district.npc,"kind":"npc","radius":140.0})
		for landmark in GameState.world.get("surface_hub",{}).get("landmarks",[]):
			var item: Dictionary = landmark.duplicate()
			item["kind"] = "surface_landmark"
			item["radius"] = 85.0
			objects.append(item)
		var gate: Dictionary = GameState.world.get("forest",{}).get("gate",{})
		objects.append({"id":"forest_gate","x":gate.get("x",0),"y":gate.get("y",0),"name":"Jalur ke Hutan Pesisir","kind":"forest","radius":140.0})
		var ladder: Dictionary = GameState.world.get("hub",{}).get("divePoint",{})
		objects.append({"id":"ladder","x":ladder.get("x",0),"y":ladder.get("y",0),"name":"Tangga Palung Smara","kind":"dive","radius":140.0})
	else:
		objects.append({"id":"boat","x":1120,"y":470,"name":"Tangga pulang ke Bandar Hujung","kind":"extract","radius":140.0})
		for collection in ["landmarks","puzzles","caches"]:
			for item in GameState.world.get(collection,[]):
				var obj: Dictionary = item.duplicate()
				obj.kind = collection
				obj["radius"] = 140.0
				if not obj.has("name"):
					obj.name = "Peti peninggalan"
				objects.append(obj)
		var target_index := 0
		for target in GameState.dive.get("targets",[]):
			var available: bool = GameState.dive.get("mode","")!="boss" or ((target_index<ceili(_required_hits()/2.0))==(int(GameState.dive.get("hits",0))<ceili(_required_hits()/2.0)))
			target_index += 1
			if not target.get("caught",false) and available:
				var obj: Dictionary = target.duplicate()
				obj.kind = "biota"
				obj["radius"] = 140.0
				var point: Vector2 = entities.target_position(target)
				obj.x = point.x
				obj.y = point.y
				obj.name = _biota_name(str(target.subject))
				objects.append(obj)
	for obj in objects:
		var distance := nala.position.distance_to(Vector2(float(obj.x),float(obj.y)))
		var max_r := float(obj.get("radius",140.0))
		if distance <= max_r and (distance < best or (is_equal_approx(distance,best) and str(obj.get("id","")) < str(nearby.get("id","~")))):
			best = distance
			nearby = obj
	if nearby.is_empty():
		hint.text = "WASD / arah: bergerak · E: amati · Tahan & lepas spasi: jala · M: peta · J: jurnal"
	elif str(nearby.get("kind","")) == "dive":
		var ab: Dictionary = GameState.player.get("abilities",{})
		var day_now := int(GameState.player.get("progress",{}).get("day",1))
		var target_zone := "Dangkalan Segaran (0–25 m)" if day_now==1 else "Hutan Lamun Wringin (25–60 m)" if day_now==2 else "Rongga Kapur Jalatunda & Tamansari (60–110 m)"
		hint.text = "[E] Selami: %s · Siap selam: Oksigen Lv %d, Tas Lv %d · Tujuan: %s" % [str(nearby.name),int(ab.get("oxygen",0)),int(ab.get("bag",0)),target_zone]
	else:
		hint.text = ("Tahan & lepas spasi: " if nearby.kind=="biota" else "[E] ")+_action_label(nearby)
func _action_label(obj: Dictionary) -> String:
	if obj.is_empty():
		return "Dekati tempat atau tokoh"
	var kind := str(obj.get("kind",""))
	var label_name := str(obj.get("name",""))
	var found: Array = GameState.adventure.get("discoveries",[])
	match kind:
		"homestead":
			return "Periksa: "+label_name
		"npc", "resident":
			if label_name=="Mbah Wira" and _service_movement_locked(): return "Lanjutkan giliran kedai"
			return "Bicara: " + label_name
		"surface_landmark":
			return ("Periksa Ulang: " if found.has(str(obj.get("id",""))) else "Amati Kebun: ") + label_name
		"forest":
			return "Masuk: " + label_name
		"dive":
			return "Selami: " + label_name
		"extract":
			return "Naik: " + label_name
		"landmarks":
			return ("Periksa: " if found.has(str(obj.get("id",""))) else "Amati: ") + label_name
		"puzzles":
			return "Pulihkan: " + label_name
		"caches":
			return ("Periksa: " if found.has(str(obj.get("id",""))) else "Buka: ") + label_name
		"biota":
			return "Jala: " + label_name
	return label_name
func _biota_name(subject: String) -> String:
	return "Ubur-Ubur Klorofil" if subject=="Biologi" else "Ikan Simpul Ekosistem" if subject=="Lingkungan" else "Keong Rasio" if subject=="Matematika" else "Ikan Lentera Alkalin"
func _mission_counts() -> Dictionary:
	var disc: Array = GameState.adventure.get("discoveries",[])
	var garden := 0
	for gid in ["garden_leaf","garden_root","garden_channel"]:
		if disc.has(gid): garden += 1
	var forest := 0
	for fid in ["forest_canopy","forest_roots","forest_stream"]:
		if disc.has(fid): forest += 1
	var sea := 0
	for sid in ["nitrogen","photosynthesis","osmosis"]:
		if disc.has(sid): sea += 1
	var has_klorofil := false
	for inv in GameState.player.get("inventory",[]):
		if str(inv.get("fragmentId","")) == "klorofil" and int(inv.get("quantity",0)) > 0:
			has_klorofil = true
	return {"garden":garden,"forest":forest,"sea":sea,"has_klorofil":has_klorofil}
func _update_hud() -> void:
	if GameState.player.is_empty():
		return
	var p: Dictionary = GameState.player
	var depth := maxf(0,(nala.position.y-400)/28)
	var region := "Bandar Hujung"
	if not GameState.dive.is_empty():
		for zone in GameState.world.get("zones",[]):
			if depth>=float(zone.minDepth) and depth<float(zone.maxDepth):
				region = str(zone.name)
	var day := int(p.progress.day)
	var stage := str(p.progress.stage)
	var counts := _mission_counts()
	var goal := "Layani warga di Kedai Waras."
	if GameState.homestead.get("pendingStoryAdvance")!=null:
		goal="Pulang ke Griya Sasmita di barat desa dan tidur di dipan."
	elif stage == "night":
		goal = "Buka Kedai Waras bersama Mbah Wira & racik solusi warga malam ini."
	elif stage == "boss":
		goal = "Pulihkan Gajah Mina di Tamansari."
	elif stage == "done":
		goal = "Prasasti Smara Kuno ditemukan. Fase 1 selesai."
	elif day == 1:
		goal = "Jelajahi Segaran dan jala bekal kedai. Hutan Pesisir ada di timur laut dermaga."
	elif day == 2:
		if not GameState.dive.is_empty():
			goal = "Hutan Lamun Wringin (25–60 m): Amati Nitrogen, Fotosintesis, & Osmosis (%d/3) lalu jala Benih Hayati." % int(counts.sea)
		elif int(counts.garden) < 3:
			goal = "Misi Bu Darmi: Amati Kebun Apung (%d/3), Hutan Pesisir (%d/3), & Hutan Lamun (%d/3)." % [int(counts.garden),int(counts.forest),int(counts.sea)]
		elif int(counts.forest) < 3:
			goal = "Kebun diamati (3/3). Bandingkan di Hutan Pesisir (%d/3) atau selami Hutan Lamun (%d/3)." % [int(counts.forest),int(counts.sea)]
		else:
			goal = "Daratan diamati. Selami Hutan Lamun Wringin (25–60 m) untuk pengamatan laut (%d/3) & Benih Hayati." % int(counts.sea)
	else:
		goal = "Selidiki pipa korporasi dan pulihkan penyaring Jalatunda."
	var d: Dictionary = GameState.dive
	var state := {"area":region,"depth":depth,"diving":not d.is_empty(),"oxygen":d.get("oxygen",0),"maxOxygen":d.get("maxOxygen",100),"coins":p.coins,"weight":d.get("weight",0),"capacity":d.get("capacity",12),"objective":goal,"action":_action_label(nearby),"canInteract":not nearby.is_empty() and nearby.get("kind","")!="biota","canNet":nearby.get("kind","")=="biota" and not d.is_empty()}
	state.merge(EnvironmentState.snapshot(),true)
	state["netCharging"] = net_started
	state["netProgress"] = clampf(net_time/0.3,0,1)
	hud.update_state(state)
	if hud.has_method("set_navigation"):
		hud.set_navigation(GameState.world,"hub" if GameState.dive.is_empty() else "sea",nala.position)
	hud.set_modal(modal_open)
func _sync_position() -> bool:
	if GameState.dive.is_empty() or syncing:
		return true
	syncing = true
	var r: Dictionary = await ApiClient.call_api("/dive/position",{"diveId":GameState.dive.id,"x":nala.position.x,"y":maxf(400,nala.position.y)})
	syncing = false
	if not r.get("ok",false):
		status.text = str(r.get("error","Koneksi posisi terganggu."))
		if r.get("code","")=="SESSION_CHANGED":
			GameState.dive = {}
			_close()
			await GameState.refresh()
			nala.position = _surface_point()
		return false
	_update_hud()
	if OS.has_feature("web") and preload("res://scripts/Diagnostics.gd").enabled():
		var snapshot := {"x":nala.position.x,"y":nala.position.y,"stage":GameState.player.get("progress",{}).get("stage",""),"modal":modal_open,"nearby":str(nearby.get("id","")),"diving":not GameState.dive.is_empty()}
		if is_instance_valid(modal) and modal.has_method("debug_state"): snapshot["dialogue"] = modal.debug_state()
		snapshot["performance"] = preload("res://scripts/Diagnostics.gd").performance_sample(nala)
		snapshot["service"] = _service_debug_status()
		snapshot["outfit"] = nala.outfit
		snapshot["equipment"] = nala.equipment
		snapshot["audio"] = AudioManager.debug_status()
		snapshot["flashlight2d"] = _flashlight_status_2d()
		snapshot["weather"] = EnvironmentState.snapshot()
		snapshot["land"] = land_renderer.debug_status() if is_instance_valid(land_renderer) else {}
		snapshot["traversal"] = nala.traversal_state
		snapshot["occlusion"] = terrain.scenery.debug_status() if is_instance_valid(terrain) and is_instance_valid(terrain.scenery) and terrain.scenery.has_method("debug_status") else {}
		snapshot["foley"] = world_foley.debug_status() if is_instance_valid(world_foley) else {}
		snapshot["life"] = entities.wildlife.debug_status() if is_instance_valid(entities.wildlife) and entities.wildlife.has_method("debug_status") else {}
		snapshot["hybrid"] = hybrid.debug_status() if is_instance_valid(hybrid) else {"active":false}
		if hud.has_method("debug_layout"):
			snapshot["hud"] = hud.debug_layout()
		JavaScriptBridge.get_interface("window").jalasmaraSnapshot = JavaScriptBridge.get_interface("JSON").parse(JSON.stringify(snapshot))
	return true
func _refresh_dive() -> void:
	var r: Dictionary = await GameState.refresh()
	if not r.get("ok",false):
		status.text = str(r.get("error","Koneksi terputus."))
		if r.get("code","")=="SESSION_CHANGED":
			GameState.dive = {}
			_close()
			await GameState.refresh()
			nala.position = _surface_point()
	elif GameState.dive.is_empty():
		nala.position = _surface_point()
	elif float(GameState.dive.get("oxygen",100))<=0:
		_extract(true)
	_update_hud()
func _interact() -> void:
	if network_busy or modal_open or nearby.is_empty():
		return
	var obj: Dictionary = nearby.duplicate()
	match str(obj.kind):
		"homestead":
			homestead_ui.open_for(str(obj.id))
		"resident":
			if str(obj.name)=="Ki Lurah Wirabhumi" and not service_resident("balai").is_empty():
				homestead_ui.open_for("balai")
			elif str(obj.name)=="Mbok Ratih" and nala.position.distance_to(Vector2(float(GameState.world.homestead.market.x),float(GameState.world.homestead.market.y)))<=100:
				homestead_ui.open_for("market")
			else: _talk([{"name":str(obj.name),"text":str(obj.text)}])
		"npc":
			if str(obj.name)=="Mbah Wira" and _has_kedai_produce():
				homestead_ui.open_for("wira")
			else: _npc_interact(str(obj.name))
		"surface_landmark":
			_surface_discover(obj)
		"forest":
			_enter_forest()
		"dive":
			_begin_dive()
		"extract":
			_extract()
		"landmarks", "caches":
			_discover(obj)
		"puzzles":
			_show_puzzle(obj)
		"biota":
			_start_net()
			net_released = true
func _has_kedai_produce() -> bool:
	var produce:Dictionary=GameState.homestead.get("produce",{})
	var servings:Dictionary=GameState.homestead_definitions.get("servings",{"kangkung":{"itemId":"kangkung"}})
	for serving in servings.values():
		if int(produce.get(str(serving.get("itemId","")),0))>0: return true
	return false
func service_resident(service_id: String) -> Dictionary:
	if service_id!="balai" or not GameState.dive.is_empty() or not is_instance_valid(nala): return {}
	var point: Dictionary=GameState.world.get("homestead",{}).get("permitBoard",{})
	if point.is_empty(): return {}
	var board:=Vector2(float(point.x),float(point.y))
	if nala.position.distance_to(board)>100: return {}
	for actor in surface_actors:
		if not is_instance_valid(actor) or actor.actor_name!="Ki Lurah Wirabhumi" or not actor.has_meta("conversation"): continue
		if actor.position.distance_to(board)>80 or nala.position.distance_to(actor.position)>80: continue
		var text: String=actor.get_meta("evening_conversation") if float(EnvironmentState.snapshot().daylight)<.45 else actor.get_meta("conversation")
		return {"name":actor.actor_name,"text":text}
	return {}
func _surface_discover(obj: Dictionary) -> void:
	network_busy = true
	while syncing: await get_tree().process_frame
	if not await _sync_surface():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/adventure/surface-interact",{"id":obj.id})
	network_busy = false
	if r.get("ok",false):
		GameState.player = r.player
		GameState.adventure = r.adventure
		if r.has("surface"):
			GameState.surface = r.surface
		elif not GameState.surface.is_empty():
			GameState.surface["playerVersion"] = int(r.player.get("version",0))
		surface_clock = 0.0
		nala.land_path.reset(nala.position)
		var reward := int(r.get("reward",0))
		AudioManager.play_sfx("path_reveal_chime" if reward > 0 else "wooden_click_light")
		var counts := _mission_counts()
		var summary := "\n\nGejala Kebun Apung diamati: %d/3 · " % int(counts.garden) + ("Sudah tercatat dalam jurnal." if r.get("alreadyFound",false) else "+%d koin · Dicatat dalam jurnal." % reward)
		_show_message(str(obj.get("title",obj.get("name","Pengamatan Kebun"))),str(obj.get("text",""))+summary)
		_update_hud()
	else:
		status.text = str(r.get("error","Dekati titik kebun terlebih dahulu."))
func _enter_water(dive: Dictionary) -> void:
	GameState.dive = dive
	var pos: Dictionary = dive.get("position",{"x":1120,"y":470})
	nala.position = Vector2(float(pos.x),float(pos.y))
	nala.speed = float(dive.get("speed",110))
	nala.velocity = Vector2.ZERO
	camera.reset_smoothing()
	environment.configure("sea")
	environment.splash(Vector2(480,270))
	_update_hud()
func _begin_dive() -> void:
	if not GameState.shift.is_empty():
		_show_message("Kedai masih buka","Temui Mbah Wira untuk menutup giliran kedai sebelum menyelam.")
		return
	if GameState.player.progress.stage=="done":
		_show_message("Prasasti Smara Kuno","Peta hologram menunjuk kedalaman 300 meter. Gerbang mekanik telah terbuka; perjalanan Fase 2 menunggu.")
		return
	var mode := "boss" if GameState.player.progress.stage=="boss" else "dive"
	network_busy = true
	while syncing: await get_tree().process_frame
	if not await _sync_surface():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/dive/start",{"mode":mode})
	network_busy = false
	if r.get("ok",false):
		_enter_water(r.dive)
		status.text = "Cari celah di antara terumbu. Amati prasasti, instalasi, dan biota di sepanjang jalan."
	else:
		_show_message("Belum dapat menyelam",str(r.get("error","Coba kembali.")))
func _extract(fainted := false) -> void:
	if network_busy or GameState.dive.is_empty():
		return
	if not fainted and nala.position.distance_to(Vector2(1120,470))>220 and not (GameState.dive.get("mode","")=="boss" and int(GameState.dive.get("hits",0))>=_required_hits()):
		status.text = "Kembali ke tangga selam di Dangkalan Segaran."
		return
	network_busy = true
	var was_frozen: bool = nala.frozen
	nala.frozen = true
	nala.velocity = Vector2.ZERO
	nala.touch = Vector2.ZERO
	while syncing: await get_tree().process_frame
	var r: Dictionary = await ApiClient.call_api("/dive/extract",{"diveId":GameState.dive.id})
	if not r.get("ok",false):
		network_busy = false
		nala.frozen = was_frozen or modal_open or ViewportLayout.host_paused
		status.text = str(r.get("error","Belum dapat kembali."))
		return
	# Publish the returned version and dock position before any refresh can yield.
	GameState.apply_result(r.merged({"dive":{}},true))
	nala.position = _surface_point()
	nala.land_path.reset(nala.position)
	surface_clock = 0.0
	camera.reset_smoothing()
	await GameState.refresh()
	nala.position = _surface_point()
	nala.land_path.reset(nala.position)
	camera.reset_smoothing()
	network_busy = false
	nala.frozen = was_frozen or modal_open or ViewportLayout.host_paused
	_update_hud()
	if r.get("victory",false):
		_talk([{"name":"Babak 5 · Sang Penjaga Kembali Mengingat","text":"Pipa terakhir terlepas. Gajah Mina berhenti mengamuk; air di sekitar mahkotanya kembali jernih. Nala mengembalikan Inti Smara kepada sang penjaga."},{"name":"Saras","text":"Ini bukan reruntuhan biasa. Prasasti itu memetakan ruang penyimpanan ingatan di kedalaman 300 meter. Seseorang membangun seluruh palung ini."},{"name":"Bandar Hujung","text":"Kebun kembali hijau. Warga tidak lagi bergantung pada Kapsul Instan. Di bawah Tamansari, gerbang mekanik perlahan terbuka. Fase 1 selesai."}])
	else:
		_show_message("Kembali ke Bandar Hujung", "Beno menolong Nala dan menyelamatkan satu tangkapan." if r.get("fainted",false) else "Fragmen tersimpan ke tas. Datangi Mbah Wira di Kedai Waras untuk membantu warga malam ini.")
func _discover(obj: Dictionary) -> void:
	network_busy = true
	if not await _sync_position():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/adventure/interact",{"diveId":GameState.dive.id,"id":obj.id})
	network_busy = false
	if r.get("ok",false):
		GameState.player = r.player
		GameState.adventure = r.adventure
		_show_message(str(obj.get("title","Peti peninggalan")),str(obj.get("text","Bekal dan koin tersimpan di dalam peti tua."))+"\n\n"+("Sudah tercatat dalam jurnal." if r.get("alreadyFound",false) else "+%d koin · Dicatat dalam jurnal." % int(r.reward)))
		_update_hud()
	else:
		status.text = str(r.get("error","Dekati objek terlebih dahulu."))
func _show_puzzle(obj: Dictionary) -> void:
	if not await _sync_position():
		return
	var box := _open(str(obj.title))
	_label(box,str(obj.prompt))
	var controls: Array = []
	if obj.kind=="filter" or obj.get("kind","")=="puzzles" and obj.id=="filter":
		for i in range(3):
			var select := OptionButton.new()
			for text in obj.labels:
				select.add_item(str(text))
			select.selected = 2-i
			controls.append(select)
			box.add_child(select)
	else:
		for text in obj.labels:
			var toggle := CheckButton.new()
			toggle.text = str(text)+" · buka"
			controls.append(toggle)
			box.add_child(toggle)
	var feedback := _label(box,"")
	_button(box,"Uji aliran",func():
		var settings: Array = []
		for control in controls:
			settings.append(control.selected if control is OptionButton else 1 if control.button_pressed else 0)
		await ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":false})
		var r: Dictionary = await ApiClient.call_api("/adventure/interact",{"diveId":GameState.dive.id,"id":obj.id,"settings":settings})
		if r.get("ok",false):
			if not str(obj.id) in GameState.adventure.get("puzzles",[]): AudioManager.play_sfx("path_reveal_chime",1.0,-12.0)
			GameState.player = r.player
			GameState.adventure = r.adventure
			_show_message("Instalasi kembali bekerja",str(obj.explanation)+"\n\n+%d koin" % int(r.reward))
		else:
			feedback.text = str(r.get("error","Periksa susunan kembali."))
			ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":true})
	)
	_button(box,"Tinggalkan instalasi",_close)
func _start_net() -> void:
	if network_busy or modal_open or net_started or nearby.get("kind","")!="biota":
		return
	net_target = nearby.duplicate()
	if GameState.dive.get("mode","")=="boss":
		_boss_challenge(net_target)
		return
	network_busy = true
	net_released = false
	if not await _sync_position():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/dive/net/start",{"diveId":GameState.dive.id})
	network_busy = false
	if r.get("ok",false):
		net_started = true
		AudioManager.play_sfx("net_throw",1.0,-9.0)
		net_time = 0
		status.text = "Lepaskan saat lingkaran jala terbuka. Tidak perlu kuis untuk menjala biota biasa."
	else:
		status.text = str(r.get("error","Jala belum siap."))
func _finish_net() -> void:
	net_started = false
	network_busy = true
	if not await _sync_position():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/dive/collect",{"diveId":GameState.dive.id,"targetId":net_target.id})
	network_busy = false
	if r.get("ok",false):
		GameState.dive = r.dive
		status.text = "%s tertangkap · %d bintang · %d/%d kg" % [_biota_name(str(net_target.subject)),int(r.stars),int(r.dive.weight),int(r.dive.capacity)]
	else:
		status.text = str(r.get("error","Jala terlepas."))
func _boss_challenge(target: Dictionary) -> void:
	network_busy = true
	if not await _sync_position():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/dive/challenge",{"diveId":GameState.dive.id,"targetId":target.id})
	network_busy = false
	if r.get("ok",false):
		GameState.dive = r.dive
		_show_quiz()
	else:
		status.text = str(r.get("error","Dekati titik resonansi."))
func _show_quiz() -> void:
	var challenge: Dictionary = GameState.dive.get("challenge",{})
	if challenge.is_empty():
		return
	var box := _open("Resonansi Inti Smara",false)
	var prompt_label := _label(box,str(challenge.question.prompt),24)
	prompt_label.add_theme_font_override("font",BODY_FONT)
	if challenge.get("answered",false):
		var explanation_label := _label(box,str(challenge.result.explanation),24)
		explanation_label.add_theme_font_override("font",BODY_FONT)
		_button(box,"Lanjutkan pemulihan",func():
			var r: Dictionary = await ApiClient.call_api("/dive/continue",{"diveId":GameState.dive.id,"challengeId":challenge.id})
			if r.get("ok",false):
				GameState.dive = r.dive
				_close()
				if int(GameState.dive.get("hits",0))>=_required_hits():
					_extract()
		)
	else:
		var answers := GridContainer.new()
		answers.columns = 2
		answers.set_meta("quiz_answers",true)
		answers.add_theme_constant_override("h_separation",12)
		answers.add_theme_constant_override("v_separation",12)
		box.add_child(answers)
		for i in range(challenge.question.options.size()):
			var selected := i
			var answer := _button(answers,"",func():
				if network_busy:
					return
				network_busy = true
				var r: Dictionary = await ApiClient.call_api("/dive/catch",{"diveId":GameState.dive.id,"challengeId":challenge.id,"selectedOption":selected})
				network_busy = false
				if r.get("ok",false):
					GameState.dive = r.dive
					_show_quiz()
			)
			var option_text := "%s. %s" % [String.chr(65+i),str(challenge.question.options[i])]
			var measured := BODY_FONT.get_multiline_string_size(option_text,HORIZONTAL_ALIGNMENT_LEFT,250,24)
			answer.custom_minimum_size = Vector2(0,maxf(_ui_target(),measured.y+28))
			var option_label := Label.new()
			option_label.text = option_text
			option_label.add_theme_font_override("font",BODY_FONT)
			option_label.add_theme_font_size_override("font_size",_ui_font())
			option_label.set_meta("base_font_size",24)
			option_label.add_theme_color_override("font_color",Color("f4ebd9"))
			option_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			option_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			answer.add_child(option_label)
			option_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			option_label.offset_left = 14
			option_label.offset_right = -14
			option_label.offset_top = 12
			option_label.offset_bottom = -12
			var key := InputEventKey.new()
			key.physical_keycode = KEY_1+i
			answer.shortcut = Shortcut.new()
			answer.shortcut.events = [key]
		_label(box,"Serangan berhenti selama resonansi. Jawab dengan pemahaman, lalu lanjutkan menghindari serangan.",13)
func _npc_interact(name_text: String) -> void:
	network_busy = true
	while syncing: await get_tree().process_frame
	var saved := _can_resume_kedai(name_text)
	if not saved: saved = await _sync_surface()
	network_busy = false
	if not saved: return
	var p: Dictionary = GameState.player
	var progress: Dictionary = p.get("progress",{})
	var missions: Array = progress.get("missions",[])
	var day := int(progress.get("day",1))
	var stage := str(progress.get("stage","dive"))
	var counts := _mission_counts()
	if name_text=="Mbah Wira":
		if GameState.homestead.get("pendingStoryAdvance")!=null:
			_talk([{"name":"Mbah Wira","text":"Pelayanan malam ini sudah selesai. Pulang ke Griya Sasmita dan tidur di dipan. Besok kita melanjutkan dari hasil kerja hari ini."}])
		elif stage=="night":
			_open_kedai()
		elif stage=="boss":
			_talk([{"name":"Babak 4 · Sabotase di Kedai Waras","text":"Inspektur Raka menuntut kedai ditutup: pengetahuan tanpa lisensi, katanya. Lalu gempa mengguncang dermaga. Pipa raksasa di Tamansari pecah, dan sesuatu menarik jangkar kota."},{"name":"Nala","text":"Dia kabur sebelum selesai membacakan pasalnya. Aku anggap itu izin menyelam."},{"name":"Mbah Wira","text":"Gajah Mina sedang kesakitan. Netralisasi lapisan racunnya dalam simulasi alatmu, lepaskan pipa, dan pulihkan inti ingatannya. Jangan lukai sang penjaga. Tabung dan jala level tiga harus siap."}])
		elif day==2:
			_talk([{"name":"Mbah Wira","text":"Malam nanti Bu Darmi akan datang ke Kedai Waras. Agar racikanmu tepat, jangan hanya menyelam: amati dulu gejala kebun apung di timur pelataran (%d/3), bandingkan dengan Hutan Pesisir Wringin di daratan (%d/3), lalu selami Hutan Lamun Wringin pada kedalaman 25–60 m (%d/3)." % [int(counts.garden),int(counts.forest),int(counts.sea)]},{"name":"Nala","text":"Aku juga akan memastikan fragmen Benih Hayati (Biologi Tumbuhan) sudah ada di tas sebelum membuka kedai malam ini."}])
		else:
			_talk([{"name":"Mbah Wira","text":"Kedai buka setelah kamu kembali membawa fragmen. Jika bekal kurang, tutup sementara dan cari lagi. Pelanggan yang sudah dilayani tetap tercatat."},{"name":"Nala","text":"Baik. Menjaring ingatan dulu, meracik solusi kemudian."}])
	elif name_text=="Beno":
		_show_upgrades()
	elif name_text=="Bu Darmi":
		if missions.has("akar") and (day>=3 or stage in ["boss","done"]):
			_talk([{"name":"Bu Darmi · Kebun Apung Pulih Bertahap","emotion":"happy","text":"Lihatlah petak kebunku, Nala! Pucuk-pucuk hijau sudah tumbuh tinggi dan mulai berbunga. Sejak kita memasang penyangga aerasi bambu dan menjaga saluran pasang tetap lancar, akarnya tidak lagi membusuk."},{"name":"Nala","text":"Saat pori media memiliki udara untuk respirasi seluler dan air tidak lagi tergenang payau, akar mampu menyerap nitrogen untuk membentuk klorofil kembali."}])
		elif missions.has("akar"):
			_talk([{"name":"Bu Darmi · Perawatan Kebun Dimulai","text":"Terima kasih atas seduhan di Kedai Waras malam ini, Nala. Aku sudah melonggarkan media tanam, memasang penyangga bambu, dan membuka saluran pembuangan di tepi selatan agar air pasang tidak menggenang."},{"name":"Nala","text":"Perawatan sudah dimulai malam ini, Bu. Begitu akarnya kembali mendapat oksigen untuk bernapas, kebun apung akan pulih bertahap mulai besok."}])
		elif stage=="night":
			_talk([{"name":"Bu Darmi","text":"Aku sudah mencatat semua gejala kebunku. Temui Mbah Wira di Kedai Waras sekarang—kita bahas temuanmu dari kebun apung, Hutan Pesisir Wringin, dan Hutan Lamun Wringin untuk meracik solusinya."}])
		elif int(counts.garden) < 3:
			_talk([{"name":"Babak 2 · Kebun Apung yang Sekarat","text":"Daun kebun apung menguning dan akarnya membusuk. Raka menawarkan Kapsul Tani dengan harga tiga kali penghasilanku, padahal kapsul itu hanya memaksa daun tampak segar sehari."},{"name":"Bu Darmi","text":"Tolong periksa tiga titik di sekeliling petak kebunku di sebelah timur ini (%d/3): Daun Kebun Menguning, Media Tanam Tergenang, dan Saluran Air Kebun Apung." % int(counts.garden)},{"name":"Nala","text":"Setelah memeriksa kebunmu, aku akan membandingkannya dengan tanah berhumus serta aliran hulu di Hutan Pesisir Wringin (daratan timur laut), lalu menyelam ke Hutan Lamun Wringin (kedalaman 25–60 m) untuk mengamati Koral Nitrogen, Lentera Fotosintesis, dan Kerang Osmosis."}])
		elif int(counts.forest) < 3 or int(counts.sea) < 3:
			_talk([{"name":"Bu Darmi","text":"Kamu sudah memeriksa ketiga gejala di kebunku (3/3): daunnya pucat klorosis, medianya padat tergenang tanpa udara, dan saluran pasangnya tersendat."},{"name":"Nala","text":"Benar, Bu. Sekarang aku sedang melengkapi perbandingan di Hutan Pesisir Wringin daratan (%d/3) dan pengamatan bawah laut di Hutan Lamun Wringin 25–60 m (%d/3) sambil menjala fragmen Benih Hayati." % [int(counts.forest),int(counts.sea)]}])
		else:
			_talk([{"name":"Bu Darmi","text":"Semua catatan dari kebun apung (3/3), Hutan Pesisir Wringin (3/3), dan Hutan Lamun Wringin (3/3) sudah lengkap!"},{"name":"Nala","text":"Begitu kembali dari penyelaman dan malam tiba, aku akan menemui Mbah Wira di Kedai Waras untuk meracik solusinya dengan Benih Hayati."}])
	else:
		_talk([{"name":"Inspektur Raka","text":"PT Cakrawala Sintetis menyediakan Kapsul Instan untuk seluruh kebutuhan kerja Anda. Belajar mandiri meningkatkan risiko kesalahan prosedur."},{"name":"Nala","text":"Menarik. Apakah prosedurnya juga menjelaskan pipa yang bocor di bawah kota?"},{"name":"Inspektur Raka","text":"Akses ke fasilitas Sektor Tuban-7 dibatasi. Percakapan ini dicatat."}])
func _service_debug_status() -> Dictionary:
	if not is_instance_valid(modal) or not modal.get_meta("service_tray",false): return {}
	var viewport:=modal.get_viewport()
	var transform:=viewport.get_final_transform()
	var scroll:=_modal_scroll(modal)
	var focused:=viewport.gui_get_focus_owner()
	var result:Dictionary={"physicalViewport":[viewport.get_window().size.x,viewport.get_window().size.y],"scrollOffset":scroll.scroll_vertical,"focus":{}}
	for item in [["panel",modal],["scroll",scroll],["header",modal.get_meta("service_header")]]:
		var rect:Rect2=transform*item[1].get_global_rect()
		result[item[0]]={"position":[rect.position.x,rect.position.y],"size":[rect.size.x,rect.size.y]}
	if is_instance_valid(focused) and scroll.is_ancestor_of(focused):
		var rect:Rect2=transform*focused.get_global_rect()
		result.focus={"kind":focused.get_class(),"position":[rect.position.x,rect.position.y],"size":[rect.size.x,rect.size.y],"visible":scroll.get_global_rect().grow(1).encloses(focused.get_global_rect())}
	return result

func _can_resume_kedai(name_text: String) -> bool:
	# Active shifts reject surface writes; resume only at the already acknowledged Wira point.
	if name_text!="Mbah Wira" or str(GameState.shift.get("id","")).is_empty(): return false
	if not GameState.dive.is_empty() or bool(GameState.homestead.get("inside",false)): return false
	if str(GameState.player.get("progress",{}).get("stage",""))!="night": return false
	if str(GameState.surface.get("area","hub"))!="hub" or nala.position.distance_to(_surface_point())>.5 or nala.land_path.size()>0: return false
	for district in GameState.world.get("surface_hub",{}).get("districts",[]):
		if str(district.get("npc",""))=="Mbah Wira":
			return nala.position.distance_to(Vector2(float(district.x),float(district.y)))<=float(district.get("radius",140.0))
	return false

func _show_upgrades() -> void:
	var box := _open("Beno · Galangan Rongsok Bubat")
	_label(box,"Tabung dan Jala Kognisi level 3 diperlukan di Tamansari. Penemuan, peti, dan pemulihan instalasi memberi bekal tambahan.",14)
	for item in GameState.catalog.get("abilities",[]):
		var ability_id := str(item.id)
		var level := int(GameState.player.abilities.get(ability_id,0))
		var maxed: bool = level>=item.prices.size()
		var price := 0 if maxed else int(item.prices[level])
		var button := _button(box,"%s · Lv %d · %s" % [item.name,level,"Maksimal" if maxed else "%d koin" % price],func():
			var r: Dictionary = await ApiClient.call_api("/game/upgrade",{"ability":ability_id})
			if r.get("ok",false):
				await GameState.refresh()
				_update_hud()
				_show_upgrades()
			else:
				_show_message("Beno",str(r.get("error","Belum dapat ditingkatkan.")))
		)
		button.disabled = maxed or int(GameState.player.coins)<price or not GameState.dive.is_empty() or not GameState.shift.is_empty()
	_button(box,"Kembali ke dermaga",_close)
func _open_kedai() -> void:
	network_busy = true
	var r: Dictionary = await ApiClient.call_api("/kedai/start",{})
	network_busy = false
	if not r.get("ok",false):
		_show_message("Kedai belum dapat dibuka",str(r.get("error","Coba kembali.")))
		return
	GameState.shift = r.shift
	_kedai_customer()
func _kedai_customer() -> void:
	var box := _open("Meja Racik · Kedai Waras")
	modal.set_meta("service_tray",true)
	var stranded := not _can_resume_kedai("Mbah Wira")
	if stranded:
		_label(box,"Giliran kedai masih aktif. Tutup sementara untuk kembali berjalan; pesanan yang sudah selesai tetap tersimpan.",14)
	var current: Dictionary = {}
	var pantry_first:Button
	for customer in GameState.shift.get("customers",[]):
		if not GameState.shift.get("served",[]).has(customer.id):
			current = customer
			break
	if current.is_empty():
		_label(box,"Semua pelanggan mulai mengingat kembali. Mbah Wira menutup buku racikan malam ini.")
		_button(box,"Tutup kedai · pulang beristirahat",func(): await _close_shift(false))
	else:
		var counts := _mission_counts()
		_label(box,"Pelanggan: "+str(current.customer),20)
		_label(box,"Keluhan: “"+str(current.complaint)+"”",17)
		var note_text:=""
		if str(current.id)=="akar":
			note_text="Bukti lapangan · Kebun %d/3 · Hutan %d/3 · Laut %d/3.\nMedia tergenang dan saluran tersendat mengurangi oksigen untuk respirasi akar. Benih Hayati menyimpan konsep respirasi, osmosis, nitrogen, dan fotosintesis." % [int(counts.garden),int(counts.forest),int(counts.sea)]
		elif str(current.id)=="daun_kuning":
			note_text="Daun menguning berkaitan dengan klorofil dan kesehatan akar. Bandingkan gejala dengan konsep biologi tumbuhan dalam Benih Hayati."
		var garden_choices:Array[Dictionary]=[]
		var servings:Dictionary=GameState.homestead_definitions.get("servings",{"kangkung":{"itemId":"kangkung","name":"Kangkung kebun"}})
		for serving in servings.values():
			var quantity:=int(GameState.homestead.get("pantry",{}).get(str(serving.itemId),0))
			if quantity>0: garden_choices.append({"id":str(serving.itemId),"name":str(serving.name),"quantity":quantity})
		var garden_ingredient:=CheckButton.new()
		garden_ingredient.text="Pelengkap kedai habis"
		if garden_choices.size()==1:
			var short_name:=str(garden_choices[0].name).replace(" kebun","").replace(" pesisir","").replace(" budidaya","")
			garden_ingredient.text="Pelengkap %s ×%d" % [short_name,int(garden_choices[0].quantity)]
		elif garden_choices.size()>1: garden_ingredient.text="Pakai pelengkap kedai"
		garden_ingredient.disabled=garden_choices.is_empty()
		garden_ingredient.custom_minimum_size.y=_ui_target()
		garden_ingredient.add_theme_font_override("font",BODY_FONT)
		garden_ingredient.add_theme_font_size_override("font_size",_ui_font())
		pantry_first=garden_ingredient
		var supplement_parent:Container=box
		supplement_parent.add_child(garden_ingredient)
		var garden_select:OptionButton
		if garden_choices.size()>1:
			garden_select=OptionButton.new()
			garden_select.add_theme_font_override("font",BODY_FONT)
			garden_select.add_theme_font_size_override("font_size",_ui_font())
			garden_select.custom_minimum_size.y=_ui_target()
			garden_select.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			for choice in garden_choices:
				var short_name:=str(choice.name).replace(" kebun","").replace(" pesisir","").replace(" budidaya","")
				garden_select.add_item("%s ×%d" % [short_name,int(choice.quantity)])
				garden_select.set_item_metadata(garden_select.item_count-1,choice.id)
			supplement_parent.add_child(garden_select)
		var feedback_label := _label(box,"",13)
		feedback_label.modulate = Color("8c2d19")
		feedback_label.hide()
		var any := false
		for item in GameState.player.get("inventory",[]):
			if int(item.quantity)<=0:
				continue
			any = true
			var selected: Dictionary = item.duplicate()
			var frag_id := str(item.fragmentId)
			_button(box,"%s · %d bintang · %d buah" % [GameState.fragment_name(frag_id),int(item.stars),int(item.quantity)],func():
				if network_busy: return
				network_busy=true
				var body:Dictionary={"shiftId":GameState.shift.id,"recipeId":current.id,"fragmentId":selected.fragmentId,"stars":int(selected.stars),"gardenIngredient":garden_ingredient.button_pressed}
				if garden_ingredient.button_pressed:
					body["gardenItemId"]=str(garden_select.get_item_metadata(garden_select.selected)) if is_instance_valid(garden_select) else str(garden_choices[0].id)
				var r: Dictionary = await ApiClient.call_api("/kedai/serve",body)
				network_busy=false
				if r.get("ok",false):
					AudioManager.play_sfx("recipe_cooked")
					if str(current.id) == "akar":
						AudioManager.play_victory_jingle()
					GameState.player = r.player
					GameState.shift = r.shift
					GameState.apply_result(r)
					_show_kedai_result(current,r)
					_update_hud()
				else:
					AudioManager.play_sfx("wooden_toggle")
					var err_msg := str(r.get("error","Fragmen belum sesuai. Baca kembali keluhan pelanggan dan bukti lapangan."))
					if is_instance_valid(feedback_label):
						feedback_label.text = "Belum tepat (fragmen tidak berkurang): " + err_msg
						feedback_label.show()
					status.text = err_msg
			)
		if not note_text.is_empty():
			var notes:=_label(box,note_text,14)
			notes.hide()
			var notes_button:Button
			notes_button=_button(box,"Baca bukti lapangan",func():
				notes.visible=not notes.visible
				(notes.get_meta("toggle") as Button).text="Tutup bukti lapangan" if notes.visible else "Baca bukti lapangan"
				_layout_modal()
			)
			notes.set_meta("toggle",notes_button)
		if not any:
			_label(box,"Tas kosong. Tutup kedai sementara untuk kembali menyelam.")
		_button(box,"Tutup sementara · cari stok",func(): await _close_shift(true))
	if not stranded:
		_button(box,"Tutup panel · tetap di kedai",_close)
	_pin_service_context()
	if is_instance_valid(pantry_first) and not pantry_first.disabled:
		pantry_first.grab_focus.call_deferred()
		return
	for child in box.get_children():
		if child is Button and not child.disabled:
			child.grab_focus.call_deferred()
			break
func _pin_service_context() -> void:
	var scroll:=_modal_scroll(modal)
	var context:=modal_box.get_children().slice(0,3)
	modal.remove_child(scroll)
	var wrapper:=VBoxContainer.new()
	wrapper.add_theme_constant_override("separation",ceili(8*preload("res://scripts/UiMetrics.gd").ratio(self,hud)))
	modal.add_child(wrapper)
	var header:=VBoxContainer.new()
	header.name="ServiceContext"
	header.add_theme_constant_override("separation",ceili(4*preload("res://scripts/UiMetrics.gd").ratio(self,hud)))
	wrapper.add_child(header)
	for label in context:
		if not label is Label: break
		modal_box.remove_child(label)
		header.add_child(label)
	wrapper.add_child(scroll)
	modal.set_meta("service_header",header)

func _close_shift(abandon: bool) -> void:
	var r: Dictionary = await ApiClient.call_api("/kedai/close-shift",{"shiftId":GameState.shift.id,"abandon":abandon})
	if r.get("ok",false):
		await GameState.refresh()
		_update_hud()
		_close()
		if not abandon:
			_talk([{"name":"Kedai Waras · Pelayanan Selesai","text":"Hasil pelayanan sudah tersimpan. Pulang ke Griya Sasmita di sisi barat desa dan tidur di dipan untuk melanjutkan pagi cerita berikutnya."}])
	else:
		status.text = str(r.get("error","Giliran belum selesai."))
func _show_inventory() -> void:
	_open_field_panel(preload("res://scripts/InventoryView.gd").new())

func _show_kedai_result(current: Dictionary,r: Dictionary) -> void:
	var result_box := _open("Racikan Berhasil · "+str(current.customer),true,true)
	_label(result_box,str(r.solution),16)
	if str(current.id) == "akar":
		_label(result_box,"Dampak ke Rakit Tani Tanggulangen:\n• Malam ini: PERAWATAN DIMULAI — Bu Darmi memasang penyangga aerasi bambu dan membuka saluran pembuangan pasang agar akar kembali bernapas.\n• Hari berikutnya: PULIH BERTAHAP — Pucuk hijau dan bunga kebun apung akan tumbuh kembali.",14)
	_label(result_box,"Upah racikan: +%d koin" % int(r.earned),16)
	_button(result_box,"Pelanggan berikutnya",_kedai_customer).grab_focus.call_deferred()

func _open_field_panel(panel: Control) -> void:
	if is_instance_valid(field_panel): field_panel.queue_free()
	_open("")
	modal.hide()
	field_panel = panel
	ui.add_child(field_panel)
	field_panel.close_requested.connect(_close)

func _show_journal() -> void:
	_open_field_panel(preload("res://scripts/FieldBook.gd").new())

func _show_map() -> void:
	if modal_open and is_instance_valid(field_panel) and field_panel.get_meta("world_map",false):
		_close()
		return
	_open_field_panel(preload("res://scripts/AtlasOverlay.gd").new())
	field_panel.configure("sea" if not GameState.dive.is_empty() else "hub",nala.position)
	modal.set_meta("world_map",true)
func _boss_tick(delta: float) -> void:
	if int(GameState.dive.get("hits",0))>=_required_hits():
		return
	var second_phase := int(GameState.dive.get("hits",0))>=ceili(_required_hits()/2.0)
	status.text = "Gajah Mina · %d/300 vitalitas racun · %s" % [300-int(int(GameState.dive.get("hits",0))*300.0/_required_hits()),"Tarik Inti Smara" if second_phase else "Lepaskan lapisan asam"]
	if boss_motion.attack_event:
		var projectile := Polygon2D.new()
		projectile.polygon = PackedVector2Array([Vector2(-12,-5),Vector2(12,-5),Vector2(18,0),Vector2(12,5),Vector2(-12,5)])
		projectile.color = Color("a6b175")
		projectile.position = boss_motion.attack_origin()
		add_child(projectile)
		attacks.append({"node":projectile,"velocity":Vector2(-180,0)})
		if second_phase:
			var sludge := projectile.duplicate() as Polygon2D
			sludge.position = boss_motion.second_attack_origin()
			add_child(sludge)
			attacks.append({"node":sludge,"velocity":Vector2(0,140)})
	for i in range(attacks.size()-1,-1,-1):
		var shot: Dictionary = attacks[i]
		shot.node.position += shot.velocity*delta
		if shot.node.position.distance_to(nala.position)<26:
			flash = .5
			ApiClient.call_api("/dive/hazard",{"diveId":GameState.dive.id})
			shot.node.queue_free()
			attacks.remove_at(i)
		elif shot.node.position.x<2800 or shot.node.position.y>3470:
			shot.node.queue_free()
			attacks.remove_at(i)

func _hazard_hit() -> void:
	var r: Dictionary = await ApiClient.call_api("/dive/hazard",{"diveId":GameState.dive.id})
	if r.get("ok",false):
		GameState.dive = r.dive
		status.text = "Bahaya melukai perlengkapan. Hindari duri dan rembesan limbah."
		_update_hud()

func _required_hits() -> int:
	return int(GameState.dive.get("requiredHits",6))

func _sync_surface() -> bool:
	if syncing or not GameState.dive.is_empty():
		return false
	syncing = true
	var sent_pos := nala.position
	var route: Dictionary = nala.land_path.snapshot(sent_pos)
	var r: Dictionary = await ApiClient.call_api("/adventure/surface-position",{"area":"hub","x":sent_pos.x,"y":sent_pos.y,"path":route.path,"fromPositionAt":int(GameState.surface.get("positionAt",0)),"version":int(GameState.player.get("version",0))})
	syncing = false
	if r.get("ok",false):
		GameState.surface = r.surface
		nala.land_path.acknowledge(int(route.ticket))
		return true
	if str(r.get("code","")) in ["SESSION_CHANGED","AREA_CHANGED","POSITION_CHANGED","HOME_REQUIRED"]:
		syncing = true
		nala.frozen = true
		nala.velocity = Vector2.ZERO
		nala.touch = Vector2.ZERO
		var refreshed: Dictionary = await GameState.refresh()
		syncing = false
		if refreshed.get("ok",false):
			chain_lines.clear()
			chain_end = Callable()
			_close()
			var message := "Data permainan diubah oleh admin atau sesi lain. Posisi dan progres terbaru telah dimuat."
			if bool(GameState.homestead.get("inside",false)):
				get_tree().change_scene_to_file("res://scenes/homestead.tscn")
			elif str(GameState.surface.get("area","hub")) == "forest":
				get_tree().set_meta("surface_change_notice",message)
				get_tree().change_scene_to_file("res://scenes/forest.tscn")
			else:
				nala.position = _surface_point()
				nala.land_path.reset(nala.position)
				_update_hud()
				status.text = message
				hud.message(message)
			_restore_player_movement()
		else:
			status.text = str(refreshed.get("error","Perubahan data belum dapat dimuat. Coba sambungkan kembali."))
		return false
	status.text = str(r.get("error","Koneksi jalur darat terganggu."))
	return false
func _enter_forest() -> void:
	network_busy = true
	while syncing:
		await get_tree().process_frame
	if not await _sync_surface():
		network_busy = false
		return
	var r: Dictionary = await ApiClient.call_api("/adventure/travel",{"destination":"forest"})
	network_busy = false
	if r.get("ok",false):
		GameState.surface = r.surface
		get_tree().change_scene_to_file("res://scenes/forest.tscn")
	else:
		status.text = str(r.get("error","Jalur hutan belum dapat dilewati."))
func _show_character(first: bool) -> void:
	if not GameState.dive.is_empty() or not GameState.shift.is_empty():
		_show_message("Tampilan penjelajah","Kembali dan tutup kedai sebelum mengganti tampilan. Statistik semua tampilan sama.")
		return
	var box := _open("Pilih tampilan Nala")
	_label(box,"Empat penjelajah, satu perjalanan. Pilihan ini tersimpan di akun; kemampuan semuanya sama.",14)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	box.add_child(grid)
	var choices := [["male_default","Laki-laki · Nala","Kaos harian, perlengkapan sesuai medan"],["male_nusantara","Laki-laki · Pesisir Nusantara","Sawo matang, aksen kain pesisir"],["female_default","Perempuan · Nala","Kaos harian, perlengkapan sesuai medan"],["female_nusantara","Perempuan · Pesisir Nusantara","Busana modern dengan aksen tenun"]]
	for index in range(choices.size()):
		var choice: Array = choices[index]
		var id := str(choice[0])
		var button := _button(grid,str(choice[1])+"\n"+str(choice[2]),func():
			if network_busy:
				return
			network_busy = true
			var r: Dictionary = await ApiClient.call_api("/game/appearance",{"appearance":id})
			network_busy = false
			if r.get("ok",false):
				GameState.player = r.player
				if not GameState.surface.is_empty():
					GameState.surface["playerVersion"] = int(r.player.get("version",0))
				surface_clock = 0.0
				nala.land_path.reset(nala.position)
				_close()
				if first and not GameState.player.progress.get("tutorial",false):
					_story_intro()
			else:
				status.text = str(r.get("error","Tampilan belum tersimpan."))
		)
		button.custom_minimum_size = Vector2(280,144)
		button.add_theme_font_size_override("font_size",12)
		var path := "res://resources/art/"+id.replace("_","-")+"-base-v1.png"
		if ResourceLoader.exists(path):
			var texture: Texture2D = load(path)
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2.ZERO,Vector2(texture.get_size())/3.0)
			button.icon = atlas
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width",60)
		if index==0:
			button.grab_focus()
	if not first:
		_button(box,"Kembali",_close)

func _add_lights() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,1,1,.85),Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(.5,.5)
	texture.fill_to = Vector2(1,.5)
	dive_lamp = PointLight2D.new()
	dive_lamp.texture = _torch_texture()
	dive_lamp.color = Color(.55,.85,.76)
	dive_lamp.energy = .65
	dive_lamp.texture_scale = 2.0
	dive_lamp.position = Vector2(32,-8)
	dive_lamp.offset = Vector2.ZERO
	dive_lamp.shadow_enabled = true
	dive_lamp.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	dive_lamp.shadow_color = Color(0.04,0.09,0.13,0.65)
	nala.add_child(dive_lamp)
	for district in GameState.world.get("surface_hub",{}).get("districts",[]):
		var at := Vector2(float(district.x),float(district.y)) + Vector2(-28,-80)
		var lamp := PointLight2D.new()
		lamp.texture = texture
		lamp.position = at
		lamp.texture_scale = 2.1
		lamp.color = Color(1,.67,.34)
		lamp.energy = 1.25
		add_child(lamp)
		port_lamps.append(lamp)

func _torch_texture() -> Texture2D:
	# The centered texture's left half is empty, so its cone starts at the lamp mount.
	var image := Image.create(384,192,false,Image.FORMAT_RGBA8)
	for y in 192:
		for x in range(192,384):
			var along := float(x-192)/192.0
			var across := absf(float(y)-96.0)/96.0
			var width := 0.035+along*0.80
			var edge := 1.0-smoothstep(width*0.55,width,across)
			var reach := (1.0-smoothstep(0.45,1.0,along))*smoothstep(0.0,0.025,along)
			image.set_pixel(x,y,Color(1,1,1,edge*reach*0.72))
	return ImageTexture.create_from_image(image)

func _flashlight_status_2d() -> Dictionary:
	if not is_instance_valid(dive_lamp): return {}
	var at := dive_lamp.global_position
	var ahead := at+Vector2.RIGHT.rotated(dive_lamp.global_rotation)*560.0
	return {"mount":[at.x,at.y],"aim":[ahead.x,ahead.y],"facing":nala.direction,"active":dive_lamp.visible}

func _surface_point() -> Vector2:
	var spawn: Dictionary = GameState.world.get("surfaceSpawn",{})
	return Vector2(float(GameState.surface.get("x",spawn.get("x",0))),float(GameState.surface.get("y",spawn.get("y",0))))
