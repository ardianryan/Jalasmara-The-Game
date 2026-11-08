class_name WorldAtlas
extends Control
signal region_selected(id: String)
signal close_requested
var _world: Dictionary = {}
var _player: Dictionary = {}
var _current_area := "hub"
var _map: GeoMap
var _info: Label
var _point := Vector2.ZERO

func configure(world: Dictionary, player: Dictionary, current_area: String) -> void:
	_world = world
	_player = player
	_current_area = "sea" if current_area in ["reef","kelp","cave","boss","Dangkalan Segaran","Hutan Lamun Wringin","Rongga Kapur Jalatunda","Pelataran Kuno Tamansari"] or not GameState.dive.is_empty() else "forest" if current_area in ["forest","forest_wringin"] else "hub"
	var source: Dictionary = GameState.dive.get("position",{}) if _current_area=="sea" else GameState.surface
	_point = Vector2(float(source.get("x",1120)),float(source.get("y",1230)))
	if is_inside_tree(): _build()

func set_player_position(point: Vector2) -> void:
	_point = point
	if is_instance_valid(_map): _map.player_point=point; _map.queue_redraw()

func _ready() -> void:
	custom_minimum_size=Vector2(650,390)
	size=Vector2(650,390)
	_build()

func _build() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	var title := Label.new()
	title.text="PETA BANDAR HUJUNG & PALUNG SMARA"
	title.add_theme_font_size_override("font_size",16)
	title.add_theme_color_override("font_color",Color("302d2a"))
	add_child(title)
	for sign in ["-","+"]:
		var zoom_button:=Button.new()
		zoom_button.text=sign
		zoom_button.position=Vector2(574 if sign=="-" else 614,0)
		zoom_button.size=Vector2(36,28)
		zoom_button.pressed.connect(func():
			_map.zoom=clampf(_map.zoom*(1.25 if sign=="+" else 0.8),1,4)
			_map.queue_redraw()
		)
		add_child(zoom_button)
	_map=GeoMap.new()
	_map.position=Vector2(0,35)
	_map.size=Vector2(650,285)
	_map.configure(_world,_current_area,_point)
	_map.place_selected.connect(func(place:Dictionary):
		_info.text=str(place.name)+(" · "+str(place.reason) if place.has("reason") else "")
		region_selected.emit(str(place.name))
	)
	add_child(_map)
	_info=Label.new()
	_info.position=Vector2(0,325)
	_info.size=Vector2(650,27)
	_info.clip_text=true
	_info.add_theme_font_size_override("font_size",11)
	_info.add_theme_color_override("font_color",Color("302d2a"))
	_info.text="Segitiga: posisi Anda · Klik lokasi untuk info · Seret peta / roda mouse: perbesar"
	add_child(_info)
	var x:=0.0
	for item in [["Daratan","hub"],["Penampang palung","sea"]]:
		var button:=Button.new()
		button.text=item[0]
		button.position=Vector2(x,356)
		button.size=Vector2(145,32)
		button.pressed.connect(func():
			_map.zoom=1
			_map.pan=Vector2.ZERO
			var destination: String=str(item[1])
			var map_area: String=_current_area if destination=="hub" and _current_area!="sea" else destination
			var actual_point: Vector2=_point if (destination=="sea")==(_current_area=="sea") else Vector2(-100000,-100000)
			_map.configure(_world,map_area,actual_point)
		)
		add_child(button)
		x+=154
	var close:=Button.new()
	close.text="Kembali [M]"
	close.position=Vector2(512,356)
	close.size=Vector2(138,32)
	close.pressed.connect(func():close_requested.emit())
	add_child(close)
