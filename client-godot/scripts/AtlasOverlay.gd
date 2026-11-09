extends Control
signal close_requested
const HudArt = preload("res://scripts/HudSkin.gd")
var _panel: PanelContainer
var _atlas: WorldAtlas
var _point := Vector2.ZERO
var _area := "hub"

func configure(area: String,point: Vector2) -> void:
	_area = area
	_point = point
	if is_instance_valid(_atlas):
		_atlas.configure(GameState.world,GameState.player,_area)
		_atlas.set_player_position(_point)
		_skin_controls(_atlas)

func _ready() -> void:
	set_meta("world_map",true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.04,0.09,0.09,.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel",HudArt.panel("paper"))
	add_child(_panel)
	_atlas = preload("res://scripts/WorldAtlas.gd").new()
	_panel.add_child(_atlas)
	_atlas.configure(GameState.world,GameState.player,_area)
	_atlas.set_player_position(_point)
	_skin_controls(_atlas)
	_atlas.close_requested.connect(func():close_requested.emit())
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var view := get_viewport().get_visible_rect().size
	var inset := ViewportLayout.insets()
	var top := ceilf(60*view.x/maxf(1,Vector2(get_window().size).x))+inset.y
	_panel.position = Vector2(16+inset.x,top)
	_panel.size = view-Vector2(32+inset.x+inset.z,top+16+inset.w)

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()

func _skin_controls(node: Node) -> void:
	if node is Button:
		HudArt.apply_button(node)
		if node.text=="Tutup": HudArt.set_icon(node,"close",28)
	for child in node.get_children(): _skin_controls(child)
