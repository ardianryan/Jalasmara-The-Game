extends CanvasLayer

const HudArt=preload("res://scripts/HudSkin.gd")
const BODY_FONT=preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
var host: Node
var inside := false
var is_open := false
var busy := false
var root_control: Control
var panel: PanelContainer
var content: VBoxContainer
var message_label: Label
var game_hud: CanvasLayer
var _current_id := ""
var _pending: Dictionary={}
var _position_clock := 0.0
var _last_position := Vector2.ZERO
var _position_busy := false
var _home_path:=preload("res://scripts/land/LandPath.gd").new()
var _path_ready := false
var _snapshot_at := 0

func _ready() -> void:
	layer=15
	if get_parent().has_method("get_nearby"):
		configure(get_parent(),true)

func configure(owner_node: Node,home_inside := false) -> void:
	if is_instance_valid(root_control): return
	host=owner_node
	inside=home_inside
	root_control=Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	get_viewport().size_changed.connect(_layout_page)
	if inside:
		game_hud=preload("res://scripts/GameHud.gd").new()
		host.add_child.call_deferred(game_hud)
		game_hud.interact_requested.connect(func(): if not is_open and not busy: host.interact())
		game_hud.move_changed.connect(func(direction: Vector2): if is_instance_valid(host.player): host.player.touch=direction)
		game_hud.journal_requested.connect(func(): open_for("archive"))
		game_hud.inventory_requested.connect(func(): open_for("inventory"))
		game_hud.character_requested.connect(func(): open_for("appearance"))
		game_hud.map_requested.connect(func(): open_for("home_map"))
		game_hud.objective_requested.connect(show_objective)
		host.interaction_requested.connect(open_for)
		_publish_ready.call_deferred()

func _publish_ready() -> void:
	await get_tree().process_frame
	if not OS.has_feature("web"): return
	var window=JavaScriptBridge.get_interface("window")
	window.jalasmaraReady=true
	window.parent.postMessage(JavaScriptBridge.get_interface("JSON").parse('{"type":"jalasmara:ready"}'),str(window.location.origin))

func _process(delta: float) -> void:
	if not is_instance_valid(host) or GameState.player.is_empty(): return
	if inside:
		if is_instance_valid(host.player):
			if not _path_ready:
				_home_path.reset(host.player.position)
				_path_ready=true
			_home_path.record(host.player.position)
			host.player.frozen=is_open or _home_path.full()
		EnvironmentState.clock_paused=is_open
		if is_instance_valid(game_hud) and is_instance_valid(game_hud.root_control):
			var state:=EnvironmentState.snapshot()
			state.merge({"area":"Griya Sasmita","coins":GameState.player.get("coins",0),"objective":"Tidur untuk menyelesaikan hari." if GameState.homestead.get("pendingStoryAdvance",false) else "Rumah Nala · arsip, peti, dan istirahat.","action":_object_name(str(host.get_nearby())),"canInteract":not str(host.get_nearby()).is_empty() and not busy,"canNet":false,"diving":false,"weight":0,"capacity":0},true)
			game_hud.update_state(state)
		_position_clock+=delta
		if _position_clock>1.1 and not busy and not _position_busy and not is_open and is_instance_valid(host.player):
			_position_clock=0
			if host.player.position.distance_to(_last_position)>1:
				_sync_position()
		if OS.has_feature("web") and preload("res://scripts/Diagnostics.gd").enabled() and Time.get_ticks_msec()-_snapshot_at>100:
			_snapshot_at=Time.get_ticks_msec()
			var snapshot: Dictionary=host.debug_snapshot()
			snapshot["homestead"]=GameState.homestead
			snapshot["calendar"]=GameState.calendar
			snapshot["weather"]=EnvironmentState.snapshot()
			snapshot["diving"]=false
			snapshot["homePanel"]=is_open
			snapshot["outfit"]=host.player.outfit if is_instance_valid(host.player) else "daily"
			JavaScriptBridge.get_interface("window").jalasmaraSnapshot=JavaScriptBridge.get_interface("JSON").parse(JSON.stringify(snapshot))
	if is_open and Input.is_action_just_pressed("ui_cancel") and not busy:
		close()

