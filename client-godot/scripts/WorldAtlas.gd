class_name WorldAtlas
extends Control

signal region_selected(id: String)
signal close_requested

const CREAM := Color("f5ebd4")
const OPEN := Color("8db9a2")
const STORY := Color("d7a76e")
const FUTURE := Color("80938f")
const MAP_RECT := Rect2(0,0,426,334)

var _world: Dictionary = {}
var _player: Dictionary = {}
var _current_area := ""
var _selected := ""
var _regions: Array = []
var _atlas: Dictionary = {}
var _title: Label
var _availability: Label
var _description: Label
var _reason: Label
var _current: Label
var _built := false

func configure(world: Dictionary, player: Dictionary, current_area: String) -> void:
	_world = world
	_player = player
	_current_area = current_area
	if is_inside_tree():
		_rebuild()

func _ready() -> void:
	custom_minimum_size = Vector2(650,390)
	size = Vector2(650,390)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_atlas = _world.get("atlas",{})
	_regions = _atlas.get("regions",[])
	var panel := Panel.new()
	panel.position = Vector2(438,0)
	panel.size = Vector2(212,334)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color("202d3a")
	style.border_color = Color("654733")
	style.border_width_left = 2
	panel.add_theme_stylebox_override("panel",style)
	add_child(panel)
	_title = _label(panel,"Pilih wilayah",Vector2(12,12),Vector2(188,52),16)
	_availability = _label(panel,"",Vector2(12,69),Vector2(188,34),11)
	_description = _label(panel,"Pilih titik pada peta untuk membaca tentang wilayahnya.",Vector2(12,108),Vector2(188,130),12)
	_reason = _label(panel,"",Vector2(12,248),Vector2(188,55),12)
	_current = _label(panel,"",Vector2(12,309),Vector2(188,20),11)
	_current.add_theme_color_override("font_color",OPEN)
	for region in _regions:
		_add_region(region)
	var close := Button.new()
	close.text = "Kembali"
	close.position = Vector2(548,346)
	close.size = Vector2(102,40)
	close.pressed.connect(func(): close_requested.emit())
	add_child(close)
	var legend := _label(self,"o Terbuka    - Alur cerita    ... Coming soon",Vector2(8,344),Vector2(526,20),11)
	legend.add_theme_color_override("font_color",Color("654733"))
	_label(self,"Peta informasi. Datangi jalur penghubung untuk berpindah wilayah.",Vector2(8,368),Vector2(526,18),10)
	_built = true
	if not _regions.is_empty():
		var initial := str(_regions[0].get("id",""))
		for region in _regions:
			if _is_current(region):
				initial = str(region.id)
				break
		if not _selected.is_empty() and not _find_region(_selected).is_empty():
			initial = _selected
		_select(initial,false)
	else:
		_description.text = "Peta wilayah belum tersedia. Tutup peta dan coba muat ulang permainan."
	queue_redraw()

func _label(parent: Node, text: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.text = text
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("302d2a") if parent==self else CREAM)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	label.set_deferred("size",dimensions)
	return label

func _point(region: Dictionary) -> Vector2:
	var width := maxf(1.0,float(_atlas.get("width",720)))
	var height := maxf(1.0,float(_atlas.get("height",1080)))
	return Vector2(24+float(region.get("mapX",0))/width*360,16+float(region.get("mapY",0))/height*292)

func _state(region: Dictionary) -> String:
	var status := str(region.get("status","coming_soon"))
	if status == "coming_soon":
		return status
	var day := int(_player.get("progress",{}).get("day",1))
	if int(region.get("requiresDay",1))>day:
		return "story"
	return "open" if status in ["open","story"] else "coming_soon"

func _color(region: Dictionary) -> Color:
	match _state(region):
		"open": return OPEN
		"story": return STORY
	return FUTURE

func _is_current(region: Dictionary) -> bool:
	var id := str(region.get("id",""))
	var aliases := {"reef":"shallow_tutorial","kelp":"kelp_forest","cave":"limestone_cave","boss":"boss_sanctuary","harbor":"city_bandar_hujung","forest":"forest_wringin"}
	return id == str(aliases.get(_current_area,_current_area)) or str(region.get("name","")).to_lower() == _current_area.to_lower()

