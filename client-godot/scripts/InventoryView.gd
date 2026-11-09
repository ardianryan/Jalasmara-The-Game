extends Control
signal close_requested

const HudArt = preload("res://scripts/HudSkin.gd")
const Icons = preload("res://scripts/ItemIcons.gd")
const BODY = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const INK := Color("302d2a")
const DETAIL := Color("62533f")
var _player: Dictionary = {}
var _dive: Dictionary = {}
var _items: Array = []
var _selected := 0
var _body_size := 24
var _target := 72.0
var _detail: VBoxContainer

func configure(player: Dictionary = {},dive: Variant = null) -> void:
	_player = player.duplicate(true) if not player.is_empty() else GameState.player.duplicate(true)
	_dive = GameState.dive.duplicate(true) if dive==null else dive.duplicate(true)
	if is_inside_tree(): _build()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	get_viewport().size_changed.connect(_build)
	if _player.is_empty(): configure(GameState.player,GameState.dive)
	else: _build()

func close() -> void:
	close_requested.emit()

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _paper(_background := Color("f1e1bc")) -> StyleBox:
	return HudArt.panel("paper")

func _text(parent: Node,value: String,heading := false) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_override("font",BODY)
	label.add_theme_font_size_override("font_size",_body_size+3 if heading else _body_size)
	label.add_theme_color_override("font_color",INK)
	parent.add_child(label)
	return label

func _button_style(button: Button) -> void:
	button.add_theme_font_override("font",BODY)
	button.add_theme_font_size_override("font_size",_body_size)
	HudArt.apply_button(button)

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var viewport := get_viewport().get_visible_rect().size
	var ratio := viewport.x/maxf(1,Vector2(get_window().size).x)
	var touch := DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"): touch = bool(JavaScriptBridge.get_interface("window").matchMedia("(pointer:coarse)").matches)
	_body_size = maxi(24,ceili(16*ratio))
	_target = maxf(84 if touch or get_window().size.x<900 else 64,ceilf(48*ratio))
	var safe := Vector4.ZERO
	var layout := get_node_or_null("/root/ViewportLayout")
	if layout != null: safe = layout.insets()
	var shade := ColorRect.new()
	shade.color = Color(0.04,0.09,0.09,0.72)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	var top := ceilf(60*ratio)+safe.y
	panel.position = Vector2(18+safe.x,top)
	panel.size = viewport-Vector2(36+safe.x+safe.z,top+18+safe.w)
	panel.add_theme_stylebox_override("panel",_paper())
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	_text(header,"Tas Nala · %d koin" % int(_player.get("coins",0)),true)
	var close_button := Button.new()
	close_button.text = "Tutup"
	close_button.custom_minimum_size = Vector2(160,_target)
	_button_style(close_button)
	HudArt.set_icon(close_button,"close",28)
	close_button.pressed.connect(close)
	header.add_child(close_button)
	var summary := "Fragmen yang sudah dibawa pulang tersimpan permanen."
	if not _dive.is_empty(): summary = "Jala sementara: %.1f / %.1f kg. Naik melalui tangga untuk menyimpan tangkapan." % [float(_dive.get("weight",0)),float(_dive.get("capacity",0))]
	_text(column,summary)
	_items = []
	for item in _player.get("inventory",[]):
		if int(item.get("quantity",0))>0:
			var row: Dictionary = item.duplicate(true)
			row["temporary"] = false
			_items.append(row)
	for item in _dive.get("loot",[]):
		var row: Dictionary = item.duplicate(true)
		row["temporary"] = true
		_items.append(row)
	_selected = clampi(_selected,0,maxi(0,_items.size()-1))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",14)
	scroll.add_child(content)
	var grid := GridContainer.new()
	grid.columns = maxi(2,floori((panel.size.x-44)/maxf(150,_target+44)))
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	content.add_child(grid)
	for i in range(_items.size()):
		var index := i
		var item: Dictionary = _items[i]
		var button := Button.new()
		button.text = "x%d · %d*" % [int(item.get("quantity",1)),int(item.get("stars",1))]
		button.icon = Icons.texture(str(item.get("fragmentId","")))
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width",54)
		button.custom_minimum_size = Vector2(maxf(150,_target+44),_target)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = GameState.fragment_name(str(item.get("fragmentId","")))
		_button_style(button)
		button.add_theme_stylebox_override("normal",HudArt.slot())
		button.pressed.connect(func():
			_selected=index
			_show_detail()
		)
		button.focus_entered.connect(func():
			_selected=index
			_show_detail()
		)
		grid.add_child(button)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation",10)
	content.add_child(_detail)
	_show_detail()
	_focus_control.call_deferred(close_button)

func _focus_control(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()

func _show_detail() -> void:
	for child in _detail.get_children():
		_detail.remove_child(child)
		child.queue_free()
	if _items.is_empty():
		_text(_detail,"Tas masih kosong. Amati dunia dan jala fragmen ilmu di bawah laut.")
		return
	var item: Dictionary = _items[_selected]
	var id := str(item.get("fragmentId",""))
	_text(_detail,GameState.fragment_name(id),true)
	_text(_detail,"%d bintang · %d buah · %s" % [int(item.get("stars",1)),int(item.get("quantity",1)),"di dalam jala; belum tersimpan" if item.get("temporary",false) else "sudah tersimpan"])
	for fragment in GameState.catalog.get("fragments",[]):
		if str(fragment.id)==id:
			_text(_detail,str(fragment.get("description","")))
			_text(_detail,"Berat satu fragmen: %.1f kg. Digunakan saat meracik di Kedai Waras." % float(fragment.get("weight",0)))
			break

static func add_rows(parent: VBoxContainer,inventory: Array) -> Array[HBoxContainer]:
	var rows: Array[HBoxContainer] = []
	for item in inventory:
		var id := str(item.get("fragmentId",""))
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.custom_minimum_size.y = 84
		row.add_theme_constant_override("separation",14)
		parent.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Icons.texture(id)
		icon.custom_minimum_size = Vector2(64,64)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation",5)
		row.add_child(text)
		for value in [GameState.fragment_name(id),"Kualitas: %d bintang · Jumlah: %d" % [int(item.get("stars",1)),int(item.get("quantity",0))]]:
			var label := Label.new()
			label.text = value
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.add_theme_font_override("font",BODY)
			label.add_theme_font_size_override("font_size",24)
			label.add_theme_color_override("font_color",INK)
			text.add_child(label)
		rows.append(row)
	return rows
