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

const INK := Color("082e35")
const CREAM := Color("f5ebd4")
const LAMUN := Color("8db9a2")
const COPPER := Color("d7a76e")
const MUTED := Color("bacdc5")

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
var _objective_panel: Panel
var _action: Button
var _net: Button
var _dpad: Control
var _directions: Array[Button] = []
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
	_status_panel = _panel(Rect2(308,65,380,58))
	status_label = _label(_status_panel,"",Vector2(12,8),Vector2(356,44),13)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_panel.hide()
	update_state(_state)

func _theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 14
	theme.set_color("font_color","Label",CREAM)
	for kind in ["normal","hover","pressed","disabled","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("16494f")
		if kind == "hover":
			style.bg_color = Color("23636a")
		elif kind == "pressed":
			style.bg_color = Color("367771")
		elif kind == "disabled":
			style.bg_color = Color("183a40")
		style.set_corner_radius_all(3)
		style.set_border_width_all(1)
		style.border_color = Color("426367")
		if kind == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = COPPER
			style.set_border_width_all(2)
		theme.set_stylebox(kind,"Button",style)
	theme.set_color("font_color","Button",CREAM)
	theme.set_color("font_hover_color","Button",CREAM)
	theme.set_color("font_pressed_color","Button",CREAM)
	theme.set_color("font_disabled_color","Button",Color("8baba5"))
	return theme

func _panel(rect: Rect2) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(INK.r,INK.g,INK.b,0.94)
	style.set_corner_radius_all(3)
	style.border_color = Color("55716c")
	style.border_width_left = 2
	panel.add_theme_stylebox_override("panel",style)
	root_control.add_child(panel)
	return panel

func _label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size := 14) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",font_size)
	label.clip_text = true
	parent.add_child(label)
	return label

func _button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = rect.position
	button.size = rect.size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_NONE
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if callback.is_valid():
		button.pressed.connect(callback)
	root_control.add_child(button)
	return button

func _build_region() -> void:
	_area_panel = _panel(Rect2(16,12,280,94))
	_region = _label(_area_panel,"Bandar Hujung",Vector2(12,8),Vector2(204,23),15)
	_depth = _label(_area_panel,"",Vector2(214,8),Vector2(54,23),13)
	_depth.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_depth.add_theme_color_override("font_color",COPPER)
	_resources = _label(_area_panel,"",Vector2(12,36),Vector2(256,21),12)
	_resources.add_theme_color_override("font_color",MUTED)
	_weather = _label(_area_panel,"",Vector2(12,57),Vector2(256,18),11)
	_weather.add_theme_color_override("font_color",COPPER)
	_oxygen_text = _label(_area_panel,"",Vector2(12,57),Vector2(256,18),11)
	_oxygen_track = ColorRect.new()
	_oxygen_track.color = Color("3b5658")
	_oxygen_track.position = Vector2(12,80)
	_oxygen_track.size = Vector2(256,5)
	_oxygen_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area_panel.add_child(_oxygen_track)
	_oxygen_fill = ColorRect.new()
	_oxygen_fill.color = LAMUN
	_oxygen_fill.size = Vector2(256,5)
	_oxygen_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_oxygen_track.add_child(_oxygen_fill)

func _build_utilities() -> void:
	var height := 44.0 if touch_enabled else 34.0
	var items := [
		["Peta", "M", 82.0, func(): map_requested.emit()],
		["Jurnal", "J", 92.0, func(): journal_requested.emit()],
		["Tas", "I", 70.0, func(): inventory_requested.emit()],
		["Tampilan", "", 96.0, func(): character_requested.emit()]
	]
	var x := 586.0
	for item in items:
		var text: String = item[0]
		if not touch_enabled and not str(item[1]).is_empty():
			text += " [%s]" % item[1]
		var button := _button(text,Rect2(x,12,float(item[2]),height),item[3])
		button.add_theme_font_size_override("font_size",13)
		_utilities.append(button)
		x += float(item[2])+6.0