func _object_name(id: String) -> String:
	return str({"bed":"Istirahat di dipan","archive":"Buka arsip Nala","chest":"Buka peti","display":"Lihat rak pameran","exit":"Keluar rumah"}.get(id,"Dekati benda di rumah"))

func _set_modal(active: bool) -> void:
	is_open=active
	if not is_instance_valid(host): return
	if host.has_method("set_interaction_modal"): host.set_interaction_modal(active)
	elif host.has_method("set_modal"): host.set_modal(active)
	if is_instance_valid(game_hud): game_hud.set_modal(active)
	EnvironmentState.clock_paused=active

func show_objective(text: String) -> void:
	if busy or is_open: return
	_page("Tujuan perjalanan")
	_text(text)
	_button("Kembali",close)

func _ui_font() -> int:
	return preload("res://scripts/UiMetrics.gd").body(self)

func _ui_target() -> float:
	return preload("res://scripts/UiMetrics.gd").target(self)

func _layout_page() -> void:
	if not is_instance_valid(panel): return
	var view:=get_viewport().get_visible_rect().size
	var safe:=ViewportLayout.insets()
	var ratio:=preload("res://scripts/UiMetrics.gd").ratio(self)
	var edge:=ceilf(16*ratio)
	var top:=ceilf(60*ratio)+safe.y
	var width:=minf(760*ratio,view.x-edge*2-safe.x-safe.z)
	panel.position=Vector2(safe.x+(view.x-safe.x-safe.z-width)*.5,top)
	panel.size=Vector2(width,view.y-top-edge-safe.w)
	for label in panel.find_children("*","Label",true,false):
		label.add_theme_font_size_override("font_size",maxi(_ui_font(),ceili(int(label.get_meta("base_font_size",16))*ratio)))
	for control in panel.find_children("*","Button",true,false):
		control.custom_minimum_size.y=_ui_target()
		control.add_theme_font_size_override("font_size",_ui_font())
		HudArt.apply_button(control)
	if content!=null: content.add_theme_constant_override("separation",ceili(10*ratio))

func _page(title: String) -> void:
	if is_instance_valid(panel):
		root_control.remove_child(panel)
		panel.queue_free()
	_set_modal(true)
	panel=PanelContainer.new()
	panel.name="HomesteadPanel"
	var viewport_size:=get_viewport().get_visible_rect().size
	var safe:=ViewportLayout.insets()
	var top:=ceilf(60*preload("res://scripts/UiMetrics.gd").ratio(self))+safe.y
	panel.position=Vector2(maxf(16+safe.x,(viewport_size.x-760)*.5),top)
	panel.size=Vector2(minf(760,viewport_size.x-32-safe.x-safe.z),viewport_size.y-top-16-safe.w)
	panel.add_theme_stylebox_override("panel",HudArt.panel("paper"))
	root_control.add_child(panel)
	var scroll:=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	panel.add_child(scroll)
	content=VBoxContainer.new()
	content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	scroll.add_child(content)
	var heading:=Label.new()
	heading.text=title
	heading.add_theme_color_override("font_color",Color("302d2a"))
	heading.set_meta("base_font_size",23)
	heading.add_theme_font_size_override("font_size",maxi(ceili(23*preload("res://scripts/UiMetrics.gd").ratio(self)),_ui_font()))
	heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	message_label=_text("")
	message_label.visible=false
	_layout_page()

func _text(value: String) -> Label:
	var label:=Label.new()
	label.text=value
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font",BODY_FONT)
	label.add_theme_font_size_override("font_size",_ui_font())
	label.add_theme_color_override("font_color",Color("302d2a"))
	content.add_child(label)
	return label

