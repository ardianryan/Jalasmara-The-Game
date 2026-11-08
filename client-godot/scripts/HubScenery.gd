extends Node2D

var camera_point := Vector2(1120,1230)
var gardens_restored := false
var solved: Array = []
var _config: Dictionary = {}
var _extent := Vector2(2400,1600)
var _background: Texture2D
var _geometry: Node2D
var _foreground: Array[Node2D] = []
var _trees: Array[Node2D] = []
var _land_rock: Node2D
var _surface_water: Node2D
var _depth_planes: Node2D
var _foreground_host: Node2D

func configure(hub: Dictionary) -> void:
	_config = hub.duplicate(true)
	_extent = Vector2(float(hub.get("width",2400)),float(hub.get("height",1600)))
	if is_inside_tree():
		_build_geometry()
		if is_instance_valid(_depth_planes): _depth_planes.configure("hub",_extent,_config.get("paths",[]),float(_config.get("walkableHalfWidth",130)))
		if is_instance_valid(_foreground_host): add_foreground_to(_foreground_host)
		queue_redraw()

func _ready() -> void:
	if _config.is_empty():
		configure(GameState.world.get("hub",{}))
	for path in ["res://resources/art/coastal-village-map.png","res://resources/art/bandar-hujung-map.png"]:
		if ResourceLoader.exists(path):
			_background = load(path)
			break
	_build_geometry()
	_depth_planes = preload("res://scripts/DepthPlanes.gd").new()
	_depth_planes.configure("hub",_extent,_config.get("paths",[]),float(_config.get("walkableHalfWidth",130)))
	add_child(_depth_planes)
	if is_instance_valid(_foreground_host): add_foreground_to(_foreground_host)
	_add_polyfork_plants()
	_surface_water = preload("res://scripts/SurfaceWater.gd").new()
	add_child(_surface_water)
	_surface_water.configure("hub",_extent,_background)
	var pixel_effects := preload("res://scripts/PixelEffects.gd").new()
	pixel_effects.name = "PixelEffects"
	add_child(pixel_effects)
	pixel_effects.configure("hub")
	queue_redraw()

func _add_polyfork_plants() -> void:
	for item in [["bamboo-stalk",Vector2(1600,640),Vector2(64,96)],["fern-plant",Vector2(1610,915),Vector2(64,64)]]:
		var path := "res://resources/art/polyfork/%s.png" % item[0]
		if not ResourceLoader.exists(path): continue
		var plant := Sprite2D.new()
		plant.texture = load(path)
		plant.position = item[1]
		plant.centered = false
		plant.offset = Vector2(-plant.texture.get_width()/2.0,-plant.texture.get_height())
		plant.scale = item[2]/plant.texture.get_size()
		plant.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(plant)

func _process(_delta: float) -> void:
	if is_instance_valid(_depth_planes): _depth_planes.update_camera(camera_point)

func _build_geometry() -> void:
	if is_instance_valid(_geometry):
		remove_child(_geometry)
		_geometry.queue_free()
	_geometry = Node2D.new()
	_geometry.name = "VillageGeometry"
	add_child(_geometry)
	for entry in _config.get("obstacles",[]):
		var rect := _rect(entry)
		if rect.size.x<=0 or rect.size.y<=0: continue
		var body := StaticBody2D.new()
		body.position = rect.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		body.add_child(collision)
		_geometry.add_child(body)
		var occluder := LightOccluder2D.new()
		occluder.position = rect.position
		var occlusion := OccluderPolygon2D.new()
		occlusion.polygon = PackedVector2Array([Vector2.ZERO,Vector2(rect.size.x,0),rect.size,Vector2(0,rect.size.y)])
		occluder.occluder = occlusion
		_geometry.add_child(occluder)
	for trunk in _config.get("treeTrunks",[]):
		var body := StaticBody2D.new()
		body.position = Vector2(float(trunk.x),float(trunk.y))
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = float(trunk.radius)
		collision.shape = shape
		body.add_child(collision)
		_geometry.add_child(body)
		var occluder := LightOccluder2D.new()
		occluder.position = body.position
		var outline := PackedVector2Array()
		for index in range(12): outline.append(Vector2.from_angle(float(index)*TAU/12.0)*shape.radius)
		var occlusion := OccluderPolygon2D.new()
		occlusion.polygon = outline
		occluder.occluder = occlusion
		_geometry.add_child(occluder)

