extends Node2D
const PlayerScript = preload("res://scripts/Player.gd")
const WorldScript = preload("res://scripts/World.gd")
const EntitiesScript = preload("res://scripts/Entities.gd")
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
var attack_clock := 0.0
var attacks: Array = []
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
		return
	var result: Dictionary = await GameState.refresh()
	if not result.get("ok",false):
		_show_message("Koneksi belum tersambung",str(result.get("error","Coba muat ulang halaman.")))
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
		add_child(actor)
		surface_actors.append(actor)
	nala.position = _surface_point()
	nala.frozen = false
	if GameState.dive.is_empty() and is_instance_valid(terrain.scenery) and terrain.scenery.has_method("nearest_walkable"):
		nala.position = terrain.scenery.nearest_walkable(nala.position)
	if str(GameState.surface.get("area","hub"))=="forest" and GameState.dive.is_empty():
		get_tree().change_scene_to_file("res://scenes/forest.tscn")
		return
	nala.land_path.reset(nala.position)
	land_renderer = preload("res://scripts/land/LandWorld3D.gd").new()
	add_child(land_renderer)
	land_renderer.setup(self,nala,camera,"hub")
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
	if not GameState.player.has("appearance") and GameState.dive.is_empty() and GameState.shift.is_empty():
		_show_character(true)
	elif not GameState.player.progress.get("tutorial",false):
		_story_intro()
	if OS.has_feature("web"):
		var window = JavaScriptBridge.get_interface("window")
		window.jalasmaraReady = true
		window.parent.postMessage(JavaScriptBridge.get_interface("JSON").parse('{"type":"jalasmara:ready"}'),str(window.location.origin))
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
	hud.move_changed.connect(func(direction: Vector2): nala.touch = direction)
	status = hud.status_label
	hint = Label.new()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.theme = hud.root_control.theme
	hud.add_child(ui)
func _button(parent: Node, text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 42
	b.pressed.connect(callback)
	parent.add_child(b)
	return b
func _label(parent: Node, text: String, size := 16) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	parent.add_child(label)
	return label
func _open(title: String, pause_reading := true) -> VBoxContainer:
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
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("f1e1bc")
	bg.content_margin_left = 25
	bg.content_margin_right = 25
	bg.content_margin_top = 20
	bg.content_margin_bottom = 20
	bg.set_corner_radius_all(2)
	bg.border_color = Color("654733")
	bg.set_border_width_all(2)
	modal.add_theme_stylebox_override("panel",bg)
	ui.add_child(modal)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600,370)
	modal.add_child(scroll)
	modal_box = VBoxContainer.new()
	modal_box.custom_minimum_size.x = 590
	modal_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_box.add_theme_constant_override("separation",12)
	scroll.add_child(modal_box)
	_label(modal_box,title,23)
	if pause_reading and not GameState.dive.is_empty():
		ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":true})
	return modal_box
func _close() -> void:
	if modal:
		modal.queue_free()
		modal = null
	modal_open = false
	hud.set_modal(false)
	nala.frozen = false
	if not GameState.dive.is_empty():
		ApiClient.call_api("/dive/reading",{"diveId":GameState.dive.id,"paused":false})
func _show_message(title: String, text: String) -> void:
	var box := _open(title)
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
	var box := _open(str(line.name))
	_label(box,str(line.text),18)
	_button(box,"Lanjut",_next_line).grab_focus()