func _button(value: String,action: Callable) -> Button:
	var button:=Button.new()
	button.text=value
	button.custom_minimum_size.y=_ui_target()
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font",BODY_FONT)
	button.add_theme_font_size_override("font_size",_ui_font())
	HudArt.apply_button(button)
	button.pressed.connect(action)
	var first_button:=true
	for child in content.get_children():
		if child is Button: first_button=false
	content.add_child(button)
	if first_button: button.grab_focus.call_deferred()
	return button

func close() -> void:
	if busy: return
	if is_instance_valid(panel):
		root_control.remove_child(panel)
		panel.queue_free()
	panel=null
	_set_modal(false)

func open_for(id: String) -> void:
	if busy: return
	if not _pending.is_empty():
		_page("Kegiatan menunggu konfirmasi")
		_text("Ada kegiatan yang belum dipastikan hasilnya. Kirim ulang kegiatan yang sama untuk mengambil hasil tanpa menggandakan barang atau hari.")
		_button("Periksa kegiatan sebelumnya",_retry_pending)
		_button("Kembali",close)
		return
	_current_id=id
	match id:
		"home_enter":
			_page("Griya Sasmita")
			_text("Rumah warisan Nala. Di dalam tersedia dipan, arsip, peti, dan rak pameran.")
			_button("Masuk rumah",func(): _perform("enter"))
		"exit":
			_perform("exit")
			return
		"bed": _bed()
		"archive": _archive()
		"chest": _chest()
		"inventory": _inventory()
		"display": _display()
		"market": _market()
		"fish_pen": _fish_pen()
		"balai": _balai()
		"kedai_stock": _kedai_stock()
		"wira":
			_page("Mbah Wira · Kedai Waras")
			_text("Ada hasil kebun yang dapat dititipkan sebagai bahan pelengkap kedai.")
			_button("Titipkan bahan kebun",func(): open_for("kedai_stock"))
			_button("Bicara dan pelayanan kedai",func():
				close()
				host._npc_interact("Mbah Wira")
			)
		"appearance":
			_page("Pakaian di rumah")
			_text("Nala mengenakan baju harian. Pilihan penampilan tersedia kembali setelah keluar rumah; kemampuan dan perlengkapan tersimpan di akun.")
		"home_map":
			_page("Griya Sasmita · Bandar Hujung")
			_text("Pintu rumah terhubung dengan jalan desa menuju Kedai Waras. Petak kebun berada di rakit di luar rumah. Keluar melalui pintu selatan untuk kembali ke desa.")
		_:
			if id.begins_with("plot_"): _plot(id)
			else: return
	_button("Kembali",close)
	for child in content.get_children():
		if child is Button:
			child.grab_focus.call_deferred()
			break

func _bed() -> void:
	_page("Dipan Rotan · Tidur")
	var day:=int(GameState.calendar.get("calendarDay",1))
	_text("Hari %d · %s. Tidur menuju pukul 06.00 berikutnya. Progres kegiatan disimpan server." % [day,str(EnvironmentState.snapshot().clock)])
	if GameState.homestead.get("pendingStoryAdvance",false):
		_text("Pelayanan kedai sudah lengkap. Istirahat akan melanjutkan cerita ke pagi berikutnya.")
	else:
		_text("Tidur memajukan kalender dan pertumbuhan yang memenuhi syarat. Misi cerita tetap mengikuti hasil permainanmu.")
	var early:=float(GameState.calendar.get("minuteOfDay",480))>=360 and float(GameState.calendar.get("minuteOfDay",480))<1080
	if early: _text("Masih siang. Dengan memilih tidur, Nala akan melewati sisa kegiatan hari ini.")
	_button("Lewati hari ini dan tidur" if early else "Tidur sampai pagi",func(): _perform("sleep",{"confirmEarly":early}))