func _build_objective() -> void:
	_objective_panel = _panel(Rect2(208,460,508,64))
	var title := _label(_objective_panel,"TUJUAN",Vector2(12,6),Vector2(484,15),10)
	title.add_theme_color_override("font_color",COPPER)
	_objective = _label(_objective_panel,"Jelajahi Bandar Hujung.",Vector2(12,23),Vector2(484,37),13)
	_objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_actions() -> void:
	_action = _button("Aksi [E]",Rect2(734,398,210,48),func(): interact_requested.emit())
	_action.add_theme_font_size_override("font_size",13)
	_net = _button("Jala Kognisi\nTahan, lalu lepas",Rect2(734,458,210,66),Callable())
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
	for item in [["^",Vector2(74,396),Vector2.UP],["<",Vector2(18,452),Vector2.LEFT],["v",Vector2(74,452),Vector2.DOWN],[">",Vector2(130,452),Vector2.RIGHT]]:
		var button := Button.new()
		button.text = item[0]
		button.position = item[1]
		button.size = Vector2(50,50)
		button.add_theme_font_size_override("font_size",22)
		button.focus_mode = Control.FOCUS_NONE
		button.button_down.connect(func():
			if not _modal:
				move_changed.emit(item[2])
		)
		button.button_up.connect(func(): move_changed.emit(Vector2.ZERO))
		_dpad.add_child(button)
		_directions.append(button)
	_dpad.visible = touch_enabled

func update_state(state: Dictionary) -> void:
	_state = state.duplicate()
	if not is_instance_valid(root_control):
		return
	var diving := bool(state.get("diving",false))
	_region.text = str(state.get("area","Bandar Hujung"))
	_region.tooltip_text = _region.text
	_depth.text = "%dm" % int(state.get("depth",0)) if diving else ""
	_resources.text = "%d koin    Tas %.1f / %.1f kg" % [int(state.get("coins",0)),float(state.get("weight",0)),float(state.get("capacity",0))]
	_oxygen_text.visible = diving
	_oxygen_track.visible = diving
	var clock := str(state.get("clock",""))
	var weather := str(state.get("weather",""))
	var has_weather := not clock.is_empty() or not weather.is_empty()
	_weather.text = (clock+"  "+weather).strip_edges()
	_weather.visible = has_weather
	_oxygen_text.position.y = 75 if has_weather else 57
	_oxygen_track.position.y = 98 if has_weather else 80
	_area_panel.size.y = (112 if has_weather else 94) if diving else (84 if has_weather else 64)
	var maximum := maxf(1.0,float(state.get("maxOxygen",100)))
	var oxygen := clampf(float(state.get("oxygen",maximum)),0.0,maximum)
	_oxygen_text.text = "Oksigen %d / %d" % [ceili(oxygen),int(maximum)]
	_oxygen_fill.size.x = 256.0*oxygen/maximum
	_oxygen_fill.color = Color("dc8f75") if oxygen/maximum<0.25 else LAMUN
	_objective.text = str(state.get("objective","Jelajahi Bandar Hujung."))
	_objective.tooltip_text = _objective.text
	_can_interact = bool(state.get("canInteract",false))
	_can_net = bool(state.get("canNet",false))
	var action := str(state.get("action","Dekati tempat atau tokoh"))
	_action.text = action if touch_enabled else action+" [E]"
	_action.tooltip_text = _action.text
	_action.disabled = _modal or not _can_interact
	_net.text = "Jala Kognisi\nTahan, lalu lepas" if touch_enabled else "Jala Kognisi\nTahan, lalu lepas [Spasi]"
	_net.visible = diving or _can_net
	_net.disabled = _modal or not _can_net
	_dpad.visible = touch_enabled and not _modal

func set_modal(open: bool) -> void:
	_modal = open
	if open:
		move_changed.emit(Vector2.ZERO)
		_release_net()
	if is_instance_valid(root_control):
		update_state(_state)
		for button in _utilities:
			button.disabled = open

func _release_net() -> void:
	if _net_held:
		_net_held = false
		net_released.emit()

func message(text: String) -> void:
	if not is_instance_valid(status_label):
		return
	status_label.text = text
	_status_panel.visible = not text.is_empty()
	_message_until = Time.get_ticks_msec()/1000.0+5.0

func _process(_delta: float) -> void:
	if is_instance_valid(_status_panel) and _status_panel.visible and Time.get_ticks_msec()/1000.0>_message_until:
		_status_panel.hide()
