class_name WorldAtlas
extends VBoxContainer
signal region_selected(id: String)
signal close_requested
const BODY = preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2")
const INK := Color("302d2a")
var _world: Dictionary = {}
var _player: Dictionary = {}
var _current_area := "hub"
var _map: GeoMap
var _info: Label
var _point := Vector2.ZERO
var _buttons: Array[Button] = []
var _info_scroll: ScrollContainer
var _title: Label
var _font_size := 24
var _target := 64.0
var _shown_area := "hub"
var _header: HBoxContainer
var _footer: HBoxContainer
var _zoom_buttons: Array[Button] = []

func configure(world: Dictionary,player: Dictionary,current_area: String) -> void:
	_world=world
	_player=player
	_current_area="sea" if current_area in ["sea","reef","kelp","cave","boss","Dangkalan Segaran","Hutan Lamun Wringin","Rongga Kapur Jalatunda","Pelataran Kuno Tamansari"] or not GameState.dive.is_empty() else "forest" if current_area in ["forest","forest_wringin"] else "hub"
	_shown_area=_current_area
	var source: Dictionary=GameState.dive.get("position",{}) if _current_area=="sea" else GameState.surface
	_point=Vector2(float(source.get("x",1120)),float(source.get("y",1230)))
	if is_inside_tree(): _build()

func set_player_position(point: Vector2) -> void:
	_point=point
	if is_instance_valid(_map):
		_map.player_point=_point if (_shown_area=="sea")==(_current_area=="sea") else Vector2(-100000,-100000)
		_map.queue_redraw()

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	size_flags_vertical=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	get_viewport().size_changed.connect(_layout)
	_build()

func close() -> void:
	close_requested.emit()

func _style(background: Color) -> StyleBoxFlat:
	var style:=StyleBoxFlat.new()
	style.bg_color=background
	style.border_color=Color("8a633d")
	style.set_border_width_all(2)
	style.content_margin_left=10
	style.content_margin_right=10
	style.content_margin_top=8
	style.content_margin_bottom=8
	return style

func _button(parent: Node,title: String,callback: Callable) -> Button:
	var button:=Button.new()
	button.text=title
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button.add_theme_font_override("font",BODY)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
		button.add_theme_color_override(state,INK)
	button.add_theme_stylebox_override("normal",_style(Color("ead7ac")))
	button.add_theme_stylebox_override("hover",_style(Color("f8ebcc")))
	button.add_theme_stylebox_override("pressed",_style(Color("d6bd8e")))
	var focus:=_style(Color.TRANSPARENT)
	focus.border_color=Color("80501f")
	focus.set_border_width_all(4)
	button.add_theme_stylebox_override("focus",focus)
	button.pressed.connect(callback)
	parent.add_child(button)
	_buttons.append(button)
	return button

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	_zoom_buttons.clear()
	var header:=HBoxContainer.new()
	_header=header
	header.add_theme_constant_override("separation",8)
	add_child(header)
	_title=Label.new()
	_title.text="Atlas Jalasmara"
	_title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_override("font",BODY)
	_title.add_theme_color_override("font_color",INK)
	header.add_child(_title)
	for sign in ["-","+"]:
		var button:=_button(header,sign,func():
			_map.zoom=clampf(_map.zoom*(1.25 if sign=="+" else 0.8),1,4)
			_map.queue_redraw()
		)
		button.size_flags_horizontal=Control.SIZE_SHRINK_END
		button.tooltip_text="Perkecil peta" if sign=="-" else "Perbesar peta"
		_zoom_buttons.append(button)
	_map=GeoMap.new()
	_map.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_map.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_map.custom_minimum_size.y=96
	_map.configure(_world,_shown_area,_point)
	_map.tooltip_text="Fokus peta: panah untuk geser, +/- untuk zoom, Page Up/Down memilih lokasi, Home untuk mereset."
	_map.place_selected.connect(_place_selected)
	add_child(_map)
	_info_scroll=ScrollContainer.new()
	_info_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	_info_scroll.follow_focus=true
	_info_scroll.focus_mode=Control.FOCUS_ALL
	add_child(_info_scroll)
	_info=Label.new()
	_info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_info.add_theme_font_override("font",BODY)
	_info.add_theme_color_override("font_color",INK)
	_info.text="Segitiga: posisi Anda. Pilih lokasi atau seret peta. Keyboard: fokus peta, panah untuk geser, Page Up/Down untuk lokasi, +/- untuk zoom."
	_info_scroll.add_child(_info)
	var footer:=HBoxContainer.new()
	_footer=footer
	footer.add_theme_constant_override("separation",8)
	add_child(footer)
	for item in [["Daratan","hub"],["Palung","sea"]]:
		var destination:=str(item[1])
		_button(footer,str(item[0]),func(): _change_section(destination))
	var close_button:=_button(footer,"Tutup",close)
	close_button.tooltip_text="Kembali ke permainan [M]"
	_layout()
	_focus_control.call_deferred(close_button)

func _focus_control(control: Control) -> void:
	if is_instance_valid(control) and control.is_inside_tree(): control.grab_focus()

func _layout() -> void:
	if not is_instance_valid(_info): return
	var logical:=get_viewport().get_visible_rect().size
	var physical:=Vector2(get_window().size)
	var ratio:=logical.x/maxf(1,physical.x)
	_font_size=maxi(24,ceili(16*ratio))
	var compact:=physical.x<900
	if OS.has_feature("web"): compact=compact or bool(JavaScriptBridge.get_interface("window").matchMedia("(pointer:coarse)").matches)
	_target=maxf(84 if compact else 56,ceilf(48*ratio))
	var short_landscape:=logical.y<700 and physical.x<1000
	_header.visible=not short_landscape
	for index in range(_zoom_buttons.size()):
		var button:=_zoom_buttons[index]
		var destination:Node=_footer if short_landscape else _header
		if button.get_parent()!=destination: button.reparent(destination,false)
		if short_landscape: _footer.move_child(button,2+index)
	_title.add_theme_font_size_override("font_size",_font_size+2)
	_info.add_theme_font_size_override("font_size",_font_size)
	_info_scroll.custom_minimum_size.y=ceilf(_font_size*3)
	for button in _buttons:
		button.custom_minimum_size.y=_target
		button.add_theme_font_size_override("font_size",_font_size)
		if button.text in ["-","+"]: button.custom_minimum_size.x=_target

func _place_selected(place: Dictionary) -> void:
	_info.text=str(place.get("name","Lokasi"))+("\n"+str(place.reason) if place.has("reason") else "")
	_info_scroll.scroll_vertical=0
	region_selected.emit(str(place.get("name","")))

func _change_section(destination: String) -> void:
	_map.zoom=1
	_map.pan=Vector2.ZERO
	_shown_area=_current_area if destination=="hub" and _current_area!="sea" else destination
	var actual_point:=_point if (destination=="sea")==(_current_area=="sea") else Vector2(-100000,-100000)
	_map.configure(_world,_shown_area,actual_point)
	_info.text="Daratan Bandar Hujung dan Hutan Pesisir Wringin." if destination=="hub" else "Penampang Palung Smara. Lokasi yang belum terbuka tetap mengikuti progres cerita."
	_info_scroll.scroll_vertical=0