func _archive() -> void:
	_page("Meja Arsip · Catatan Nala")
	var discoveries: Array=GameState.adventure.get("discoveries",[])
	_text("Temuan yang tersimpan: %d. Siklus cerita %d." % [discoveries.size(),int(GameState.player.get("progress",{}).get("day",1))])
	var found:=false
	for group in ["landmarks","puzzles","caches"]:
		for entry in GameState.world.get(group,[]):
			if discoveries.has(str(entry.get("id",""))):
				found=true
				_text(str(entry.get("name",entry.id)))
				_text(str(entry.get("description",entry.get("text",entry.get("concept","Catatan pengamatan tersimpan di jurnal.")))))
	for entry in GameState.world.get("forest",{}).get("landmarks",[]):
		if discoveries.has(str(entry.get("id",""))):
			found=true
			_text(str(entry.get("name",entry.id)))
			_text(str(entry.get("description",entry.get("text","Pengamatan daratan tersimpan."))))
	if not found: _text("Belum ada catatan yang dibuka. Amati benda dan lingkungan saat menjelajah untuk menambah arsip.")

func _inventory() -> void:
	_page("Bekal Nala")
	for item in GameState.player.get("inventory",[]):
		_text("%s · %d bintang · %d buah" % [GameState.fragment_name(str(item.fragmentId)),int(item.stars),int(item.quantity)])
	for crop in _crops():
		_text("%s · Bibit %d · Panen %d · Kedai %d" % [crop.name,_quantity("seeds",str(crop.seedId)),_quantity("produce",str(crop.id)),_quantity("pantry",str(crop.id))])
	if not GameState.homestead_definitions.get("fishPen",{}).is_empty():
		_text("Ikan seruni hidup untuk indukan: %d · Hasil budidaya %d · Kedai %d" % [_quantity("liveCatch","reef_seruni"),_quantity("produce","ikan_seruni"),_quantity("pantry","ikan_seruni")])
	if GameState.player.get("inventory",[]).is_empty(): _text("Belum ada fragmen yang dibawa pulang.")

func _chest() -> void:
	_page("Peti Rumah · Fragmen Tersimpan")
	_text("Pindahkan satu buah per tindakan. Benda penting cerita tetap bersama Nala.")
	for item in GameState.player.get("inventory",[]):
		if int(item.quantity)<=0: continue
		var value: Dictionary=item.duplicate()
		_text("Di tas: %s · %d bintang · %d buah" % [GameState.fragment_name(str(value.fragmentId)),int(value.stars),int(value.quantity)])
		_button("Simpan satu ke peti",func(): _perform("deposit",{"itemId":value.fragmentId,"stars":int(value.stars),"qty":1}))
	for item in GameState.homestead.get("storageLoot",[]):
		var value: Dictionary=item.duplicate()
		_text("Di peti: %s · %d bintang · %d buah" % [GameState.fragment_name(str(value.fragmentId)),int(value.stars),int(value.quantity)])
		_button("Ambil satu dari peti",func(): _perform("withdraw",{"itemId":value.fragmentId,"stars":int(value.stars),"qty":1}))
	if GameState.player.get("inventory",[]).is_empty() and GameState.homestead.get("storageLoot",[]).is_empty(): _text("Peti dan tas masih kosong. Fragmen hasil penjelajahan dapat disimpan setelah Nala membawanya pulang.")

func _display() -> void:
	_page("Rak Pameran")
	var items: Array=GameState.adventure.get("keyItems",[])
	if items.is_empty(): _text("Rak masih kosong. Benda penting yang ditemukan Nala akan ditampilkan di sini.")
	for id in items: _text("Prasasti Smara Kuno" if str(id)=="prasasti_smara_kuno" else str(id))

func _quantity(group: String,item_id: String) -> int:
	return int(GameState.homestead.get(group,{}).get(item_id,0))

func _crops() -> Array:
	var definitions:=GameState.homestead_definitions
	if definitions.has("crops"): return definitions.crops
	return [definitions.crop] if definitions.has("crop") else []

func _servings() -> Dictionary:
	return GameState.homestead_definitions.get("servings",{"kangkung":{"itemId":"kangkung","name":"Kangkung kebun"}})

