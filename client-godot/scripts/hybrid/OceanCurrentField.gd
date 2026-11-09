extends RefCounted

const CELL_SIZE := 192.0
const REEF_REACH := 110.0
var _edges: Array[Dictionary] = []
var _cells: Dictionary = {}
var _bounds: Array[Rect2] = []
var _contours: Array[PackedVector2Array] = []
var queries := 0
var tested_edges := 0

func configure(contours: Array[PackedVector2Array]) -> void:
	_edges.clear()
	_cells.clear()
	_bounds.clear()
	_contours=contours.duplicate()
	for polygon in _contours:
		var bounds:=Rect2(polygon[0],Vector2.ZERO)
		for point in polygon: bounds=bounds.expand(point)
		_bounds.append(bounds)
		for index in range(polygon.size()):
			var a:=polygon[index]
			var b:=polygon[(index+1)%polygon.size()]
			if a.distance_squared_to(b)<.01: continue
			var id:=_edges.size()
			_edges.append({"a":a,"b":b})
			var extent:=Rect2(a,Vector2.ZERO).expand(b).grow(REEF_REACH)
			for y in range(floori(extent.position.y/CELL_SIZE),floori(extent.end.y/CELL_SIZE)+1):
				for x in range(floori(extent.position.x/CELL_SIZE),floori(extent.end.x/CELL_SIZE)+1):
					var key:=Vector2i(x,y)
					if not _cells.has(key): _cells[key]=[]
					_cells[key].append(id)

func solid(point: Vector2) -> bool:
	for index in range(_contours.size()):
		if _bounds[index].grow(.01).has_point(point) and Geometry2D.is_point_in_polygon(point,_contours[index]): return true
	return false

func sample(point: Vector2, ambient: Vector2) -> Vector2:
	queries+=1
	var speed:=minf(ambient.length(),24.0)
	if speed<.001: return Vector2.ZERO
	var best:=REEF_REACH*REEF_REACH
	var normal:=Vector2.ZERO
	var ids: Array=_cells.get(Vector2i(floori(point.x/CELL_SIZE),floori(point.y/CELL_SIZE)),[])
	for id in ids:
		tested_edges+=1
		var edge: Dictionary=_edges[id]
		var nearest:=Geometry2D.get_closest_point_to_segment(point,edge.a,edge.b)
		var offset:=point-nearest
		var distance:=offset.length_squared()
		if distance<best and distance>.0001:
			best=distance
			normal=offset.normalized()
	var flow:=ambient.normalized()*speed
	if normal==Vector2.ZERO: return flow
	var toward:=flow.dot(normal)
	if toward>=0: return flow
	var tangent:=Vector2(-normal.y,normal.x)
	if tangent.dot(flow)<0: tangent=-tangent
	var blend:=1.0-smoothstep(8.0,REEF_REACH,sqrt(best))
	return flow.lerp(tangent*speed,blend).limit_length(speed)

func trace(origin: Vector2, movement: Vector2) -> Vector2:
	if movement.length_squared()<.000001: return origin
	var target:=origin+movement
	var nearest:=target
	var distance:=movement.length_squared()
	var candidates: Dictionary={}
	var extent:=Rect2(origin,Vector2.ZERO).expand(target)
	for y in range(floori(extent.position.y/CELL_SIZE),floori(extent.end.y/CELL_SIZE)+1):
		for x in range(floori(extent.position.x/CELL_SIZE),floori(extent.end.x/CELL_SIZE)+1):
			for id in _cells.get(Vector2i(x,y),[]): candidates[id]=true
	for id in candidates:
		var edge: Dictionary=_edges[id]
		var hit: Variant=Geometry2D.segment_intersects_segment(origin,target,edge.a,edge.b)
		if hit is Vector2 and origin.distance_squared_to(hit)<distance:
			distance=origin.distance_squared_to(hit)
			nearest=hit-movement.normalized()*.75
	return origin if solid(nearest) else nearest

func debug_status() -> Dictionary:
	return {"edges":_edges.size(),"cells":_cells.size(),"influence":REEF_REACH,"queries":queries,"testedEdges":tested_edges,"maximumSpeed":24.0,"changesPhysics":false}
