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
		draw_rect(Rect2(2,2,w-4,h-5),Color("f1e1bc") if paper else Color(0.125,0.176,0.227,0.92))
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

var root_control: Control
var status_label: Label
var touch_enabled := false
var _region: Label
var _depth: Label
var _resources: Label
var _weather: Label
var _oxygen_text: Label
var _oxygen_track: ColorRect
var _oxygen_fill: ColorRect
var _objective: Label
var _area_panel: Panel
var _status_panel: Panel
var _action: Button
var _action_label: Label
var _net: Button
var _dpad: Control
var _utilities: Array[Button] = []
var _modal := false
var _net_held := false
var _can_interact := false
var _can_net := false
var _message_until := 0.0
var _state: Dictionary = {}

func _ready() -> void:
	layer = 10
	touch_enabled = DisplayServer.is_touchscreen_available()
	if OS.has_feature("web"):
		touch_enabled = bool(JavaScriptBridge.get_interface("window").matchMedia("(pointer:coarse)").matches)
	root_control = Control.new()
	root_control.name = "GameHudControls"
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)
	root_control.theme = _theme()
	_build_region()
	_build_utilities()
	_build_objective()
	_build_actions()
	_build_dpad()
	_status_panel = _panel(Rect2(344,72,272,42),false)
	status_label = _label(_status_panel,"",Vector2(9,7),Vector2(254,29),12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_panel.hide()
	update_state(_state)

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 13
	theme.set_color("font_color","Label",CREAM)
	for kind in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = INK if kind=="normal" else WOOD
		style.set_border_width_all(1)
		style.border_color = COPPER
		style.border_width_bottom = 3
		if kind=="disabled": style.bg_color = Color("343732")
		if kind=="focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = CREAM
		theme.set_stylebox(kind,"Button",style)
	theme.set_color("font_color","Button",CREAM)
	theme.set_color("font_hover_color","Button",CREAM)
	theme.set_color("font_pressed_color","Button",CREAM)
	theme.set_color("font_disabled_color","Button",Color("938d7b"))
	return theme

func _panel(rect: Rect2, paper: bool) -> Panel:
	var panel := Plate.new()
	panel.paper = paper
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	root_control.add_child(panel)
	return panel

func _label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size := 13) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_outline_color",Color("202d3a"))
	label.add_theme_constant_override("outline_size",2)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	parent.add_child(label)
	label.set_deferred("size",dimensions)
	return label

func _button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.text = text
	if callback.is_valid(): button.pressed.connect(callback)
	root_control.add_child(button)
	return button

func _icon_button(kind: String, rect: Rect2, callback: Callable, hint := "") -> Button:
	var button := _button("",rect,callback)
	if touch_enabled:
		for kind_name in ["normal","hover","pressed","disabled"]:
			button.add_theme_stylebox_override(kind_name,StyleBoxEmpty.new())
	var visual_size := 48.0 if touch_enabled else rect.size.x
	var plate := Plate.new()
	plate.position = (rect.size-Vector2.ONE*visual_size)/2
	plate.size = Vector2.ONE*visual_size
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
	button.add_child(plate)
	var icon := HudIcon.new()
	icon.kind = kind
	icon.position = Vector2.ONE*(visual_size-25)/2
	icon.size = Vector2(25,25)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(icon)
	if not hint.is_empty() and not touch_enabled:
		var key := _label(plate,hint,Vector2(visual_size-13,visual_size-12),Vector2(12,11),8)
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return button

func _build_region() -> void:
	var width := 316.0 if touch_enabled else 258.0
	_area_panel = _panel(Rect2(14,12,width,52 if touch_enabled else 48),true)
	_region = _label(_area_panel,"Bandar Hujung",Vector2(10,4),Vector2(width-60,24),18 if touch_enabled else 14)
	_region.add_theme_color_override("font_color",Color("302d2a"))
	_region.add_theme_constant_override("outline_size",0)
	_depth = _label(_area_panel,"",Vector2(width-48,7),Vector2(38,20),13 if touch_enabled else 11)
	_depth.add_theme_color_override("font_color",WOOD)
	_depth.add_theme_constant_override("outline_size",0)
	_depth.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_resources = _label(_area_panel,"",Vector2(10,29),Vector2(width-20,20),14 if touch_enabled else 11)
	_resources.add_theme_color_override("font_color",Color("554a38"))
	_resources.add_theme_constant_override("outline_size",0)
	_weather = _label(root_control,"",Vector2(20,68 if touch_enabled else 62),Vector2(width-6,21),15 if touch_enabled else 11)
	_oxygen_text = _label(root_control,"",Vector2(20,92 if touch_enabled else 84),Vector2(88,18),13 if touch_enabled else 10)
	_oxygen_track = ColorRect.new()
	_oxygen_track.position = Vector2(104,99 if touch_enabled else 90)
	_oxygen_track.size = Vector2(width-100,5)
	_oxygen_track.color = INK
	_oxygen_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(_oxygen_track)
	_oxygen_fill = ColorRect.new()
	_oxygen_fill.color = LAMUN
	_oxygen_fill.size = _oxygen_track.size
	_oxygen_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_oxygen_track.add_child(_oxygen_fill)