func _plot(plot_id: String) -> void:
	_page("Rakit Kebun · Petak "+plot_id.trim_prefix("plot_"))
	if not GameState.homestead.get("permit",false):
		_text("Kebun pribadi memerlukan izin Lurah setelah Nala membantu Bu Darmi. Periksa papan balai untuk melihat syaratnya.")
		return
	var plot: Dictionary={}
	for value in GameState.homestead.get("plots",[]):
		if str(value.id)==plot_id: plot=value
	if plot.is_empty():
		_text("Petak belum dapat dimuat. Tutup panel dan coba lagi setelah tersambung.")
		return
	if str(plot.get("stage","empty"))=="empty":
		_text("Petak kosong. Pilih bibit yang dibawa Nala.")
		var available:=false
		for crop in _crops():
			var seed_id:=str(crop.seedId)
			var count:=_quantity("seeds",seed_id)
			_text("%s · %d bibit · Tumbuh %d hari kalender dengan perawatan." % [crop.name,count,int(crop.growthDays)])
			if count>0:
				available=true
				_button("Tanam "+str(crop.name),func(): _perform("plant",{"plotId":plot_id,"itemId":seed_id}))
		if not available: _text("Bibit dapat dibeli di pasar Mbok Ratih.")
	else:
		var crop_name:="Tanaman kebun"
		for crop in _crops():
			if str(crop.id)==str(plot.get("cropId","")): crop_name=str(crop.name)
		var stage:=str({"seed":"Bibit","sprout":"Tunas","young":"Tanaman muda","ready":"Siap panen"}.get(str(plot.get("stage","")),str(plot.get("stage","Tumbuh"))))
		_text("%s · %s · Pertumbuhan %d hari." % [crop_name,stage,int(plot.get("growthDays",0))])
		_text("Kebutuhan air hari ini terpenuhi." if plot.get("watered",false) else "Petak perlu disiram agar pertumbuhan berikutnya tidak tertunda.")
		if plot.get("ready",false): _button("Panen "+crop_name,func(): _perform("harvest",{"plotId":plot_id}))
		elif not plot.get("watered",false): _button("Siram petak",func(): _perform("water",{"plotId":plot_id}))
	_text("Hasil panen melengkapi racikan Kedai Waras. Fragmen pengetahuan untuk resep cerita tetap diperlukan.")

func _market() -> void:
	_page("Pasar Tambakbaya · Bibit Ratih")
	_text("Koin Nala: %d." % int(GameState.player.get("coins",0)))
	var market: Dictionary=GameState.homestead_definitions.get("market",{})
	var bought:=int(GameState.homestead.get("market",{}).get("bought",0)) if int(GameState.homestead.get("market",{}).get("day",0))==int(GameState.calendar.get("calendarDay",1)) else 0
	var remaining:=maxi(0,int(market.get("dailyStock",0))-bought)
	_text("Sisa persediaan bibit bersama hari ini: %d. Bibit dipakai setelah memperoleh izin kebun Lurah." % remaining)
	for crop in _crops():
		var seed_id:=str(crop.seedId)
		var price:=int(crop.get("price",market.get("price",0)))
		_text("%s · %d koin · Dibawa %d bibit." % [crop.name,price,_quantity("seeds",seed_id)])
		var purchase:=_button("Beli satu bibit "+str(crop.name),func(): _perform("buy_seed",{"itemId":seed_id,"qty":1}))
		purchase.disabled=market.is_empty() or remaining<=0 or int(GameState.player.get("coins",0))<price