func _rect(value: Variant) -> Rect2:
	if value is Array and value.size()>=4:
		return Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3]))
	if value is Dictionary:
		return Rect2(float(value.get("x",0)),float(value.get("y",0)),float(value.get("width",0)),float(value.get("height",0)))
	return Rect2()

func is_walkable(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO,_extent).has_point(point): return false
	for obstacle in _config.get("obstacles",[]):
		if _rect(obstacle).grow(12).has_point(point): return false
	for trunk in _config.get("treeTrunks",[]):
		if point.distance_to(Vector2(float(trunk.x),float(trunk.y)))<float(trunk.radius)+12.0: return false
	for area in _config.get("walkableAreas",[]):
		var polygon := PackedVector2Array()
		for vertex in area: polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	var paths: Array = _config.get("paths",[])
	if paths.is_empty(): return true
	var half_width := float(_config.get("walkableHalfWidth",130))
	for path in paths:
		for index in range(path.size()-1):
			var first: Variant = path[index]
			var second: Variant = path[index+1]
			var a := Vector2(float(first[0]),float(first[1]))
			var b := Vector2(float(second[0]),float(second[1]))
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))<=half_width:
				return true
	return false

func nearest_walkable(point: Vector2) -> Vector2:
	if is_walkable(point): return point
	for radius in range(8,193,8):
		for index in range(24):
			var candidate := point + Vector2.from_angle(float(index)*TAU/24.0)*radius
			if is_walkable(candidate): return candidate
	return point

func add_foreground_to(actors: Node2D) -> void:
	_foreground_host = actors
	for node in _foreground:
		if is_instance_valid(node): node.queue_free()
	_foreground.clear()
	_trees.clear()
	if _background == null or not is_instance_valid(actors): return
	var entries: Array = _config.get("foreground",[])
	for entry_index in range(mini(3,entries.size())):
		var entry: Dictionary = entries[entry_index]
		var points: Array = entry.get("polygon",[])
		if points.size()<3: continue
		var base: Array = entry.get("base",[0,0])
		var anchor := Vector2(float(base[0]),float(base[1]))
		var polygon := Polygon2D.new()
		polygon.position = anchor
		var vertices := PackedVector2Array()
		var uv := PackedVector2Array()
		for point in points:
			var world_point := Vector2(float(point[0]),float(point[1]))
			vertices.append(world_point-anchor)
			uv.append(world_point/_extent*_background.get_size())
		polygon.polygon = vertices
		polygon.uv = uv
		polygon.texture = _background
		actors.add_child(polygon)
		_foreground.append(polygon)
	_add_trees(actors)
	var rock := preload("res://scripts/LandRockVisual.gd").new()
	if rock.configure(Vector2(790,850),Vector2(65,46),Rect2(740,675,250,205),0.45):
		actors.add_child(rock)
		_foreground.append(rock)
		_land_rock = rock