func _build_utilities() -> void:
	var width := 72.0 if touch_enabled else 36.0
	var x := 640.0 if touch_enabled else 782.0
	for item in [["map","Peta","M",func():map_requested.emit()],["journal","Jurnal","J",func():journal_requested.emit()],["bag","Tas","I",func():inventory_requested.emit()],["character","Tampilan","",func():character_requested.emit()]]:
		var button := _icon_button(item[0],Rect2(x,6 if touch_enabled else 14,width,width),item[3],item[2])
		button.tooltip_text = str(item[1])+" ["+str(item[2])+"]" if not str(item[2]).is_empty() else str(item[1])
		_utilities.append(button)
		x += width+4

func _build_objective() -> void:
	_objective = _label(root_control,"",Vector2(20,114 if touch_enabled else 105),Vector2(340,22),15 if touch_enabled else 11)
	_objective.add_theme_color_override("font_color",CREAM)

func _build_actions() -> void:
	_action_label = _label(root_control,"",Vector2(652,422) if touch_enabled else Vector2(620,487),Vector2(288,26) if touch_enabled else Vector2(216,22),17 if touch_enabled else 12)
	_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_action = _icon_button("action",Rect2(868,448,72,72) if touch_enabled else Rect2(900,478,44,44),func():interact_requested.emit())
	_action.tooltip_text = "Aksi [E]"
	if not touch_enabled:
		var key := _label(_action,"E",Vector2(12,10),Vector2(20,24),17)
		_action.get_child(0).hide()
		key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_net = _icon_button("net",Rect2(780,448,72,72) if touch_enabled else Rect2(846,478,44,44),Callable(),"Sp")
	_net.tooltip_text = "Jala Kognisi: tahan, lalu lepas [Spasi]"
	_net.button_down.connect(func():
		if not _modal and _can_net:
			_net_held = true
			net_pressed.emit()
	)
	_net.button_up.connect(_release_net)

func _build_dpad() -> void:
	_dpad = Control.new()
	_dpad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(_dpad)
	for item in [["^",Vector2(96,368),Vector2.UP],["<",Vector2(20,444),Vector2.LEFT],["v",Vector2(96,444),Vector2.DOWN],[">",Vector2(172,444),Vector2.RIGHT]]:
		var button := Button.new()
		button.position = item[1]
		button.size = Vector2(72,72)
		button.focus_mode = Control.FOCUS_NONE
		for kind in ["normal","hover","pressed"]: button.add_theme_stylebox_override(kind,StyleBoxEmpty.new())
		var plate := Plate.new()
		plate.position = Vector2(8,8)
		plate.size = Vector2(56,56)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
		button.add_child(plate)
		var label := _label(plate,item[0],Vector2(0,11),Vector2(56,34),23)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.button_down.connect(func():
			if not _modal: move_changed.emit(item[2])
		)
		button.button_up.connect(func():move_changed.emit(Vector2.ZERO))
		_dpad.add_child(button)
	_dpad.visible = touch_enabled

func update_state(state: Dictionary) -> void:
	_state = state.duplicate()
	if not is_instance_valid(root_control): return
	var diving := bool(state.get("diving",false))
	_region.text = str(state.get("area","Bandar Hujung"))
	_region.tooltip_text = _region.text
	_depth.text = "%dm" % int(state.get("depth",0)) if diving else ""
	_resources.text = "%d koin  /  Tas %.1f / %.1f kg" % [int(state.get("coins",0)),float(state.get("weight",0)),float(state.get("capacity",0))]
	_weather.text = (str(state.get("clock",""))+"  "+str(state.get("weather",""))).strip_edges()
	_oxygen_text.visible = diving
	_oxygen_track.visible = diving
	var maximum := maxf(1.0,float(state.get("maxOxygen",100)))
	var oxygen := clampf(float(state.get("oxygen",maximum)),0.0,maximum)
	_oxygen_text.text = "O2 %d / %d" % [ceili(oxygen),int(maximum)]
	_oxygen_fill.size.x = _oxygen_track.size.x*oxygen/maximum
	_oxygen_fill.color = Color("dc8f75") if oxygen/maximum<0.25 else LAMUN
	_objective.text = str(state.get("objective",""))
	_objective.tooltip_text = _objective.text
	_objective.position.y = (114 if diving else 91) if touch_enabled else (105 if diving else 81)
	_can_interact = bool(state.get("canInteract",false))
	_can_net = bool(state.get("canNet",false))
	_action_label.text = str(state.get("action",""))
	_action_label.tooltip_text = _action_label.text
	_action_label.visible = _can_interact and not _modal
	_action.visible = _can_interact and not _modal
	_action.disabled = _modal or not _can_interact
	_net.visible = (diving or _can_net) and not _modal
	_net.disabled = _modal or not _can_net
	_dpad.visible = touch_enabled and not _modal

func set_modal(open: bool) -> void:
	_modal = open
	if open:
		move_changed.emit(Vector2.ZERO)
		_release_net()
	if is_instance_valid(root_control):
		update_state(_state)
		for button in _utilities: button.disabled = open

func _release_net() -> void:
	if _net_held:
		_net_held = false
		net_released.emit()

func message(text: String) -> void:
	if not is_instance_valid(status_label): return
	status_label.text = text
	_status_panel.visible = not text.is_empty()
	_message_until = Time.get_ticks_msec()/1000.0+4.0

func _process(_delta: float) -> void:
	if is_instance_valid(_status_panel) and _status_panel.visible and Time.get_ticks_msec()/1000.0>_message_until:
		_status_panel.hide()
