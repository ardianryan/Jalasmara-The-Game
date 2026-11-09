extends Control
signal close_requested

const HudArt = preload("res://scripts/HudSkin.gd")
const BODY = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const HEADING = preload("res://resources/fonts/ark-pixel-12px-proportional-latin.otf")
const Icons = preload("res://scripts/ItemIcons.gd")
const INK := Color("302d2a")
const PAPER := Color("f1e1bc")
const TABS := ["Biota", "Konsep", "Warga", "Misi"]
var _state: Dictionary = {}
var _tab := 0
var _selected := 0
var _detail_open := false
var _compact := false
var _font_size := 24
var _target := 64.0
var _panel: PanelContainer
var _pages: HBoxContainer
var _entries: Array = []

func configure(state: Dictionary = {}) -> void:
	_state = state.duplicate(true) if not state.is_empty() else {"player":GameState.player,"catalog":GameState.catalog,"world":GameState.world,"adventure":GameState.adventure,"dive":GameState.dive,"homestead":GameState.homestead}
	if is_inside_tree(): _rebuild()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(_rebuild)
	if _state.is_empty(): configure()
	else: _rebuild()
	AudioManager.play_sfx("page_turn",1.0,-20)
	if not EnvironmentState.reduced_motion:
		_panel.pivot_offset = _panel.size/2
		_panel.scale = Vector2(.96,.96)
		_panel.modulate.a = 0
		var opening := create_tween().set_parallel(true)
		opening.tween_property(_panel,"scale",Vector2.ONE,.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		opening.tween_property(_panel,"modulate:a",1.0,.16)

func close() -> void:
	close_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _style(_color: Color = PAPER) -> StyleBox:
	return HudArt.panel("paper")

func _label(parent: Node,text: String,heading := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font",HEADING if heading else BODY)
	label.add_theme_font_size_override("font_size",_font_size+3 if heading else _font_size)
	label.add_theme_color_override("font_color",INK)
	parent.add_child(label)
	return label

func _button(parent: Node,text: String,callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = _target
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_override("font",BODY)
	button.add_theme_font_size_override("font_size",_font_size)
	HudArt.apply_button(button)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var viewport := get_viewport().get_visible_rect().size
	var physical := Vector2(get_window().size)
	var ratio := viewport.x/maxf(1,physical.x)
	var touch := DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"): touch = bool(JavaScriptBridge.get_interface("window").matchMedia("(pointer:coarse)").matches)
	_compact = touch or physical.x<900 or viewport.x<850
	_font_size = maxi(24,ceili(16*ratio))
	_target = maxf(84 if _compact else 56,ceilf(48*ratio))
	var safe := Vector4.ZERO
	var layout := get_node_or_null("/root/ViewportLayout")
	if layout != null: safe = layout.insets()
	var dim := ColorRect.new()
	dim.color = Color(0.04,0.09,0.09,0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	var top := ceilf(60*ratio)+safe.y
	_panel.position = Vector2(18+safe.x,top)
	_panel.size = viewport-Vector2(36+safe.x+safe.z,top+18+safe.w)
	_panel.add_theme_stylebox_override("panel",_style())
	add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",10)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_label(header,"SmaraPedia",true)
	if _compact and _detail_open:
		var back := _button(header,"Daftar",func():
			_detail_open=false
			_rebuild()
		)
		back.size_flags_horizontal=Control.SIZE_SHRINK_END
		back.custom_minimum_size.x=120
	var close_button := _button(header,"Tutup",close)
	if not _compact: HudArt.set_icon(close_button,"close",28)
	close_button.custom_minimum_size.x = 120
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation",6)
	column.add_child(tabs)
	for i in range(TABS.size()):
		var index := i
		var button := _button(tabs,TABS[i],func():
			_tab=index
			_selected=0
			_detail_open=false
			_rebuild()
		)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		button.button_pressed = _tab==i
		if not _compact: HudArt.set_icon(button,["compass","journal","character","quest-scroll"][i],28)
		if _tab==i: button.add_theme_stylebox_override("normal",HudArt.button("selected"))
	_entries = entries_for(_state,TABS[_tab])
	_selected = clampi(_selected,0,maxi(0,_entries.size()-1))
	_pages = HBoxContainer.new()
	_pages.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages.add_theme_constant_override("separation",18)
	column.add_child(_pages)
	if not _compact or not _detail_open: _build_index()
	if not _compact or _detail_open: _build_detail()
	_label(column,("Hari %d · Catatan tersimpan" if _compact else "Hari %d · Catatan berasal dari penemuan dan progres tersimpan.") % int(_state.get("player",{}).get("progress",{}).get("day",1)))
	_focus_control.call_deferred(close_button)

func _focus_control(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()

func _scroll(parent: Node) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",12)
	scroll.add_child(box)
	return box

func _build_index() -> void:
	var box := _scroll(_pages)
	if not _compact:
		box.get_parent().custom_minimum_size.x = 290
		box.get_parent().size_flags_horizontal = Control.SIZE_FILL
	if _entries.is_empty(): _label(box,"Belum ada catatan untuk bagian ini.")
	for i in range(_entries.size()):
		var index := i
		var item: Dictionary = _entries[i]
		var unlocked := bool(item.get("unlocked",false))
		var button := _button(box,str(item.title) if unlocked else "?  Belum ditemukan",func():
			_selected=index
			_detail_open=true
			_rebuild()
		)
		button.tooltip_text = str(item.title) if unlocked else "Amati dunia untuk membuka catatan ini."

func _build_detail() -> void:
	var box := _scroll(_pages)
	if _entries.is_empty(): return
	var item: Dictionary = _entries[_selected]
	var unlocked := bool(item.get("unlocked",false))
	if item.has("icon") and not _compact:
		var icon := TextureRect.new()
		icon.texture = Icons.texture(str(item.icon))
		icon.custom_minimum_size = Vector2(88,88)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.modulate = Color.WHITE if unlocked else Color("302d2a")
		box.add_child(icon)
	_label(box,str(item.title) if unlocked else "Catatan belum terbuka",true)
	if not _compact:
		_label(box,"TERCATAT" if unlocked else "BELUM DIAMATI")
		_label(box,str(item.get("subtitle","")) if unlocked else "Belum diamati")
	_label(box,str(item.get("text","")) if unlocked else "Jelajahi wilayah dan amati penemuan dengan tombol Aksi. Isi catatan muncul setelah penemuan tersimpan.")

static func entries_for(state: Dictionary,tab: String) -> Array:
	var output: Array = []
	var world: Dictionary = state.get("world",{})
	var player: Dictionary = state.get("player",{})
	var catalog: Dictionary = state.get("catalog",{})
	var discoveries: Array = state.get("adventure",{}).get("discoveries",[])
	var progress: Dictionary = player.get("progress",{})
	var missions: Array = progress.get("missions",[])
	if tab=="Biota":
		for item in world.get("landmarks",[]):
			if str(item.get("id","")) not in ["cell","nitrogen","photosynthesis","osmosis","food_web"]: continue
			output.append({"title":str(item.get("name",item.get("title","Temuan laut"))),"subtitle":"Biota dan habitat Palung Smara","text":str(item.get("text","")),"unlocked":discoveries.has(item.get("id","")),"icon":"ekosistem"})
	elif tab=="Konsep":
		for fragment in catalog.get("fragments",[]):
			var known := knows_fragment(state,str(fragment.id))
			output.append({"title":str(fragment.name),"subtitle":str(fragment.get("subject","Fragmen ilmu")),"text":str(fragment.get("description","")),"unlocked":known,"icon":str(fragment.id)})
		for group in [world.get("surface_hub",{}).get("landmarks",[]),world.get("forest",{}).get("landmarks",[]),world.get("landmarks",[])]:
			for item in group:
				output.append({"title":str(item.get("title",item.get("name","Penemuan"))),"subtitle":"Catatan pengamatan","text":str(item.get("text","")),"unlocked":discoveries.has(item.get("id",""))})
		for note in state.get("fieldNotes",[]):
			if note is Dictionary: output.append({"title":str(note.get("title","Catatan")),"text":str(note.get("text","")),"unlocked":true})
	elif tab=="Warga":
		for item in world.get("surface_hub",{}).get("districts",[]):
			output.append({"title":str(item.get("npc","Warga")),"subtitle":str(item.get("name","Bandar Hujung")),"text":"Temui di %s untuk berbicara dan membantu kehidupan desa." % str(item.get("name","Bandar Hujung")),"unlocked":true})
		for item in world.get("surface_hub",{}).get("residents",[]):
			output.append({"title":str(item.get("name","Warga")),"subtitle":str(item.get("title","Warga Bandar Hujung")),"text":str(item.get("line","")),"unlocked":int(progress.get("day",1))>=int(item.get("cycle",1))})
	elif tab=="Misi":
		output.append({"title":"Kebun Apung Bu Darmi","subtitle":"Perawatan dimulai" if missions.has("akar") and int(progress.get("day",1))<3 else "Pulih bertahap" if missions.has("akar") else "Menelusuri akar masalah","text":mission_text(state),"unlocked":true})
		output.append({"title":"Rumah dan kebun Nala","subtitle":"Griya Sasmita","text":"Izin berkebun: %s. Dua petak kebun mengikuti hari kalender tersimpan. Menutup Kedai menyiapkan kelanjutan cerita; tidur di rumah mengantarkan hari berikutnya." % ("sudah diperoleh" if state.get("homestead",{}).get("permit",false) else "belum diperoleh; bantu misi akar lalu temui balai"),"unlocked":true})
		for recipe in catalog.get("recipes",[]):
			output.append({"title":"%s · %s" % [str(recipe.get("customer","Warga")),str(recipe.get("id",""))],"subtitle":"Sudah dilayani" if missions.has(recipe.get("id","")) else "Belum dilayani","text":str(recipe.get("complaint",""))+("\n\n"+str(recipe.get("solution","")) if missions.has(recipe.get("id","")) else ""),"unlocked":int(recipe.get("day",1))<=int(progress.get("day",1))})
	return output

static func knows_fragment(state: Dictionary,id: String) -> bool:
	for items in [state.get("player",{}).get("inventory",[]),state.get("dive",{}).get("loot",[])]:
		for item in items:
			if str(item.get("fragmentId",""))==id and int(item.get("quantity",1))>0: return true
	var missions: Array = state.get("player",{}).get("progress",{}).get("missions",[])
	for recipe in state.get("catalog",{}).get("recipes",[]):
		if str(recipe.get("fragmentId",""))==id and missions.has(recipe.get("id","")): return true
	var observations := {"klorofil":["cell","garden_leaf","garden_root","photosynthesis"],"ekosistem":["forest_roots","food_web","nitrogen"],"netralisasi":["limestone","corporate_pipe"]}
	for observed in observations.get(id,[]):
		if state.get("adventure",{}).get("discoveries",[]).has(observed): return true
	return false

static func mission_text(state: Dictionary) -> String:
	var discoveries: Array = state.get("adventure",{}).get("discoveries",[])
	var counts: Array = []
	for group in [["garden_leaf","garden_root","garden_channel"],["forest_canopy","forest_roots","forest_stream"],["nitrogen","photosynthesis","osmosis"]]:
		var count := 0
		for id in group:
			if discoveries.has(id): count+=1
		counts.append(count)
	return "Gejala kebun apung: %d/3\nPembanding Hutan Pesisir Wringin: %d/3\nPengamatan Hutan Lamun Wringin: %d/3\nBenih Hayati di tas: %s\n\nMedia yang terus tergenang membuat akar kekurangan oksigen untuk respirasi. Air payau juga dapat mengganggu osmosis dan penyerapan hara. Bandingkan bukti darat dan laut sebelum meracik.\n\nHutan Pesisir Wringin berada di daratan. Hutan Lamun Wringin adalah zona laut 25–60 m. Lamun merupakan tumbuhan berbunga; kelp merupakan alga cokelat dalam ekosistem fantasi permainan." % [counts[0],counts[1],counts[2],"tersedia" if _has_inventory(state,"klorofil") else "belum ada; jala di laut"]

static func _has_inventory(state: Dictionary,id: String) -> bool:
	for item in state.get("player",{}).get("inventory",[]):
		if str(item.get("fragmentId",""))==id and int(item.get("quantity",0))>0: return true
	return false