func _story_intro() -> void:
	_talk([
		{"name":"Babak 1 · Kabut dan Kopi Pahit","text":"Bandar Hujung terapung di atas ingatan yang tenggelam. Kabut Nir-Aksara membuat warga lupa ilmu yang dahulu mereka kuasai. Kapal Nala rusak, dan uang sewanya hampir habis."},
		{"name":"Beno","text":"Kapalmu bisa kuperbaiki. Gratis? Hampir. Bantu Mbah Wira membuka Kedai Waras, dan jangan sentuh tuas merah di bengkelnya."},
		{"name":"Nala","text":"Baik. Utang kapal dibayar dengan kopi. Sejauh ini rencana hidupku makin masuk akal."},
		{"name":"Mbah Wira","text":"Di bawah dermaga ada ingatan yang mengkristal. Berenanglah. Amati taman tua itu. Tidak semua ilmu datang dari menjawab pertanyaan: banyak yang hanya perlu kamu temukan."},
		{"name":"Petualangan dimulai","text":"WASD / arah: bergerak. E: bicara atau mengamati. Tahan lalu lepas spasi: Jala Kognisi. M: peta, J: jurnal, I: tas. Datangi tangga selam di kanan Galangan Bubat; kembali ke tangga untuk naik."}
	],func():
		await ApiClient.call_api("/game/tutorial",{})
		await GameState.refresh()
		_update_hud()
	)
func _process(delta: float) -> void:
	EnvironmentState.clock_paused = modal_open or GameState.dive.has("challenge")
	if not nala:
		return
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
	_find_nearby()
	if Engine.get_process_frames()%10==0:
		_update_hud()
	if status.text != last_status:
		last_status = status.text
		hud.message(last_status)
	if GameState.dive.is_empty() and not modal_open:
		surface_clock += delta
		if (surface_clock>1.3 or (nala.land_path.needs_flush() and surface_clock>1.0)) and not network_busy and not syncing:
			surface_clock = 0
			_sync_surface()
	entities.nearest = str(nearby.get("id",""))
	if OS.has_feature("web") and Time.get_ticks_msec()-snapshot_at>=100:
		snapshot_at = Time.get_ticks_msec()
		var snapshot := {"x":nala.position.x,"y":nala.position.y,"stage":GameState.player.get("progress",{}).get("stage",""),"modal":modal_open,"nearby":str(nearby.get("id","")),"diving":not GameState.dive.is_empty()}
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
	if modal_open and is_instance_valid(modal) and modal.get_meta("world_map",false) and Input.is_action_just_pressed("map"):
		_close()
		return
	if not modal_open:
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
		if not modal_open and not network_busy and flash<=0:
			for hazard in GameState.world.get("hazards",[]):
				if nala.position.distance_to(Vector2(float(hazard.x),float(hazard.y)))<float(hazard.radius)+18:
					flash = 3.1
					_hazard_hit()
					break
		if not modal_open and GameState.dive.get("mode","")=="boss" and nala.position.distance_to(Vector2(3820,3140))<650:
			_boss_tick(delta)
		else:
			for shot in attacks:
				shot.node.queue_free()
			attacks.clear()
func _draw() -> void:
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
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F6 and is_instance_valid(hybrid):
		hybrid.enabled = not hybrid.enabled
	if event.is_action_pressed("ui_cancel") and modal_open and chain_lines.is_empty() and not GameState.dive.has("challenge"):
		_close()
func _find_nearby() -> void:
	nearby = {}
	var best := 140.0
	var objects: Array = []
	if GameState.dive.is_empty():
		for district in GameState.world.get("surface_hub",{}).get("districts",[]):
			objects.append({"id":district.id,"x":district.x,"y":district.y,"name":district.npc,"kind":"npc"})
		var gate: Dictionary = GameState.world.get("forest",{}).get("gate",{})
		objects.append({"id":"forest_gate","x":gate.get("x",0),"y":gate.get("y",0),"name":"Jalur ke Hutan Pesisir","kind":"forest"})
		var ladder: Dictionary = GameState.world.get("hub",{}).get("divePoint",{})
		objects.append({"id":"ladder","x":ladder.get("x",0),"y":ladder.get("y",0),"name":"Tangga Palung Smara","kind":"dive"})
	else:
		objects.append({"id":"boat","x":1120,"y":470,"name":"Tangga pulang ke Bandar Hujung","kind":"extract"})
		for collection in ["landmarks","puzzles","caches"]:
			for item in GameState.world.get(collection,[]):
				var obj: Dictionary = item.duplicate()
				obj.kind = collection
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
				var point: Vector2 = entities.target_position(target)
				obj.x = point.x
				obj.y = point.y
				obj.name = _biota_name(str(target.subject))
				objects.append(obj)
	for obj in objects:
		var distance := nala.position.distance_to(Vector2(float(obj.x),float(obj.y)))
		if distance<best:
			best = distance
			nearby = obj
	if nearby.is_empty():
		hint.text = "WASD / arah: bergerak · E: amati · Tahan & lepas spasi: jala · M: peta"
	else:
		hint.text = ("Tahan & lepas spasi: " if nearby.kind=="biota" else "[E] ")+str(nearby.name)