func _add_trees(actors: Node2D) -> void:
	var focus: Node2D
	for actor in actors.get_children():
		if actor is CharacterBody2D:
			focus = actor
			break
	var scale_factor := _extent.x / float(_background.get_width())
	# Coordinates follow the painted crown and wood, while sorting uses the root on the ground.
	var trees := [
		{"base":Vector2(570,566),"crown":[Vector2(475,367),Vector2(486,342),Vector2(540,322),Vector2(580,330),Vector2(605,317),Vector2(645,341),Vector2(679,377),Vector2(653,414),Vector2(605,403),Vector2(578,432),Vector2(550,420),Vector2(510,436),Vector2(472,411)],"wood":[Vector2(571,393),Vector2(591,398),Vector2(582,467),Vector2(574,535),Vector2(561,569),Vector2(548,565),Vector2(559,509)]},
		{"base":Vector2(992,786),"crown":[Vector2(871,603),Vector2(902,569),Vector2(953,564),Vector2(986,585),Vector2(1022,569),Vector2(1073,598),Vector2(1090,629),Vector2(1050,652),Vector2(1018,652),Vector2(990,682),Vector2(964,662),Vector2(924,653),Vector2(898,636)],"wood":[Vector2(984,638),Vector2(1001,643),Vector2(1000,701),Vector2(999,751),Vector2(990,788),Vector2(973,788),Vector2(980,727)]},
		{"base":Vector2(552,808),"crown":[Vector2(479,670),Vector2(490,637),Vector2(531,615),Vector2(566,621),Vector2(584,609),Vector2(612,625),Vector2(648,642),Vector2(663,680),Vector2(628,671),Vector2(608,692),Vector2(579,681),Vector2(553,701),Vector2(522,687),Vector2(491,688)],"wood":[Vector2(561,677),Vector2(579,680),Vector2(570,723),Vector2(566,775),Vector2(557,811),Vector2(541,813),Vector2(550,763)]},
		{"base":Vector2(94,694),"crown":[Vector2(1,472),Vector2(15,429),Vector2(65,405),Vector2(112,409),Vector2(148,389),Vector2(196,414),Vector2(230,450),Vector2(239,490),Vector2(204,483),Vector2(164,476),Vector2(128,503),Vector2(82,485),Vector2(48,512),Vector2(5,512)],"wood":[Vector2(100,466),Vector2(120,473),Vector2(113,550),Vector2(100,625),Vector2(91,696),Vector2(73,696),Vector2(82,623)]},
		{"base":Vector2(1346,681),"crown":[Vector2(1232,493),Vector2(1248,463),Vector2(1289,451),Vector2(1330,468),Vector2(1352,451),Vector2(1393,465),Vector2(1430,502),Vector2(1436,542),Vector2(1403,533),Vector2(1373,553),Vector2(1337,540),Vector2(1302,550),Vector2(1269,530),Vector2(1236,539)],"wood":[Vector2(1343,523),Vector2(1364,527),Vector2(1359,584),Vector2(1351,640),Vector2(1341,684),Vector2(1328,685),Vector2(1335,621)]},
		{"base":Vector2(979,223),"crown":[Vector2(868,84),Vector2(897,41),Vector2(946,29),Vector2(984,39),Vector2(1019,15),Vector2(1070,38),Vector2(1100,81),Vector2(1097,114),Vector2(1052,103),Vector2(1002,119),Vector2(960,100),Vector2(924,119),Vector2(884,111)],"wood":[Vector2(979,89),Vector2(999,94),Vector2(992,149),Vector2(981,225),Vector2(962,229),Vector2(971,164)]},
		{"base":Vector2(622,194),"crown":[Vector2(497,45),Vector2(533,11),Vector2(580,0),Vector2(632,13),Vector2(669,0),Vector2(708,17),Vector2(730,65),Vector2(691,75),Vector2(651,65),Vector2(616,87),Vector2(584,72),Vector2(545,91),Vector2(505,74)],"wood":[Vector2(613,66),Vector2(634,70),Vector2(631,135),Vector2(621,196),Vector2(604,198),Vector2(608,135)]},
	]
	for entry in trees:
		var tree := preload("res://scripts/ForestOcclusion.gd").new()
		tree.configure(_background,entry.base,entry.crown,0,scale_factor,entry.wood)
		actors.add_child(tree)
		if is_instance_valid(focus): tree.set_focus(focus)
		_foreground.append(tree)
		_trees.append(tree)

func debug_status() -> Dictionary:
	var trees: Array = []
	for tree in _trees:
		if is_instance_valid(tree): trees.append(tree.debug_status())
	return {"landRock":_land_rock.debug_status() if is_instance_valid(_land_rock) else {},"trees":trees,"sortByFeet":is_instance_valid(_foreground_host) and _foreground_host.y_sort_enabled,"water":_surface_water.debug_status() if is_instance_valid(_surface_water) else {}}

func _exit_tree() -> void:
	for node in _foreground:
		if is_instance_valid(node): node.queue_free()
	_foreground.clear()

func _draw() -> void:
	if _background != null:
		draw_texture_rect(_background,Rect2(Vector2.ZERO,_extent),false)
