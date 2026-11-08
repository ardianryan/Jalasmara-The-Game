class_name GeoMap
extends Control

signal place_selected(place: Dictionary)
var world: Dictionary = {}
var area := "hub"
var player_point := Vector2.ZERO
var mini := false
var zoom := 1.0
var pan := Vector2.ZERO
var places: Array[Dictionary] = []
var selected: Dictionary = {}
var _drag := false
var _drag_distance := 0.0
var _textures: Dictionary = {}
func _forest_offset() -> Vector2:
	var forest: Dictionary=world.get("forest",{})
	var gate: Dictionary=forest.get("gate",{"x":2200,"y":270})
	var entry: Dictionary=forest.get("entry",{"x":200,"y":1320})
	return Vector2(float(gate.x)-float(entry.x),float(gate.y)-float(entry.y))
const PIXEL_FONT = preload("res://resources/fonts/ark-pixel-12px-proportional-latin.otf")
const PAPER := Color("e7d8b4")
const SEA := Color("254d5b")

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE if mini else Control.MOUSE_FILTER_STOP
	for key in ["coastal-village-map","forest-muara","ocean-depth-background"]:
		var path: String = "res://resources/art/" + str(key) + ".png"
		if ResourceLoader.exists(path): _textures[key] = load(path)
	queue_redraw()

func configure(data: Dictionary, location: String, point: Vector2) -> void:
	world = data
	area = location
	player_point = point
	places.clear()
	if area == "sea":
		for group in ["landmarks","puzzles","caches"]:
			for item in world.get(group,[]):
				places.append({"name":str(item.get("name","Peti peninggalan")),"point":Vector2(float(item.x),float(item.y)),"kind":group})
		places.append({"name":"Tangga Bandar Hujung","point":Vector2(1120,470),"kind":"door"})
	else:
		for item in world.get("surface_hub",{}).get("districts",[]):
			places.append({"name":str(item.name),"point":Vector2(float(item.x),float(item.get("y",780))),"kind":"village"})
		var gate: Dictionary = world.get("forest",{}).get("gate",{"x":2200,"y":270})
		places.append({"name":"Jalur Hutan Wringin","point":Vector2(float(gate.x),float(gate.y)),"kind":"door"})
		var dive: Dictionary = world.get("hub",{}).get("divePoint",{"x":1280,"y":1430})
		places.append({"name":"Tangga Palung Smara","point":Vector2(float(dive.x),float(dive.y)),"kind":"door"})
		for stair in world.get("hub",{}).get("stairs",[]):
			places.append({"name":"Tangga pelataran","point":Vector2(float(stair.x),float(stair.y)),"kind":"stairs"})
		for item in world.get("forest",{}).get("landmarks",[]):
			places.append({"name":str(item.name),"point":_forest_offset()+Vector2(float(item.x),float(item.y)),"kind":"forest"})
		for item in world.get("forest",{}).get("blockedExits",[]):
			places.append({"name":str(item.name)+" · Coming soon","point":_forest_offset()+Vector2(float(item.x),float(item.y)),"kind":"locked","reason":str(item.reason)})
	queue_redraw()

func _player_global() -> Vector2:
	return player_point+_forest_offset() if area == "forest" else player_point

func _source() -> Rect2:
	if mini:
		return Rect2(_player_global()-Vector2(520,360),Vector2(1040,720))
	var base := Rect2(0,0,6144,3584) if area == "sea" else Rect2(-150,-1200,4700,2950)
	var view_size := base.size/zoom
	return Rect2(base.get_center()-view_size/2+pan,view_size)

func _fit() -> Rect2:
	var source := _source()
	var factor := minf(size.x/source.size.x,size.y/source.size.y)
	var extent := source.size*factor
	return Rect2((size-extent)/2,extent)

func _screen(point: Vector2) -> Vector2:
	var view := _source()
	var target := _fit()
	return target.position+(point-view.position)/view.size*target.size

func _world_at(point: Vector2) -> Vector2:
	var target := _fit()
	return _source().position+(point-target.position)/target.size*_source().size

func _image(key: String, rect: Rect2, color := Color.WHITE) -> void:
	if not _textures.has(key): return
	var target := Rect2(_screen(rect.position),rect.size/_source().size*_fit().size)
	draw_texture_rect(_textures[key],target,false,color)

func _path(points: Array, offset: Vector2, width: float, color: Color) -> void:
	var line := PackedVector2Array()
	for point in points: line.append(_screen(offset+Vector2(float(point[0]),float(point[1]))))
	if line.size()>1:
		draw_polyline(line,Color("574d38"),maxf(2,width+2),false)
		draw_polyline(line,color,width,false)