func _add_region(region: Dictionary) -> void:
	var point := _point(region)
	var surface := str(region.get("kind","dive")) == "surface"
	var button := Button.new()
	button.text = str(region.get("name",region.get("id","Wilayah")))
	button.position = point+Vector2(-59,9) if surface else point+Vector2(13,-10)
	button.size = Vector2(118,35) if surface else Vector2(182,30)
	button.add_theme_font_size_override("font_size",11)
	button.add_theme_color_override("font_color",_color(region))
	button.add_theme_color_override("font_hover_color",CREAM)
	button.add_theme_color_override("font_focus_color",CREAM)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER if surface else HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true
	button.tooltip_text = button.text+" · "+("Coming soon" if _state(region)=="coming_soon" else "Terbuka" if _state(region)=="open" else "Terkunci oleh alur cerita")
	for kind in ["normal","hover","pressed","focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color.TRANSPARENT if kind=="normal" else Color(0.16,0.32,0.32,0.85)
		style.set_corner_radius_all(2)
		if kind=="focus":
			style.set_border_width_all(1)
			style.border_color = CREAM
		button.add_theme_stylebox_override(kind,style)
	button.pressed.connect(func(): _select(str(region.get("id",""))))
	add_child(button)

func _find_region(id: String) -> Dictionary:
	for region in _regions:
		if str(region.get("id",""))==id:
			return region
	return {}

func _select(id: String, emit_signal := true) -> void:
	var region := _find_region(id)
	if region.is_empty():
		return
	_selected = id
	_title.text = str(region.get("name",id))
	var state := _state(region)
	_availability.text = "TERBUKA" if state=="open" else "TERKUNCI · ALUR CERITA" if state=="story" else "COMING SOON"
	_availability.add_theme_color_override("font_color",_color(region))
	_description.text = str(region.get("description","Belum ada catatan wilayah ini."))
	_reason.text = "Jalur ini dapat dijelajahi melalui penghubung di dunia permainan." if state=="open" else "Lanjutkan kisah warga hingga siklus %d untuk membuka jalur ini." % int(region.get("requiresDay",2)) if state=="story" else "Wilayah ini direncanakan untuk bab berikutnya. Belum dapat dimasuki atau dibuka melalui peningkatan alat."
	_current.text = "Lokasi sekarang" if _is_current(region) else ""
	queue_redraw()
	if emit_signal:
		region_selected.emit(id)

func _draw() -> void:
	if not _built:
		return
	draw_rect(MAP_RECT,Color("0b2933"))
	draw_rect(Rect2(0,0,426,76),Color("244f46"))
	for i in range(5):
		draw_line(Vector2(0,77+i*49),Vector2(426,77+i*49),Color(0.29,0.49,0.49,0.2),1)
	var font := ThemeDB.fallback_font
	draw_string(font,Vector2(10,13),"DARATAN",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("bbcec0"))
	draw_string(font,Vector2(10,91),"PALUNG SMARA",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("99b4ad"))
	var roads: Array = _atlas.get("roads",[]).duplicate()
	if roads.is_empty():
		for region in _regions:
			for target in region.get("connections",[]):
				roads.append({"from":str(region.get("id","")),"to":str(target)})
	for road in roads:
		var from := _find_region(str(road.get("from","")))
		var to := _find_region(str(road.get("to","")))
		if from.is_empty() or to.is_empty():
			continue
		var start := _point(from)
		var end := _point(to)
		var midpoint := Vector2(end.x,start.y) if from.get("kind","")==to.get("kind","") else Vector2(start.x,end.y)
		var faded := _state(from)=="coming_soon" or _state(to)=="coming_soon"
		var color := Color(0.48,0.61,0.57,0.45) if faded else Color(0.64,0.76,0.66,0.7)
		if faded:
			draw_dashed_line(start,midpoint,color,1.0,4.0)
			draw_dashed_line(midpoint,end,color,1.0,4.0)
		else:
			draw_line(start,midpoint,color,2.0)
			draw_line(midpoint,end,color,2.0)
	for region in _regions:
		var point := _point(region)
		var state := _state(region)
		draw_circle(point,7,Color("082e35"))
		if state=="open":
			draw_circle(point,4,_color(region))
		else:
			draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),_color(region),false,1.5)
		if str(region.get("id",""))==_selected:
			draw_arc(point,10,0,TAU,24,CREAM,1.5)
		if _is_current(region):
			draw_line(point+Vector2(-4,-14),point+Vector2(4,-14),CREAM,2)
			draw_line(point+Vector2(0,-14),point+Vector2(0,-9),CREAM,2)
