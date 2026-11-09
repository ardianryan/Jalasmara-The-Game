class_name GeoMap
extends Control
const Geography = preload("res://scripts/MapGeography.gd")

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
	focus_mode = Control.FOCUS_NONE if mini else Control.FOCUS_ALL
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	for key in ["ocean-depth-background"]:
		var path: String = "res://resources/art/" + str(key) + ".png"
		if ResourceLoader.exists(path): _textures[key] = load(path)
	queue_redraw()

func configure(data: Dictionary, location: String, point: Vector2) -> void:
	world = data
	area = location
	player_point = point
	selected = {}
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
	var base := Rect2(0,0,6144,3584) if area == "sea" else Rect2(-300,-1400,5100,3100)
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

func _land_outline() -> PackedVector2Array:
	return Geography.coastline(_forest_offset())

func _outline_on_screen(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(_screen(point))
	return result

func _draw_land_polygon(points: PackedVector2Array, color: Color) -> void:
	if points.size()<3: return
	var screen_points:=_outline_on_screen(points)
	var twice_area:=0.0
	for index in range(1,screen_points.size()-1):
		twice_area+=(screen_points[index]-screen_points[0]).cross(screen_points[index+1]-screen_points[0])
	# Tiny clipped trail tips cannot cover a pixel and lose precision in canvas triangulation.
	if absf(twice_area)<.5: return
	draw_colored_polygon(screen_points,color)

func _near_road(point: Vector2) -> bool:
	for group in [[world.get("hub",{}).get("paths",[]),Vector2.ZERO],[world.get("forest",{}).get("walkablePaths",[]),_forest_offset()]]:
		for path in group[0]:
			for index in range(path.size()-1):
				var a: Vector2 = Vector2(float(path[index][0]),float(path[index][1]))+group[1]
				var b: Vector2 = Vector2(float(path[index+1][0]),float(path[index+1][1]))+group[1]
				if Geometry2D.get_closest_point_to_segment(point,a,b).distance_to(point)<145:
					return true
	return false

func _draw_land_geography() -> void:
	if not world.get("landMaps",{}).is_empty():
		_draw_component_geography()
		return
	var offset := _forest_offset()
	var shore := _land_outline()
	var edge := _outline_on_screen(shore)
	edge.append(edge[0])
	draw_polyline(edge,Color("65918e"),10 if not mini else 6,false)
	draw_polyline(edge,Color("adc2a3"),5 if not mini else 3,false)
	_draw_land_polygon(shore,Color("c8b98b"))
	draw_polyline(edge,Color("8c805d"),1.5,false)
	var forest_area := Geography.forest_outline(offset)
	for piece in Geometry2D.intersect_polygons(forest_area,shore):
		_draw_land_polygon(piece,Color("97a67a"))
	# Contour bands describe the inland rise while preserving the same map coordinates.
	for ring in range(4):
		var line := PackedVector2Array()
		for step in range(37):
			var angle := TAU*step/36.0
			var point := offset+Vector2(1340,470)+Vector2(cos(angle)*(350+ring*140),sin(angle)*(220+ring*95))
			if Geometry2D.is_point_in_polygon(point,shore):
				line.append(_screen(point))
		if line.size()>1:
			draw_polyline(line,Color(0.33,0.43,0.30,0.18),1,false)
	var river: Array = Geography.stream(offset)
	_path(river,Vector2.ZERO,4 if not mini else 3,Color("679c9b"))
	for row in range(7):
		for column in range(9):
			var point := offset+Vector2(170+column*255+sin(row*3.1+column)*45,130+row*215+cos(column*1.9+row)*40)
			if not Geometry2D.is_point_in_polygon(point,shore) or not Geometry2D.is_point_in_polygon(point,forest_area) or _near_road(point):
				continue
			var at := _screen(point)
			if not Rect2(Vector2.ZERO,size).grow(8).has_point(at):
				continue
			var crown := 2.5 if mini else clampf(3.5*sqrt(zoom),3.5,6)
			draw_line(at,at+Vector2(0,crown),Color("657658"),1)
			for leaf in [Vector2(-0.4,0),Vector2(0.4,0),Vector2(0,-0.45)]:
				draw_circle(at+leaf*crown,crown*0.65,Color("6c855e"))
	for building in world.get("hub",{}).get("foreground",[]):
		var roof := PackedVector2Array()
		for point in building.get("polygon",[]):
			roof.append(Vector2(float(point[0]),float(point[1])))
		_draw_land_polygon(roof,Color("a1815c"))
		var rim := _outline_on_screen(roof)
		if rim.size()>2:
			rim.append(rim[0])
			draw_polyline(rim,Color("6d6146"),1,false)
	for path in world.get("hub",{}).get("paths",[]):
		_path(path,Vector2.ZERO,2 if mini else 3,Color("eee0b5"))
	for path in world.get("forest",{}).get("walkablePaths",[]):
		_path(path,offset,1.5 if mini else 2,Color("e4d3a3"))
	if not mini:
		_map_caption("BANDAR HUJUNG",Vector2(1040,1080),Color("554e36"))
		_map_caption("HUTAN WRINGIN",offset+Vector2(780,550),Color("405a40"))
		_map_caption("PALUNG SMARA",Vector2(2690,1050),Color("9bb5ac"))
		draw_string(PIXEL_FONT,Vector2(size.x-19,20),"N",HORIZONTAL_ALIGNMENT_LEFT,-1,10,PAPER)
		draw_line(Vector2(size.x-16,27),Vector2(size.x-16,39),PAPER,1)

func _draw_component_geography() -> void:
	var palette := {"grass":"83916d","dirt":"c7ad80","sand":"d1c298","stone":"96917d","dock":"9f8058","bridge":"a38b61","wood":"9f8058"}
	for place in ["hub","forest"]:
		var offset := Vector2.ZERO if place=="hub" else _forest_offset()
		var data: Dictionary = world.get("landMaps",{}).get(place,{})
		var surfaces: Array = data.get("surfaces",[]).duplicate()
		surfaces.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return int(a.get("priority",0))<int(b.get("priority",0)))
		for surface in surfaces:
			var local := PackedVector2Array()
			for vertex in surface.get("polygon",[]): local.append(Vector2(float(vertex[0]),float(vertex[1])))
			var pieces: Array[PackedVector2Array] = [local]
			if not bool(surface.get("walkable",true)):
				pieces.clear()
				for ground in surfaces:
					if not bool(ground.get("walkable",true)): continue
					var boundary := PackedVector2Array()
					for vertex in ground.get("polygon",[]): boundary.append(Vector2(float(vertex[0]),float(vertex[1])))
					pieces.append_array(Geometry2D.intersect_polygons(local,boundary))
			for piece in pieces:
				var points := PackedVector2Array()
				for point in piece: points.append(point+offset)
				_draw_land_polygon(points,Color(palette.get(str(surface.get("material","grass")),"83916d")))
				if bool(surface.get("walkable",true)) and points.size()>2:
					var rim := _outline_on_screen(points)
					rim.append(rim[0])
					draw_polyline(rim,Color("637960") if place=="forest" else Color("8c805f"),1,false)
		for obstacle in data.get("obstacles",[]):
			var points := PackedVector2Array()
			for vertex in obstacle.get("footprint",[]): points.append(Vector2(float(vertex[0]),float(vertex[1]))+offset)
			var kind := str(obstacle.get("kind","rock"))
			_draw_land_polygon(points,Color("4e7156") if kind=="tree" else Color("8d7457") if kind=="house" else Color("766f60"))
			if kind=="tree":
				var center := _screen(offset+Vector2(float(obstacle.x)+float(obstacle.width)*0.5,float(obstacle.y)+float(obstacle.height)*0.5))
				draw_circle(center,3 if mini else 4,Color("5d7d5a"))
	if not mini:
		_map_caption("BANDAR HUJUNG",Vector2(1000,1050),Color("554e36"))
		_map_caption("HUTAN WRINGIN",_forest_offset()+Vector2(750,550),Color("405a40"))
		_map_caption("PALUNG SMARA",Vector2(2650,1050),Color("9bb5ac"))

