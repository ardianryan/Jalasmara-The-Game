extends Node2D

var camera_point := Vector2(1120,1230)
var gardens_restored := false
var solved: Array = []
var _config: Dictionary = {}
var _extent := Vector2(2400,1600)
var _background: Texture2D
var _geometry: Node2D
var _foreground: Array[Polygon2D] = []
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

func add_foreground_to(actors: Node2D) -> void:
	_foreground_host = actors
	for node in _foreground:
		if is_instance_valid(node): node.queue_free()
	_foreground.clear()
	if _background == null or not is_instance_valid(actors): return
	for entry in _config.get("foreground",[]):
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

func _exit_tree() -> void:
	for node in _foreground:
		if is_instance_valid(node): node.queue_free()
	_foreground.clear()

func _draw() -> void:
	if _background != null:
		draw_texture_rect(_background,Rect2(Vector2.ZERO,_extent),false)
