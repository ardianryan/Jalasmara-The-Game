extends Node2D

var _area := "hub"
var _extent := Vector2(2400,1600)
var _paths: Array = []
var _half_width := 130.0
var _camera := Vector2(1200,800)
var _anchor := Vector2(1200,800)
var _texture: Texture2D
var _far: Node2D
var _near: Node2D
var _decor: Array[Dictionary] = []

func configure(area: String, extent: Vector2, paths: Array, half_width: float) -> void:
	_area = area
	_extent = extent
	_paths = paths
	_half_width = half_width
	_anchor = extent/2
	if is_inside_tree(): _build()

func _ready() -> void:
	_build()

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_decor.clear()
	if not ResourceLoader.exists("res://resources/art/forest-muara.png"): return
	_texture = load("res://resources/art/forest-muara.png")
	_far = Node2D.new()
	_near = Node2D.new()
	_near.z_index = 30
	add_child(_far)
	add_child(_near)
	var far_points := [Vector2(100,70),Vector2(_extent.x*0.28,55),Vector2(_extent.x*0.53,70),Vector2(_extent.x*0.79,60),Vector2(_extent.x-65,370),Vector2(60,_extent.y*0.48),Vector2(_extent.x-45,_extent.y*0.71),Vector2(80,_extent.y-85)]
	var near_points := [Vector2(65,160),Vector2(_extent.x*0.36,45),Vector2(_extent.x-55,160),Vector2(35,_extent.y*0.60),Vector2(_extent.x-35,_extent.y*0.58),Vector2(65,_extent.y-65),Vector2(_extent.x*0.35,_extent.y-35),Vector2(_extent.x*0.75,_extent.y-30)]
	for i in range(far_points.size()):
		if _clear_of_paths(far_points[i],180): _add_canopy(_far,far_points[i],i%2,1.0,true)
	for i in range(near_points.size()):
		if _clear_of_paths(near_points[i],220): _add_canopy(_near,near_points[i],i%2,0.78,false)
	update_camera(_camera)

func _clear_of_paths(point: Vector2, clearance: float) -> bool:
	for path in _paths:
		for i in range(path.size()-1):
			var a := Vector2(float(path[i][0]),float(path[i][1]))
			var b := Vector2(float(path[i+1][0]),float(path[i+1][1]))
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))<_half_width+clearance:
				return false
	return true

func _add_canopy(parent: Node2D, at: Vector2, variant: int, size_scale: float, far: bool) -> void:
	var source := [Vector2(0,0),Vector2(280,0),Vector2(265,50),Vector2(228,87),Vector2(180,115),Vector2(145,152),Vector2(85,185),Vector2(0,205)] if variant==0 else [Vector2(1240,850),Vector2(1320,780),Vector2(1430,775),Vector2(1510,835),Vector2(1535,900),Vector2(1535,1023),Vector2(1280,1023),Vector2(1225,960)]
	var center := Vector2(125,95) if variant==0 else Vector2(1380,905)
	var polygon := Polygon2D.new()
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in source:
		vertices.append((point-center)*size_scale)
		uv.append(point/Vector2(1536,1024)*_texture.get_size())
	polygon.polygon = vertices
	polygon.uv = uv
	polygon.texture = _texture
	polygon.position = at
	polygon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	polygon.modulate = Color(0.48,0.65,0.67,0.35) if far else Color(1.0,0.97,0.87,0.96)
	parent.add_child(polygon)
	_decor.append({"node":polygon,"at":at,"far":far})

func update_camera(point: Vector2) -> void:
	_camera = point
	var difference := point-_anchor
	if is_instance_valid(_far): _far.position = (difference*0.02).clamp(Vector2(-24,-18),Vector2(24,18)).round()
	if is_instance_valid(_near): _near.position = (difference*-0.035).clamp(Vector2(-30,-22),Vector2(30,22)).round()
	var view := Rect2(point-Vector2(720,460),Vector2(1440,920))
	for entry in _decor:
		var node: Polygon2D = entry.node
		node.visible = view.has_point(entry.at)
	queue_redraw()

func _draw() -> void:
	var origin := _camera-Vector2(650,390)
	for i in range(8):
		var alpha := (1.0-float(i)/8.0)*0.026
		draw_rect(Rect2(origin+Vector2(0,i*44),Vector2(1300,45)),Color(0.51,0.66,0.68,alpha))
