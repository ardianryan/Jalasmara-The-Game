class_name GameHud
extends CanvasLayer

signal interact_requested
signal net_pressed
signal net_released
signal map_requested
signal journal_requested
signal inventory_requested
signal character_requested
signal move_changed(direction: Vector2)
signal objective_requested(text: String)

const INK := Color("202d3a")
const CREAM := Color("f1e1bc")
const WOOD := Color("654733")
const COPPER := Color("af8759")
const LAMUN := Color("6faba2")

class Plate extends Panel:
	var paper := false
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var outline := PackedVector2Array([Vector2(3,0),Vector2(w-3,0),Vector2(w-3,3),Vector2(w,3),Vector2(w,h-3),Vector2(w-3,h-3),Vector2(w-3,h),Vector2(3,h),Vector2(3,h-3),Vector2(0,h-3),Vector2(0,3),Vector2(3,3)])
		draw_colored_polygon(outline,Color("654733"))
		draw_rect(Rect2(2,2,w-4,h-5),Color("f1e1bc") if paper else Color(0.21,0.14,0.10,0.94))
		draw_line(Vector2(4,2),Vector2(w-4,2),Color("af8759"),1)
		for x in range(8,int(w)-7,12):
			draw_rect(Rect2(x,h-3,3,1),Color("af8759"))

class HudIcon extends Control:
	var kind := "map"
	var ink := Color("f1e1bc")
	func _draw() -> void:
		draw_set_transform(size/2,0,Vector2.ONE*minf(size.x,size.y)/26.0)
		match kind:
			"map":
				draw_polyline(PackedVector2Array([Vector2(-10,-8),Vector2(-3,-10),Vector2(4,-7),Vector2(10,-9),Vector2(10,8),Vector2(4,10),Vector2(-3,7),Vector2(-10,9),Vector2(-10,-8)]),ink,1.8)
				draw_line(Vector2(-3,-9),Vector2(-3,7),ink,1.2)
				draw_line(Vector2(4,-7),Vector2(4,9),ink,1.2)
			"journal":
				draw_rect(Rect2(-8,-10,16,20),ink,false,1.8)
				draw_line(Vector2(-4,-10),Vector2(-4,10),ink,1.2)
				for y in [-4,0,4]: draw_line(Vector2(-1,y),Vector2(5,y),ink,1.2)
			"bag":
				draw_rect(Rect2(-8,-5,16,15),ink,false,1.8)
				draw_arc(Vector2(0,-5),5,PI,TAU,12,ink,1.8)
				draw_line(Vector2(-8,0),Vector2(8,0),ink,1.2)
				draw_rect(Rect2(-2,-1,4,4),ink,false,1.2)
			"character":
				draw_circle(Vector2(0,-5),4,ink,false,1.8)
				draw_arc(Vector2(0,7),8,PI,TAU,14,ink,1.8)
				draw_line(Vector2(-8,7),Vector2(8,7),ink,1.8)
			"net":
				draw_circle(Vector2(-2,-3),8,ink,false,1.8)
				draw_line(Vector2(3,3),Vector2(10,11),ink,2.4)
				for x in [-6,-2,2]: draw_line(Vector2(x,-9),Vector2(x,3),ink,0.8)
				for y in [-6,-2,2]: draw_line(Vector2(-8,y),Vector2(4,y),ink,0.8)
			"action":
				draw_circle(Vector2.ZERO,8,ink,false,1.8)
				draw_line(Vector2(-4,0),Vector2(4,0),ink,1.8)
				draw_line(Vector2(0,-4),Vector2(0,4),ink,1.8)
		draw_set_transform(Vector2.ZERO)

