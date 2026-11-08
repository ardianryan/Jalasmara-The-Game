extends Node2D

const BODY_RADIUS := 12.0
# One extra pixel keeps six-pixel breadcrumb chords clear of rounded obstacle corners.
const WALK_CLEARANCE := 13.0
var camera_point := Vector2.ZERO
var gardens_restored := false
var solved: Array = []
var config: Dictionary = {}
var _floors: Array[PackedVector2Array] = []
var _blocked: Array[PackedVector2Array] = []

func configure(map: Dictionary) -> void:
	config = map
	_floors.clear()
	_blocked.clear()
	for surface in map.get("surfaces",[]):
		if bool(surface.get("walkable",true)): _floors.append(_polygon(surface.get("polygon",[])))
	for obstacle in map.get("obstacles",[]):
		_blocked.append(_polygon(obstacle.get("footprint",[])))
	if is_inside_tree(): _build_bodies()

func _ready() -> void:
	_build_bodies()

func _polygon(points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points: result.append(Vector2(float(point[0]),float(point[1])))
	return result

func _build_bodies() -> void:
	for child in get_children(): child.queue_free()
	for polygon in _blocked:
		if polygon.size()<3: continue
		var body := StaticBody2D.new()
		var shape := CollisionPolygon2D.new()
		shape.polygon = polygon
		body.add_child(shape)
		add_child(body)

func _on_floor(point: Vector2) -> bool:
	for floor_polygon in _floors:
		if Geometry2D.is_point_in_polygon(point,floor_polygon): return true
	return false

func is_walkable(point: Vector2) -> bool:
	if not _on_floor(point): return false
	for polygon in _blocked:
		if Geometry2D.is_point_in_polygon(point,polygon): return false
		for index in range(polygon.size()):
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,polygon[index],polygon[(index+1)%polygon.size()]))<WALK_CLEARANCE: return false
	for index in range(8):
		if not _on_floor(point+Vector2.from_angle(float(index)*TAU/8.0)*WALK_CLEARANCE): return false
	return true

func nearest_walkable(point: Vector2) -> Vector2:
	if is_walkable(point): return point
	for radius in range(8,401,8):
		for direction in range(32):
			var candidate := point+Vector2.from_angle(float(direction)*TAU/32.0)*radius
			if is_walkable(candidate): return candidate
	var spawn: Dictionary = config.get("spawn",{})
	return Vector2(float(spawn.get("x",1120)),float(spawn.get("y",1230)))

func surface_at(point: Vector2) -> Dictionary:
	var selected: Dictionary = {}
	for surface in config.get("surfaces",[]):
		if Geometry2D.is_point_in_polygon(point,_polygon(surface.get("polygon",[]))):
			if selected.is_empty() or float(surface.get("priority",0))>float(selected.get("priority",0)) or (float(surface.get("priority",0))==float(selected.get("priority",0)) and float(surface.get("elevation",0))>=float(selected.get("elevation",0))): selected = surface
	return selected

func add_foreground_to(_actors: Node2D) -> void:
	pass

func debug_status() -> Dictionary:
	return {"componentMap":true,"floors":_floors.size(),"obstacles":_blocked.size(),"bodyRadius":BODY_RADIUS,"walkClearance":WALK_CLEARANCE,"bitmapFloor":false}