func _map_caption(title: String, point: Vector2, color: Color) -> void:
	var at := _screen(point)
	if Rect2(Vector2(5,15),size-Vector2(10,25)).has_point(at):
		draw_string(PIXEL_FONT,at,title,HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)

func _draw() -> void:
	if world.is_empty(): return
	draw_rect(Rect2(Vector2.ZERO,size),SEA)
	if area == "sea":
		_image("ocean-depth-background",Rect2(0,0,6144,3584),Color(0.45,0.65,0.7,1))
		var contours: Array = world.get("terrainContours",[])
		if not contours.is_empty():
			for contour in contours:
				var outline := PackedVector2Array()
				for point in contour: outline.append(_screen(Vector2(float(point[0]),float(point[1]))))
				draw_colored_polygon(outline,Color("87978b"))
		else:
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
		_draw_land_geography()

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
	if not mini and has_focus():
		draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),Color("302d2a"),false,5)
		draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),Color("f3c677"),false,2)
	if mini: draw_string(PIXEL_FONT,Vector2(size.x-14,13),"m" if area=="sea" else "N",HORIZONTAL_ALIGNMENT_LEFT,-1,9,PAPER)

func _gui_input(event: InputEvent) -> void:
	if mini: return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT: pan.x -= _source().size.x*.08
			KEY_RIGHT: pan.x += _source().size.x*.08
			KEY_UP: pan.y -= _source().size.y*.08
			KEY_DOWN: pan.y += _source().size.y*.08
			KEY_PLUS,KEY_EQUAL,KEY_KP_ADD: zoom = minf(4,zoom*1.2)
			KEY_MINUS,KEY_KP_SUBTRACT: zoom = maxf(1,zoom/1.2)
			KEY_HOME:
				zoom = 1
				pan = Vector2.ZERO
			KEY_PAGEDOWN,KEY_PAGEUP:
				if not places.is_empty():
					var index := places.find(selected)
					selected = places[posmod(index+(1 if event.keycode==KEY_PAGEDOWN else -1),places.size())]
					pan += Vector2(selected.point)-_source().get_center()
					place_selected.emit(selected)
			_: return
		queue_redraw()
		accept_event()
	elif event is InputEventMouseButton:
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