class DiveInstrument extends Control:
	var ratio := 1.0
	var phase := 0.0
	var reduced_motion := false
	var loss_feedback := 0.0
	func _draw() -> void:
		var edge := Color("af8759")
		var fill := Color("6faba2")
		if ratio<=0.35:
			edge = Color("e6bd76")
			fill = Color("e6bd76")
		if ratio<=0.15:
			edge = Color("f0a080")
			fill = Color("f0a080")
		var shape := PackedVector2Array([Vector2(8,0),Vector2(size.x-8,0),Vector2(size.x,8),Vector2(size.x,size.y-8),Vector2(size.x-8,size.y),Vector2(8,size.y),Vector2(0,size.y-8),Vector2(0,8)])
		draw_colored_polygon(shape,Color("202d3a"))
		draw_polyline(PackedVector2Array([Vector2(8,1),Vector2(size.x-8,1),Vector2(size.x-1,8),Vector2(size.x-1,size.y-8),Vector2(size.x-8,size.y-1),Vector2(8,size.y-1),Vector2(1,size.y-8),Vector2(1,8),Vector2(8,1)]),edge,2)
		# The segmented cylinder remains readable without relying on its colour.
		draw_rect(Rect2(12,20,26,60),edge,false,2)
		draw_rect(Rect2(19,13,12,7),edge)
		draw_line(Vector2(18,10),Vector2(31,10),edge,2)
		for index in range(10):
			var lit := ratio>float(index)/10.0
			draw_rect(Rect2(16,73-index*5,18,3),fill if lit else Color("3d5055"))
		draw_line(Vector2(150,14),Vector2(150,size.y-14),Color("654733"),1)
		if ratio<=0.15:
			var alpha := 0.18 if reduced_motion else 0.18+0.035*sin(phase*2)
			draw_rect(Rect2(3,3,size.x-6,size.y-6),Color(0.94,0.63,0.5,alpha),false,2)
		if loss_feedback>0.0:
			draw_line(Vector2(49,65),Vector2(138,65),Color(1.0,0.81,0.67,minf(1.0,loss_feedback*2)),2)

var _sound_button: Button
var _navigation: GeoMap
var root_control: Control
var status_label: Label
var touch_enabled := false
var _region: Label
var _depth: Label
var _resources: Label
var _weather: Label
var _oxygen_text: Label
var _oxygen_max: Label
var _oxygen_loss: Label
var _previous_oxygen := -1.0
var _previous_maximum := -1.0
var _was_diving := false
var _loss_seconds := 0.0
var _warning: Label
var _bag: Label
var _objective: Label
var _instrument: DiveInstrument
var _status_panel: Panel
var _action: Button
var _action_label: Label
var _net: Button
var _net_title: Label
var _net_charge: ColorRect
var _deck: Panel
var _dpad: Control
var _utility_plate: Panel
var _identity_plate: Panel
var _objective_toggle: Button
var _utilities: Array[Button] = []
var _modal := false
var _net_held := false
var _can_interact := false
var _can_net := false
var _held_seconds := 0.0
var _message_until := 0.0
var _state: Dictionary = {}
var _weather_plate: Panel
var _action_plate: Panel
var _warning_plate: Panel
var _oxygen_caption: Label
var _depth_caption: Label
var _action_title: Label
var _net_hint: Label