func _draw() -> void:
	if world.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),SEA)
	if area == "sea":
		_image("ocean-depth-background",Rect2(0,0,6144,3584),Color(0.45,0.65,0.7,1))
		for rect in world.get("terrain",[]):
			var origin := _screen(Vector2(float(rect[0]),float(rect[1])))
			var extent := Vector2(float(rect[2]),float(rect[3]))/_source().size*_fit().size
			draw_rect(Rect2(origin,extent),Color("87978b"))
		if not mini:
			for depth in [25,60,95]:
				var y := _screen(Vector2(0,400+depth*28)).y
				draw_dashed_line(Vector2(0,y),Vector2(size.x,y),Color(0.83,0.9,0.82,0.28),1,4)
				draw_string(PIXEL_FONT,Vector2(5,y-4),"%d m"%depth,HORIZONTAL_ALIGNMENT_LEFT,-1,10,PAPER)
	else:
		_image("coastal-village-map",Rect2(0,0,2400,1600))
		_image("forest-muara",Rect2(_forest_offset(),Vector2(2400,1600)))
		for path in world.get("hub",{}).get("paths",[]): _path(path,Vector2.ZERO,2 if mini else 3,Color("dfc388"))
		for path in world.get("forest",{}).get("walkablePaths",[]): _path(path,_forest_offset(),1.5 if mini else 2,Color("d4b77c"))
	var label_boxes: Array[Rect2] = []
	var label_order: Array = places.duplicate()
	if not selected.is_empty():
		label_order.erase(selected)
		label_order.push_front(selected)
	for place in places:
		var at := _screen(place.point)
		if not Rect2(Vector2.ZERO,size).grow(-4).has_point(at): continue
		var locked := str(place.kind)=="locked"
		var color := Color("b3aaa0") if locked else Color("f5df9e")
		draw_circle(at,3 if mini else 5,Color("293d3d"))
		if locked:
			draw_line(at-Vector2(3,3),at+Vector2(3,3),color,2)
			draw_line(at+Vector2(-3,3),at+Vector2(3,-3),color,2)
		else: draw_circle(at,2 if mini else 3,color)
	if not mini:
		for place in label_order:
			var at := _screen(place.point)
			if not Rect2(Vector2.ZERO,size).grow(-4).has_point(at): continue
			if zoom<=1.3 and selected.get("name","")!=place.name: continue
			var title := str(place.name)
			var extent := PIXEL_FONT.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,10)
			var origin := at+Vector2(7,-6)
			origin.x = clampf(origin.x,4,maxf(4,size.x-extent.x-4))
			origin.y = clampf(origin.y,14,size.y-4)
			var box := Rect2(origin-Vector2(2,11),extent+Vector2(5,4))
			var overlaps := false
			for occupied in label_boxes:
				if box.intersects(occupied): overlaps = true
			if overlaps: continue
			label_boxes.append(box)
			draw_rect(box,Color(0.1,0.18,0.18,0.9))
			draw_string(PIXEL_FONT,origin,title,HORIZONTAL_ALIGNMENT_LEFT,-1,10,PAPER)
	var here := _screen(_player_global())
	if Rect2(Vector2.ZERO,size).has_point(here):
		draw_circle(here,6 if mini else 8,Color("263538"))
		draw_colored_polygon(PackedVector2Array([here+Vector2(0,-6),here+Vector2(5,5),here+Vector2(0,2),here+Vector2(-5,5)]),Color("fff1c4"))
	draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("af8759"),false,2)
	if mini: draw_string(PIXEL_FONT,Vector2(size.x-14,13),"m" if area=="sea" else "N",HORIZONTAL_ALIGNMENT_LEFT,-1,9,PAPER)

func _gui_input(event: InputEvent) -> void:
	if mini: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			zoom = minf(4,zoom*1.2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			zoom = maxf(1,zoom/1.2)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag = true
				_drag_distance = 0
			else:
				_drag = false
				if _drag_distance<6: select_nearest(event.position)
		queue_redraw()
		accept_event()
	elif event is InputEventMouseMotion and _drag:
		_drag_distance += event.relative.length()
		pan -= event.relative/_fit().size*_source().size
		queue_redraw()
		accept_event()

func select_nearest(point: Vector2) -> void:
	var nearest := 28.0
	selected = {}
	for place in places:
		var distance := _screen(place.point).distance_to(point)
		if distance<nearest:
			nearest = distance
			selected = place
	if not selected.is_empty(): place_selected.emit(selected)
	queue_redraw()