func _biota_name(subject: String) -> String:
	return "Ubur-Ubur Klorofil" if subject=="Biologi" else "Ikan Simpul Ekosistem" if subject=="Lingkungan" else "Keong Rasio" if subject=="Matematika" else "Ikan Lentera Alkalin"
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
	var goal := "Layani warga di Kedai Waras." if stage=="night" else "Pulihkan Gajah Mina di Tamansari." if stage=="boss" else "Prasasti Smara Kuno ditemukan. Fase 1 selesai." if stage=="done" else "Jelajahi Segaran dan jala bekal kedai. Hutan ada di timur dermaga." if day==1 else "Amati Nitrogen, Fotosintesis, dan Osmosis di Wringin." if day==2 else "Selidiki pipa dan pulihkan penyaring Jalatunda."
	var d: Dictionary = GameState.dive
	var state := {"area":region,"depth":depth,"diving":not d.is_empty(),"oxygen":d.get("oxygen",0),"maxOxygen":d.get("maxOxygen",100),"coins":p.coins,"weight":d.get("weight",0),"capacity":d.get("capacity",12),"objective":goal,"action":str(nearby.get("name","Dekati tempat atau tokoh")),"canInteract":not nearby.is_empty() and nearby.get("kind","")!="biota","canNet":nearby.get("kind","")=="biota" and not d.is_empty()}
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
	if OS.has_feature("web"):
		var snapshot := {"x":nala.position.x,"y":nala.position.y,"stage":GameState.player.get("progress",{}).get("stage",""),"modal":modal_open,"nearby":str(nearby.get("id","")),"diving":not GameState.dive.is_empty()}
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
		"npc":
			_npc_interact(str(obj.name))
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
	var r: Dictionary = await ApiClient.call_api("/dive/extract",{"diveId":GameState.dive.id})
	network_busy = false
	if not r.get("ok",false):
		status.text = str(r.get("error","Belum dapat kembali."))
		return
	GameState.dive = {}
	if r.has("surface"):
		GameState.surface = r.surface
	nala.velocity = Vector2.ZERO
	await GameState.refresh()
	nala.position = _surface_point()
	nala.land_path.reset(nala.position)
	camera.reset_smoothing()
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
	_label(box,str(challenge.question.prompt),19)
	if challenge.get("answered",false):
		_label(box,str(challenge.result.explanation))
		_button(box,"Lanjutkan pemulihan",func():
			var r: Dictionary = await ApiClient.call_api("/dive/continue",{"diveId":GameState.dive.id,"challengeId":challenge.id})
			if r.get("ok",false):
				GameState.dive = r.dive
				_close()
				if int(GameState.dive.get("hits",0))>=_required_hits():
					_extract()
		)
	else:
		for i in range(challenge.question.options.size()):
			var selected := i
			_button(box,str(challenge.question.options[i]),func():
				if network_busy:
					return
				network_busy = true
				var r: Dictionary = await ApiClient.call_api("/dive/catch",{"diveId":GameState.dive.id,"challengeId":challenge.id,"selectedOption":selected})
				network_busy = false
				if r.get("ok",false):
					GameState.dive = r.dive
					_show_quiz()
			)
		_label(box,"Serangan berhenti selama resonansi. Jawab dengan pemahaman, lalu lanjutkan menghindari serangan.",13)