func _ready() -> void:
	layer = 10
	touch_enabled = touch_enabled or DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		touch_enabled = bool(JavaScriptBridge.get_interface("window").matchMedia("(pointer:coarse)").matches)
	root_control = Control.new()
	root_control.name = "GameHudControls"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.theme = _theme()
	_build_identity()
	_build_instrument()
	_build_utilities()
	_build_actions()
	_build_dpad()
	ViewportLayout.host_pause_changed.connect(func(paused: bool):
		if paused:
			_dpad.release()
			_release_net()
	)
	get_viewport().size_changed.connect(func():
		_dpad.release()
		_release_net()
		_layout()
	)
	_status_panel = _panel(Rect2(320,118,320,45),false)
	status_label = _label(_status_panel,"",Vector2(10,8),Vector2(300,30),12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_panel.hide()
	_layout()
	update_state(_state)
	_layout.call_deferred()

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = preload("res://resources/fonts/ark-pixel-12px-proportional-latin.otf")
	theme.default_font_size = 12
	theme.set_color("font_color","Label",CREAM)
	for kind in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = INK if kind=="normal" else WOOD
		style.set_border_width_all(1)
		style.border_color = COPPER
		style.border_width_bottom = 3
		if kind=="disabled":
			style.bg_color = Color("28343b")
			style.border_color = Color("59615b")
		if kind=="focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = CREAM
		theme.set_stylebox(kind,"Button",style)
	for state in ["font_color","font_hover_color","font_pressed_color"]:
		theme.set_color(state,"Button",CREAM)
	theme.set_color("font_disabled_color","Button",Color("87928d"))
	return theme

func _panel(rect: Rect2,paper: bool) -> Panel:
	var panel := Plate.new()
	panel.paper = paper
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	root_control.add_child(panel)
	return panel

func _label(parent: Node,text: String,at: Vector2,dimensions: Vector2,font_size := 12) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_outline_color",INK)
	label.add_theme_constant_override("outline_size",2)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	parent.add_child(label)
	label.set_deferred("size",dimensions)
	return label

func _button(text: String,rect: Rect2,callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.text = text
	button.clip_text = true
	if callback.is_valid(): button.pressed.connect(callback)
	root_control.add_child(button)
	return button

func _icon(parent: Node,kind: String,at: Vector2,dimensions: Vector2) -> void:
	var icon := HudIcon.new()
	icon.kind = kind
	icon.position = at
	icon.size = dimensions
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(icon)

func _build_identity() -> void:
	_identity_plate = _panel(Rect2(12,10,340,94),false)
	_region = _label(root_control,"Bandar Hujung",Vector2(18,12),Vector2(310,23),18 if touch_enabled else 16)
	_resources = _label(root_control,"",Vector2(18,38),Vector2(300,22),14 if touch_enabled else 12)
	_resources.add_theme_color_override("font_color",CREAM)
	_objective = _label(root_control,"",Vector2(18,67),Vector2(312,28),13 if touch_enabled else 12)
	_objective.tooltip_text = "Tujuan perjalanan"
	_objective.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective.clip_text = false
	_objective.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_objective_toggle = _button("",Rect2(18,67,312,60),func():
		if not _modal and not _objective.text.is_empty(): objective_requested.emit(_objective.text)
	)
	_objective_toggle.flat = true
	_objective_toggle.focus_mode=Control.FOCUS_ALL
	_objective_toggle.text = "+"
	_objective_toggle.add_theme_font_size_override("font_size",22)
	_objective_toggle.tooltip_text = "Baca tujuan perjalanan lengkap"
	_objective_toggle.move_to_front()
	root_control.move_child(_objective,root_control.get_child_count()-1)
	_weather_plate = _panel(Rect2(705,77,220,30),false)
	_weather = _label(root_control,"",Vector2(705,77) if touch_enabled else Vector2(723,68),Vector2(220,22),13 if touch_enabled else 11)
	_weather.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _build_instrument() -> void:
	_instrument = DiveInstrument.new()
	_instrument.position = Vector2(16,104) if touch_enabled else Vector2(16,420)
	_instrument.size = Vector2(296,140)
	_instrument.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(_instrument)
	_oxygen_caption = _label(_instrument,"OKSIGEN",Vector2(49,8),Vector2(96,28),20)
	_oxygen_text = _label(_instrument,"100",Vector2(47,27),Vector2(98,38),32)
	_oxygen_max = _label(_instrument,"/ 100 O2",Vector2(50,80),Vector2(93,26),18)
	_oxygen_loss = _label(_instrument,"",Vector2(99,10),Vector2(47,18),10)
	_oxygen_loss.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_oxygen_loss.add_theme_color_override("font_color",Color("ffd0aa"))
	_oxygen_loss.hide()
	_depth_caption = _label(_instrument,"KEDALAMAN",Vector2(164,8),Vector2(119,28),20)
	_depth = _label(_instrument,"0 m",Vector2(162,28),Vector2(120,28),24)
	_bag = _label(_instrument,"",Vector2(164,65),Vector2(120,48),18)
	_warning_plate = _panel(Rect2(16,220,296,32),false)
	_warning = _label(root_control,"UDARA TIPIS · NAIK",_instrument.position-Vector2(0,26),Vector2(296,23),13)
	if touch_enabled: _warning.position.y = 214
	_warning.add_theme_color_override("font_color",Color("ffd0aa"))

func _build_utilities() -> void:
	var cell := 64.0 if touch_enabled else 42.0
	var start := 620.0 if touch_enabled else 734.0
	_utility_plate = _panel(Rect2(start-4,10,cell*5+8,cell+8),false)
	var index := 0
	for item in [["map","Peta","M",func():map_requested.emit()],["journal","Jurnal","J",func():journal_requested.emit()],["bag","Tas","I",func():inventory_requested.emit()],["character","Tampilan","C",func():character_requested.emit()]]:
		var button := _button("",Rect2(start+index*cell,14,cell,cell),item[3])
		_icon(button,item[0],Vector2((cell-25)/2,5),Vector2(25,25))
		var key := _label(button,str(item[2]),Vector2(0,cell-15),Vector2(cell,12),9)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = str(item[1])+" ["+str(item[2])+"]"
		_utilities.append(button)
		key.visible = not touch_enabled
		index += 1
	_sound_button = _button("",Rect2(start+cell*4,14,cell,cell),func():AudioManager.toggle_mute())
	_sound_button.add_theme_font_size_override("font_size",18 if touch_enabled else 12)
	var refresh: Callable = func(_muted: bool):
		_sound_button.text = "Sunyi" if AudioManager.muted else "Suara"
		_sound_button.tooltip_text = "Suara nonaktif [V]" if AudioManager.muted else "Suara aktif [V]"
	AudioManager.mute_changed.connect(refresh)
	refresh.call(AudioManager.muted)

func _build_actions() -> void:
	_deck = _panel(Rect2(766,432,180,94) if touch_enabled else Rect2(784,448,162,78),false)
	_action_plate = _panel(Rect2(632,402,310,40),false)
	_action_label = _label(root_control,"",Vector2(632,402) if touch_enabled else Vector2(622,418),Vector2(310,27),15 if touch_enabled else 12)
	_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var net_rect := Rect2(774,438,80,80) if touch_enabled else Rect2(792,454,70,66)
	var action_rect := Rect2(862,438,80,80) if touch_enabled else Rect2(870,454,70,66)
	_net = _button("",net_rect,Callable())
	_icon(_net,"net",Vector2((net_rect.size.x-34)/2,6) if touch_enabled else Vector2(22,5),Vector2(34,34) if touch_enabled else Vector2(26,26))
	_net_title = _label(_net,"JALA",Vector2(0,40 if touch_enabled else 35),Vector2(net_rect.size.x,28 if touch_enabled else 14),22 if touch_enabled else 12)
	_net_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint := _label(_net,"TAHAN" if touch_enabled else "SPASI",Vector2(0,net_rect.size.y-18),Vector2(net_rect.size.x,20),14 if touch_enabled else 10)
	_net_hint=hint
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_net.tooltip_text = "Tahan untuk membentangkan jala; lepas untuk menangkap [Spasi]"
	_net_charge = ColorRect.new()
	_net_charge.position = Vector2(4,net_rect.size.y-4)
	_net_charge.size = Vector2(0,2)
	_net_charge.color = LAMUN
	_net_charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_net.add_child(_net_charge)
	_net.button_down.connect(func():
		if not _modal and _can_net:
			_net_held = true
			_held_seconds = 0.0
			net_pressed.emit()
	)
	_net.button_up.connect(_release_net)
	_action = _button("",action_rect,func():interact_requested.emit())
	_icon(_action,"action",Vector2((action_rect.size.x-34)/2,6) if touch_enabled else Vector2(22,5),Vector2(34,34) if touch_enabled else Vector2(26,26))
	var action_text := _label(_action,"AKSI",Vector2(0,40 if touch_enabled else 35),Vector2(action_rect.size.x,28 if touch_enabled else 14),22 if touch_enabled else 12)
	_action_title=action_text
	action_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var action_key := _label(_action,"SENTUH" if touch_enabled else "E",Vector2(0,action_rect.size.y-16),Vector2(action_rect.size.x,13),8)
	action_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_key.visible = not touch_enabled
	_action.tooltip_text = "Berinteraksi [E]"

func _build_dpad() -> void:
	_dpad = preload("res://scripts/AnalogJoystick.gd").new()
	_dpad.size = Vector2(176,176)
	root_control.add_child(_dpad)
	_dpad.direction_changed.connect(func(value: Vector2):
		move_changed.emit(value if not _modal else Vector2.ZERO)
	)
	_dpad.visible = touch_enabled

func _layout() -> void:
	if not is_instance_valid(_deck): return
	var viewport := get_viewport().get_visible_rect().size
	var ratio := viewport.x/maxf(1,Vector2(get_window().size).x)
	var body := maxi(24 if touch_enabled else 18,ceili(16*ratio))
	var line := ceilf(body*1.5)
	var inset := ViewportLayout.insets()
	var portrait := viewport.x<800
	var compact_dive := touch_enabled and bool(_state.get("diving",false))
	var margin := Vector2(16+inset.x,16+inset.y+(ceilf(60*ratio) if portrait else 0))
	var right := viewport.x-16-inset.z
	var bottom := viewport.y-16-inset.w
	var cell := maxf(48,ceilf(48*ratio))
	var identity_height := cell+12 if compact_dive else line*4+12
	var utilities_y := margin.y+identity_height+8 if portrait else margin.y
	_utility_plate.position=Vector2(right-cell*5-4,utilities_y-4)
	_utility_plate.size=Vector2(cell*5+8,cell+8)
	var controls:Array=_utilities+[_sound_button]
	for index in range(controls.size()):
		var button:Button=controls[index]
		button.position=Vector2(right-cell*(5-index),utilities_y)
		button.size=Vector2(cell,cell)
		for child in button.get_children():
			if child is HudIcon:
				child.position=Vector2.ONE*(cell-32)/2
				child.size=Vector2(32,32)
	_sound_button.add_theme_font_size_override("font_size",body)
	_sound_button.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	_sound_button.text="Sunyi" if AudioManager.muted else "Suara"
	var width:=minf(410,viewport.x-margin.x-24) if portrait else minf(370,viewport.x-cell*5-48)
	_identity_plate.position=margin-Vector2(6,6)
	_identity_plate.size=Vector2(width+12,identity_height)
	_region.position=margin
	_region.size=Vector2(width-cell-8 if compact_dive else width,line)
	_region.add_theme_font_size_override("font_size",body+2)
	_resources.position=margin+Vector2(0,line)
	_resources.size=Vector2(width,line)
	_resources.add_theme_font_size_override("font_size",body)
	_resources.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	_resources.visible=not compact_dive and not _modal
	_objective.position=margin+Vector2(0,line*2)
	_objective.size=Vector2(width-cell-8,line*2)
	_objective.max_lines_visible=2
	_objective.add_theme_font_size_override("font_size",body)
	_objective.visible=not compact_dive and not _modal
	_objective_toggle.position=margin+Vector2(width-cell,0 if compact_dive else line*2)
	_objective_toggle.size=Vector2(cell,cell)
	_objective_toggle.text="+"
	_objective_toggle.disabled=_modal
	_objective_toggle.visible=not _modal
	_weather.position=Vector2(right-350,utilities_y+cell+12)
	_weather.size=Vector2(350,line)
	_weather.add_theme_font_size_override("font_size",body)
	_weather.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	_weather_plate.position=_weather.position-Vector2(6,3)
	_weather_plate.size=_weather.size+Vector2(12,6)
	_weather_plate.visible=not _weather.text.is_empty()
	_dpad.position=Vector2(margin.x,bottom-_dpad.size.y)
	var action_side:=maxf(88 if touch_enabled else 76,ceilf(48*ratio))
	var action_size:=Vector2.ONE*action_side
	_action.size=action_size
	_net.size=action_size
	if touch_enabled:
		_net_hint.hide()
		for label in [_net_title,_action_title]:
			label.position=Vector2(0,42)
			label.size=Vector2(action_side,42)
			label.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
			label.add_theme_font_size_override("font_size",body)
	_action.position=Vector2(right-action_side,bottom-action_side)
	_net.position=Vector2(right-action_side*(2 if _can_interact else 1)-(10 if _can_interact else 0),bottom-action_side)
	_deck.position=Vector2(_net.position.x-6,bottom-action_side-6) if _net.visible else _action.position-Vector2(6,6)
	_deck.size=Vector2(right-_deck.position.x+6,action_side+12)
	_action_label.position=Vector2(right-minf(380,viewport.x-32),bottom-action_side-line*2-12)
	_action_label.size=Vector2(minf(380,viewport.x-32),line*2)
	_action_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_action_label.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	_action_label.add_theme_font_size_override("font_size",body)
	var action_height:=clampf(_action_label.get_theme_font("font").get_multiline_string_size(_action_label.text,HORIZONTAL_ALIGNMENT_RIGHT,_action_label.size.x,body).y+4,line,line*2)
	_action_label.size.y=action_height
	_action_label.position.y=bottom-action_side-action_height-12
	_action_plate.position=_action_label.position-Vector2(6,3)
	_action_plate.size=_action_label.size+Vector2(12,6)
	_action_plate.visible=_action_label.visible
	var instrument_scale:=1.25 if compact_dive else 1.4 if touch_enabled else 1.0
	var instrument_y:=margin.y+identity_height+12
	if portrait: instrument_y=_dpad.position.y-_instrument.size.y*instrument_scale-line-24
	_instrument.position=Vector2(margin.x,instrument_y)
	_instrument.scale=Vector2.ONE*instrument_scale
	_oxygen_text.position.y=40
	_oxygen_text.size.y=42
	_oxygen_max.position.y=110
	_oxygen_max.size.y=30
	_depth.position.y=40
	_depth.size.y=36
	_bag.position.y=80
	_bag.size.y=56
	_oxygen_loss.position=Vector2(49,82)
	_oxygen_loss.size=Vector2(96,28)
	for label in [_oxygen_caption,_depth_caption,_oxygen_max,_bag,_oxygen_loss]:
		label.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
		label.add_theme_font_size_override("font_size",maxi(20,ceili(16*ratio/instrument_scale)))
	var bag_width:=120.0
	for text_line in _bag.text.split("\n"):
		bag_width=maxf(bag_width,ceilf(_bag.get_theme_font("font").get_string_size(text_line,HORIZONTAL_ALIGNMENT_LEFT,-1,_bag.get_theme_font_size("font_size")).x)+4)
	_bag.size.x=bag_width
	_instrument.size.x=maxf(296,_bag.position.x+bag_width+12)
	_depth_caption.text="Kedalaman"
	_warning.position=_instrument.position+Vector2(0,_instrument.size.y*instrument_scale+6)
	_warning.size=Vector2(_instrument.size.x*instrument_scale,line)
	_warning.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	_warning.add_theme_font_size_override("font_size",body)
	_warning_plate.position=_warning.position-Vector2(6,3)
	_warning_plate.size=_warning.size+Vector2(12,6)
	_warning_plate.visible=_warning.visible
	if is_instance_valid(_navigation): _navigation.position=Vector2(viewport.x/2-64,bottom-94)
	_status_panel.position=Vector2(viewport.x/2-210,viewport.y/2-60)
	_status_panel.size=Vector2(420,120)
	status_label.size=Vector2(400,100)
	status_label.add_theme_font_override("font",preload("res://resources/fonts/nunito-sans-latin-400-normal.woff2"))
	status_label.add_theme_font_size_override("font_size",body)

func update_state(state: Dictionary) -> void:
	_state = state.duplicate()
	if not is_instance_valid(root_control): return
	var diving := bool(state.get("diving",false))
	_region.text = str(state.get("area","Bandar Hujung"))
	_region.tooltip_text = _region.text
	_resources.text = "%d KOIN" % int(state.get("coins",0))
	if not diving:
		_resources.text += "   TAS %.1f / %.1f kg" % [float(state.get("weight",0)),float(state.get("capacity",0))]
		if touch_enabled: _resources.text="%d koin · %.1f/%.1f kg" % [int(state.get("coins",0)),float(state.get("weight",0)),float(state.get("capacity",0))]
	_weather.text = (str(state.get("clock",""))+"  "+str(state.get("weather",""))).strip_edges()
	if state.get("authoritative",false):
		_weather.text="H%d · %s" % [int(state.get("calendarDay",1)),_weather.text]
		if not state.get("clockConnected",true): _weather.text="Jam dijeda · sambungkan kembali"
		elif not state.get("clockWriter",true): _weather.text="Jam aktif di sesi lain"
	_instrument.visible = diving and not _modal
	var maximum := maxf(1.0,float(state.get("maxOxygen",100)))
	var oxygen := clampf(float(state.get("oxygen",maximum)),0.0,maximum)
	var loss := _previous_oxygen-oxygen
	if diving and _was_diving and is_equal_approx(maximum,_previous_maximum) and loss>=4.0:
		_loss_seconds = 1.1
		_oxygen_loss.text = "-%d O2" % ceili(loss)
		_oxygen_loss.show()
	if not diving:
		_loss_seconds = 0.0
		_oxygen_loss.hide()
	_previous_oxygen = oxygen
	_previous_maximum = maximum
	_was_diving = diving
	_instrument.ratio = oxygen/maximum
	_instrument.reduced_motion = bool(state.get("reducedMotion",EnvironmentState.reduced_motion))
	_instrument.queue_redraw()
	_oxygen_text.text = "%d" % ceili(oxygen)
	_oxygen_max.text = "/ %d O2" % int(maximum)
	_oxygen_text.add_theme_color_override("font_color",Color("f0a080") if oxygen/maximum<=0.15 else (Color("e6bd76") if oxygen/maximum<=0.35 else CREAM))
	_depth.text = "%d m" % int(state.get("depth",0))
	_bag.text = "TAS\n%.1f/%.1f kg" % [float(state.get("weight",0)),float(state.get("capacity",0))]
	_warning.text = "O2 KRITIS - NAIK SEKARANG" if oxygen/maximum<=0.15 else "O2 MENIPIS - CARI TANGGA"
	_warning.add_theme_color_override("font_color",Color("f0a080") if oxygen/maximum<=0.15 else Color("e6bd76"))
	_warning.visible = diving and oxygen/maximum<=0.35 and not _modal
	_objective.text = str(state.get("objective",""))
	_objective.tooltip_text = _objective.text
	_objective.visible = not _modal
	_can_interact = bool(state.get("canInteract",false))
	_can_net = bool(state.get("canNet",false))
	_action_label.text = str(state.get("action",""))
	_action_label.tooltip_text = _action_label.text
	_action_label.visible = _can_interact and not _modal
	_action.disabled = _modal or not _can_interact
	_net.disabled = _modal or not _can_net
	var charging := bool(state.get("netCharging",_net_held))
	var ready := float(state.get("netProgress",_held_seconds/2.0))>=1.0
	_net_title.text = "LEPAS" if charging and ready else "JALA"
	_net.visible = (diving or _can_net) and not _modal
	_action.visible = _can_interact and not _modal
	_net.position.x = (774.0 if touch_enabled else 792.0) if _can_interact else (862.0 if touch_enabled else 870.0)
	_deck.position.x = (766.0 if touch_enabled else 784.0) if _can_interact else (854.0 if touch_enabled else 862.0)
	_deck.size.x = (180.0 if touch_enabled else 162.0) if _can_interact else (92.0 if touch_enabled else 84.0)
	_deck.visible = (diving or _can_net or _can_interact) and not _modal
	_dpad.visible = touch_enabled and not _modal
	_layout()

func set_modal(open: bool) -> void:
	_modal = open
	if is_instance_valid(_navigation): _navigation.visible = not open
	if open:
		_dpad.release()
		move_changed.emit(Vector2.ZERO)
		_release_net()
	if is_instance_valid(root_control):
		update_state(_state)
		for button in _utilities: button.disabled = open

func _release_net() -> void:
	if _net_held:
		_net_held = false
		net_released.emit()
	_held_seconds = 0.0

func message(text: String) -> void:
	if not is_instance_valid(status_label): return
	status_label.text = text
	_status_panel.visible = not text.is_empty()
	_message_until = Time.get_ticks_msec()/1000.0+4.0

func _process(delta: float) -> void:
	if is_instance_valid(_status_panel) and _status_panel.visible and Time.get_ticks_msec()/1000.0>_message_until:
		_status_panel.hide()
	if is_instance_valid(_instrument):
		_instrument.phase += delta
		if _loss_seconds>0.0:
			_loss_seconds = maxf(0.0,_loss_seconds-delta)
			_oxygen_loss.visible = _loss_seconds>0.0
			_oxygen_loss.modulate.a = 1.0 if _instrument.reduced_motion else minf(1.0,_loss_seconds*3)
			_instrument.queue_redraw()
		_instrument.loss_feedback = 0.0 if _instrument.reduced_motion else _loss_seconds
		if (_instrument.ratio<=0.15 and not _instrument.reduced_motion) or _loss_seconds>0.0: _instrument.queue_redraw()
	if _net_held: _held_seconds += delta
	if is_instance_valid(_net_charge):
		var charging := bool(_state.get("netCharging",_net_held))
		var progress := clampf(float(_state.get("netProgress",_held_seconds/2.0)),0.0,1.0)
		_net_charge.size.x = maxf(0,_net.size.x-8)*progress if charging else 0.0

func set_navigation(data: Dictionary,area: String,point: Vector2) -> void:
	if not is_instance_valid(root_control): return
	if not is_instance_valid(_navigation):
		_navigation = GeoMap.new()
		_navigation.mini = true
		_navigation.position = Vector2(360,12) if touch_enabled else Vector2(326,428)
		_navigation.size = Vector2(144,94) if touch_enabled else Vector2(128,94)
		root_control.add_child(_navigation)
	_navigation.configure(data,area,point)
	_navigation.visible = not _modal
	_layout()

func debug_layout() -> Dictionary:
	var layout := {"touch":touch_enabled,"oxygen":{"position":[_instrument.position.x,_instrument.position.y],"size":[_instrument.size.x,_instrument.size.y],"visible":_instrument.visible,"value":float(_state.get("oxygen",100)),"maximum":float(_state.get("maxOxygen",100)),"warning":_warning.visible,"warningText":_warning.text,"status":"critical" if _instrument.ratio<=.15 else ("low" if _instrument.ratio<=.35 else "normal"),"lossText":_oxygen_loss.text if _loss_seconds>0 else "","reducedMotion":_instrument.reduced_motion},"logicalSize":[960,540]}
	for item in [["sound",_sound_button],["net",_net],["action",_action],["objective",_objective_toggle]]:
		var center: Vector2 = item[1].get_global_rect().get_center()
		layout[item[0]] = [center.x,center.y]
	var names := ["map","journal","bag","character"]
	for index in range(_utilities.size()):
		var center := _utilities[index].get_global_rect().get_center()
		layout[names[index]] = [center.x,center.y]
	var center := _dpad.get_global_rect().get_center()
	layout["joystick"] = {"center":[center.x,center.y],"radius":_dpad.size.x*.32,"direction":[_dpad.direction.x,_dpad.direction.y],"pointer":_dpad.pointer}
	layout["logicalSize"] = [get_viewport().get_visible_rect().size.x,get_viewport().get_visible_rect().size.y]
	return layout