func _fish_pen() -> void:
	_page("Keramba Nala · Ikan Seruni")
	var definition:Dictionary=GameState.homestead_definitions.get("fishPen",{})
	var pen:Dictionary=GameState.homestead.get("fishPen",{})
	if definition.is_empty():
		_text("Data keramba belum tersambung. Coba kembali setelah desa selesai dimuat.")
		return
	if not pen.get("unlocked",false):
		_text("Keramba dibuka setelah izin kebun diperoleh dan cerita mencapai siklus %d." % int(definition.unlockStoryDay))
		return
	var parents:=int(definition.parentCount)
	var live:=_quantity("liveCatch",str(definition.speciesId))
	_text("Indukan %d/%d · Ikan hidup dibawa %d · Siap dipanen %d/%d." % [int(pen.get("breeders",0)),parents,live,int(pen.get("offspring",0)),int(definition.capacity)])
	if int(pen.get("breeders",0))<parents:
		_text("Bawa pulang %d ikan seruni hidup berkualitas tiga bintang dari penyelaman. Ikan yang belum berhasil diekstraksi belum dapat menjadi indukan." % parents)
		var stock:=_button("Masukkan %d ikan hidup sebagai indukan" % parents,func(): _perform("stock_pen",{"itemId":str(definition.speciesId),"qty":parents}))
		stock.disabled=live<parents
	else:
		_text("Pertumbuhan %d/%d hari pemberian pakan. Kapasitas anakan %d ikan." % [int(pen.get("progressDays",0)),int(definition.growthDays),int(definition.capacity)])
		var fed:=bool(pen.get("fed",false))
		var feed:=_button("Pakan hari ini sudah diberikan" if fed else "Beri pakan · %d koin" % int(definition.feedCost),func(): _perform("feed_pen"))
		feed.disabled=fed or int(GameState.player.get("coins",0))<int(definition.feedCost)
	if pen.get("ready",false): _button("Panen satu ikan budidaya",func(): _perform("harvest_pen",{"qty":1}))
	_text("Budidaya mengikuti pergantian hari kalender yang tersimpan. Hasilnya dapat dititipkan sebagai pelengkap di Kedai Waras.")

func _balai() -> void:
	_page("Balai Wirabhumi · Izin Kebun")
	if is_instance_valid(host) and host.has_method("service_resident"):
		var resident: Dictionary=host.service_resident("balai")
		if not resident.is_empty():
			_button("Bicara dengan Ki Lurah",func():
				if busy: return
				close()
				host._talk([{"name":resident.name,"text":resident.text}])
			)
	if GameState.homestead.get("permit",false):
		_text("Izin rakit kebun Griya Sasmita sudah tercatat. Rawat petak di samping rumah Nala dan bawa hasilnya ke Kedai Waras.")
	elif GameState.player.get("progress",{}).get("missions",[]).has("akar"):
		_text("Nala telah membantu Bu Darmi memulai perawatan kebunnya. Ki Lurah dapat membuka izin kebun warisan.")
		_button("Catat izin rakit kebun",func(): _perform("permit"))
	else:
		_text("Bantu Bu Darmi dalam misi Kebun Apung yang Sekarat untuk memperoleh izin. Misi tersedia mengikuti siklus cerita, bukan jumlah kali tidur.")
	if GameState.homestead.get("pendingStoryAdvance",false): _text("Pelayanan kedai telah selesai. Pulang ke Griya Sasmita dan tidur untuk melanjutkan pagi cerita.")

func _kedai_stock() -> void:
	_page("Kedai Waras · Bahan Kebun dan Keramba")
	_text("Titipkan hasil kebun atau budidaya untuk dipakai pada penyajian. Fragmen pengetahuan yang tepat tetap dibutuhkan.")
	for item in _servings().values():
		var item_id:=str(item.itemId)
		_text("%s · Dibawa %d · Stok kedai %d." % [item.name,_quantity("produce",item_id),_quantity("pantry",item_id)])
		if _quantity("produce",item_id)>0:
			_button("Titipkan satu "+str(item.name),func(): _perform("stock_kedai",{"itemId":item_id,"qty":1}))