func _npc_interact(name_text: String) -> void:
	network_busy = true
	while syncing: await get_tree().process_frame
	var saved := await _sync_surface()
	network_busy = false
	if not saved: return
	if name_text=="Mbah Wira":
		if GameState.player.progress.stage=="night":
			_open_kedai()
		elif GameState.player.progress.stage=="boss":
			_talk([{"name":"Babak 4 · Sabotase di Kedai Waras","text":"Inspektur Raka menuntut kedai ditutup: pengetahuan tanpa lisensi, katanya. Lalu gempa mengguncang dermaga. Pipa raksasa di Tamansari pecah, dan sesuatu menarik jangkar kota."},{"name":"Nala","text":"Dia kabur sebelum selesai membacakan pasalnya. Aku anggap itu izin menyelam."},{"name":"Mbah Wira","text":"Gajah Mina sedang kesakitan. Netralisasi lapisan racunnya dalam simulasi alatmu, lepaskan pipa, dan pulihkan inti ingatannya. Jangan lukai sang penjaga. Tabung dan jala level tiga harus siap."}])
		else:
			_talk([{"name":"Mbah Wira","text":"Kedai buka setelah kamu kembali membawa fragmen. Jika bekal kurang, tutup sementara dan cari lagi. Pelanggan yang sudah dilayani tetap tercatat."},{"name":"Nala","text":"Baik. Menjaring ingatan dulu, meracik solusi kemudian."}])
	elif name_text=="Beno":
		_show_upgrades()
	elif name_text=="Bu Darmi":
		_talk([{"name":"Babak 2 · Kebun Apung yang Sekarat","text":"Daun kebun apung menguning dan akarnya membusuk. Kabut membuat Bu Darmi lupa bagaimana cahaya, unsur hara, dan air menopang tanaman."},{"name":"Bu Darmi","text":"Raka menawarkan Kapsul Tani dengan harga tiga kali penghasilanku. Aku ingin memahami kebunku lagi, bukan sekadar menyuruh tanaman hidup sehari."},{"name":"Nala","text":"Di Wringin ada Koral Nitrogen, Lentera Fotosintesis, dan Kerang Osmosis. Aku akan membawa catatannya pulang."}])
	else:
		_talk([{"name":"Inspektur Raka","text":"PT Cakrawala Sintetis menyediakan Kapsul Instan untuk seluruh kebutuhan kerja Anda. Belajar mandiri meningkatkan risiko kesalahan prosedur."},{"name":"Nala","text":"Menarik. Apakah prosedurnya juga menjelaskan pipa yang bocor di bawah kota?"},{"name":"Inspektur Raka","text":"Akses ke fasilitas Sektor Tuban-7 dibatasi. Percakapan ini dicatat."}])
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
	var box := _open("Malam di Kedai Waras")
	var current: Dictionary = {}
	for customer in GameState.shift.get("customers",[]):
		if not GameState.shift.get("served",[]).has(customer.id):
			current = customer
			break
	if current.is_empty():
		_label(box,"Semua pelanggan mulai mengingat kembali. Mbah Wira menutup buku racikan malam ini.")
		_button(box,"Tutup kedai · lanjutkan cerita",func(): await _close_shift(false))
	else:
		_label(box,str(current.customer),20)
		_label(box,"“"+str(current.complaint)+"”",18)
		_label(box,"Pilih fragmen untuk meracik Seduhan Solusi:",14)
		var any := false
		for item in GameState.player.get("inventory",[]):
			if int(item.quantity)<=0:
				continue
			any = true
			var selected: Dictionary = item.duplicate()
			_button(box,"%s · %d bintang · %d buah" % [GameState.fragment_name(str(item.fragmentId)),int(item.stars),int(item.quantity)],func():
				var r: Dictionary = await ApiClient.call_api("/kedai/serve",{"shiftId":GameState.shift.id,"recipeId":current.id,"fragmentId":selected.fragmentId,"stars":int(selected.stars)})
				if r.get("ok",false):
					GameState.player = r.player
					GameState.shift = r.shift
					var result_box := _open(str(current.customer))
					_label(result_box,str(r.solution))
					_label(result_box,"+%d koin" % int(r.earned))
					_button(result_box,"Pelanggan berikutnya",_kedai_customer)
					_update_hud()
				else:
					status.text = str(r.get("error","Fragmen belum sesuai."))
			)
		if not any:
			_label(box,"Tas kosong. Tutup kedai sementara untuk kembali menyelam.")
		_button(box,"Tutup sementara · cari stok",func(): await _close_shift(true))
	_button(box,"Berjalan di dermaga",_close)
func _close_shift(abandon: bool) -> void:
	var r: Dictionary = await ApiClient.call_api("/kedai/close-shift",{"shiftId":GameState.shift.id,"abandon":abandon})
	if r.get("ok",false):
		await GameState.refresh()
		_update_hud()
		_close()
		if not abandon:
			if int(GameState.player.progress.day)==2:
				_npc_interact("Bu Darmi")
			elif int(GameState.player.progress.day)==3 and GameState.player.progress.stage=="dive":
				_talk([{"name":"Babak 3 · Air yang Berubah Ungu","text":"Kebun mulai pulih, tetapi air di bawah permukiman berubah keruh. Beno menemukan jejak asam dari jalur pipa Sektor Tuban-7."},{"name":"Beno","text":"Jangan campur apa pun ke air itu. Selidiki alirannya di Jalatunda. Ada instalasi penyaring lama yang mungkin masih bisa dihidupkan."}])
			else:
				_npc_interact("Mbah Wira")
	else:
		status.text = str(r.get("error","Giliran belum selesai."))
func _show_inventory() -> void:
	var box := _open("Tas Nala")
	_label(box,"%d koin · Fragmen permanen" % int(GameState.player.get("coins",0)))
	preload("res://scripts/InventoryView.gd").add_rows(box,GameState.player.get("inventory",[]))
	if GameState.player.get("inventory",[]).is_empty():
		_label(box,"Belum ada fragmen yang dibawa pulang.",14)
	if not GameState.dive.is_empty():
		_label(box,"Di dalam jala: %d/%d kg. Kembali ke tangga untuk menyimpannya." % [int(GameState.dive.weight),int(GameState.dive.capacity)],14)
	for key in GameState.adventure.get("keyItems",[]):
		_label(box,"Benda penting: Prasasti Smara Kuno" if key=="prasasti_smara_kuno" else str(key),14)
	_button(box,"Tutup tas",_close)
func _show_journal() -> void:
	var box := _open("Jurnal Smara")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(590,260)
	box.add_child(scroll)
	var entries := VBoxContainer.new()
	entries.custom_minimum_size.x = 560
	entries.add_theme_constant_override("separation",14)
	scroll.add_child(entries)
	var count := 0
	for item in GameState.world.get("landmarks",[])+GameState.world.get("forest",{}).get("landmarks",[]):
		if GameState.adventure.get("discoveries",[]).has(item.id):
			count += 1
			_label(entries,str(item.title),18)
			_label(entries,str(item.text),14)
	if count==0:
		_label(entries,"Temukan prasasti dan tempat pengamatan. Catatan yang kamu amati tersimpan di sini, tanpa perlu menjawab kuis.",16)
	_label(entries,"Catatan biologi: lamun adalah tumbuhan berbunga laut; kelp adalah alga cokelat. Hutan Wringin adalah ekosistem fantasi yang menggabungkan biota bercahaya.",13)
	_button(box,"Tutup jurnal",_close)