func _sync_position() -> bool:
	if not inside or not is_instance_valid(host.player): return true
	if _position_busy: return false
	_position_busy=true
	var point: Vector2=host.player.position
	var route: Dictionary=_home_path.snapshot(point)
	var result: Dictionary=await ApiClient.call_api("/homestead/position",{"x":point.x,"y":point.y,"path":route.path})
	_position_busy=false
	if result.get("ok",false):
		_last_position=point
		_home_path.acknowledge(int(route.ticket))
		GameState.apply_result(result)
		return true
	if int(result.get("status",0))==409:
		var refreshed: Dictionary=await GameState.refresh()
		if refreshed.get("ok",false):
			if not GameState.homestead.get("inside",false):
				get_tree().change_scene_to_file("res://scenes/main.tscn")
				return false
			var saved: Dictionary=GameState.homestead.get("position",{})
			host.player.position=Vector2(float(saved.get("x",480)),float(saved.get("y",580)))
			_home_path.reset(host.player.position)
			_last_position=host.player.position
	if is_instance_valid(game_hud): game_hud.message(str(result.get("error","Posisi belum tersambung. Perjalanan akan dicoba kembali.")))
	return false

func _perform(action: String,extra: Dictionary={}) -> void:
	if busy: return
	busy=true
	_set_modal(true)
	var retrying:=not _pending.is_empty()
	if inside and not retrying:
		while _position_busy: await get_tree().process_frame
		if not await _sync_position():
			busy=false
			_page("Posisi belum tersimpan")
			_text("Koneksi ke rumah belum tersambung. Coba tindakan kembali setelah posisi dapat disimpan.")
			_button("Kembali",close)
			return
	elif not retrying and host.has_method("_sync_surface"):
		while host.syncing: await get_tree().process_frame
		if not await host._sync_surface():
			busy=false
			return
	var body: Dictionary={"action":action,"expectedRevision":int(GameState.homestead.get("revision",0))}
	body.merge(extra,true)
	if _pending.is_empty(): _pending={"body":body,"key":ApiClient._uuid()}
	_page("Menyimpan kegiatan…")
	_text("Menunggu konfirmasi server. Barang dan progres akan ditampilkan setelah tersimpan.")
	var result: Dictionary=await ApiClient.call_api("/homestead/action",_pending.body,HTTPClient.METHOD_POST,str(_pending.key))
	busy=false
	if not result.get("ok",false):
		var retryable:=int(result.get("status",0))==0 or int(result.get("status",0))>=500
		_page("Kegiatan belum selesai")
		_text(str(result.get("error","Koneksi terputus. Coba lagi.")))
		if retryable:
			_button("Coba kirim kegiatan yang sama",_retry_pending)
		else:
			_pending={}
			await GameState.refresh()
		_button("Kembali",close)
		return
	_pending={}
	GameState.apply_result(result)
	if host.has_method("set_state"): host.set_state(GameState.homestead)
	if action in ["enter","exit"]:
		close()
		get_tree().change_scene_to_file("res://scenes/homestead.tscn" if action=="enter" else "res://scenes/main.tscn")
		return
	if action=="sleep":
		var wake: Dictionary=GameState.homestead.get("position",{"x":480,"y":580})
		host.player.position=Vector2(float(wake.x),float(wake.y))
		host.player.velocity=Vector2.ZERO
		_home_path.reset(host.player.position)
		_last_position=host.player.position
		_page("Pagi di Griya Sasmita")
		_text("Hari %d · %s. Kegiatan dan pertumbuhan yang sah telah disimpan." % [int(GameState.calendar.get("calendarDay",1)),str(EnvironmentState.snapshot().clock)])
		_text("Siklus cerita %d. Keluar rumah untuk melihat keadaan desa dan kebun." % int(GameState.player.get("progress",{}).get("day",1)))
		_button("Bangun dan lanjutkan",close).grab_focus()
	else:
		open_for(_current_id)

func _retry_pending() -> void:
	if _pending.is_empty() or busy: return
	var body: Dictionary=_pending.body.duplicate(true)
	var action:=str(body.action)
	body.erase("action")
	body.erase("expectedRevision")
	_perform(action,body)