func _show_map() -> void:
	if modal_open and is_instance_valid(modal) and modal.get_meta("world_map",false):
		_close()
		return
	var box := _open("Atlas Jalasmara")
	modal.set_meta("world_map",true)
	modal.position = Vector2(105,38)
	modal.size = Vector2(750,480)
	var scroll: ScrollContainer = modal.get_child(0)
	scroll.custom_minimum_size = Vector2(690,430)
	box.custom_minimum_size.x = 680
	var atlas = preload("res://scripts/WorldAtlas.gd").new()
	box.add_child(atlas)
	atlas.configure(GameState.world,GameState.player,"harbor" if GameState.dive.is_empty() else "reef" if int(GameState.player.progress.day)==1 else "kelp" if int(GameState.player.progress.day)==2 else "cave")
	atlas.set_player_position(nala.position)
	atlas.close_requested.connect(_close)
func _boss_tick(delta: float) -> void:
	if int(GameState.dive.get("hits",0))>=_required_hits():
		return
	attack_clock += delta
	var second_phase := int(GameState.dive.get("hits",0))>=ceili(_required_hits()/2.0)
	status.text = "Gajah Mina · %d/300 vitalitas racun · %s" % [300-int(int(GameState.dive.get("hits",0))*300.0/_required_hits()),"Tarik Inti Smara" if second_phase else "Lepaskan lapisan asam"]
	if attack_clock>(2.6 if second_phase else 3.5):
		attack_clock = 0
		var projectile := Polygon2D.new()
		projectile.polygon = PackedVector2Array([Vector2(-12,-5),Vector2(12,-5),Vector2(18,0),Vector2(12,5),Vector2(-12,5)])
		projectile.color = Color("a6b175")
		projectile.position = Vector2(3570,2900+randf()*480)
		add_child(projectile)
		attacks.append({"node":projectile,"velocity":Vector2(-180,0)})
		if second_phase:
			var sludge := projectile.duplicate() as Polygon2D
			sludge.position = Vector2(3300+randf()*900,2900)
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
	var route: Dictionary = nala.land_path.snapshot(nala.position)
	var r: Dictionary = await ApiClient.call_api("/adventure/surface-position",{"area":"hub","x":nala.position.x,"y":nala.position.y,"path":route.path,"fromPositionAt":int(GameState.surface.get("positionAt",0)),"version":int(GameState.player.get("version",0))})
	syncing = false
	if r.get("ok",false):
		GameState.surface = r.surface
		nala.land_path.acknowledge(int(route.ticket))
		return true
	if str(r.get("code","")) in ["SESSION_CHANGED","AREA_CHANGED","POSITION_CHANGED"]:
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
			if str(GameState.surface.get("area","hub")) == "forest":
				get_tree().set_meta("surface_change_notice",message)
				get_tree().change_scene_to_file("res://scenes/forest.tscn")
			else:
				nala.position = _surface_point()
				nala.land_path.reset(nala.position)
				_update_hud()
				status.text = message
				hud.message(message)
			nala.frozen = false
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
	var choices := [["male_default","Laki-laki · Penyelam","Rompi oranye dan peralatan rakitan"],["male_nusantara","Laki-laki · Pesisir Nusantara","Sawo matang, lurik modern"],["female_default","Perempuan · Penyelam","Rompi oranye dan perlengkapan ringan"],["female_nusantara","Perempuan · Pesisir Nusantara","Kemben modern, perlengkapan pesisir"]]
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
				_close()
				if first and not GameState.player.progress.get("tutorial",false):
					_story_intro()
			else:
				status.text = str(r.get("error","Tampilan belum tersimpan."))
		)
		button.custom_minimum_size = Vector2(280,144)
		button.add_theme_font_size_override("font_size",12)
		var path := "res://resources/art/"+id.replace("_","-")+".png"
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
