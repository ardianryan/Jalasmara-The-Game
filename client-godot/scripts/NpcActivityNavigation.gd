extends RefCounted

var _walkable := Callable()
var _graph := AStar2D.new()
var _ids: Dictionary = {}
var _next_id := 0

func configure(paths: Array,can_walk: Callable) -> void:
	_walkable=can_walk
	_graph.clear()
	_ids.clear()
	_next_id=0
	for path in paths:
		for index in range(1,path.size()):
			var a:=_point(path[index-1])
			var b:=_point(path[index])
			var steps:=maxi(1,ceili(a.distance_to(b)/40.0))
			var previous:=-1
			for step in range(steps+1):
				var point:=a.lerp(b,float(step)/steps)
				if not _clear(point): previous=-1; continue
				var id:=_node(point)
				if previous>=0 and previous!=id and segment_clear(_graph.get_point_position(previous),point): _graph.connect_points(previous,id)
				previous=id

func _point(value: Variant) -> Vector2:
	return value if value is Vector2 else Vector2(float(value[0]),float(value[1]))

func _clear(point: Vector2) -> bool:
	return not _walkable.is_valid() or bool(_walkable.call(point))

func segment_clear(a: Vector2,b: Vector2) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)/5.0))
	for step in range(steps+1):
		if not _clear(a.lerp(b,float(step)/steps)): return false
	return true

func _node(point: Vector2) -> int:
	var key:="%.2f,%.2f" % [point.x,point.y]
	if _ids.has(key): return int(_ids[key])
	var id:=_next_id
	_next_id+=1
	_ids[key]=id
	_graph.add_point(id,point)
	return id

func path_between(origin: Vector2,destination: Vector2) -> PackedVector2Array:
	if origin.distance_to(destination)<1: return PackedVector2Array([destination])
	if not _clear(origin) or not _clear(destination): return PackedVector2Array()
	var original:=_graph.get_point_ids()
	var start:=_next_id+1
	var finish:=_next_id+2
	_graph.add_point(start,origin)
	_graph.add_point(finish,destination)
	for temporary in [start,finish]:
		var at:=_graph.get_point_position(temporary)
		var candidates: Array[int]=[]
		for id in original: candidates.append(id)
		candidates.sort_custom(func(a:int,b:int)->bool:return at.distance_squared_to(_graph.get_point_position(a))<at.distance_squared_to(_graph.get_point_position(b)))
		var connected:=0
		for id in candidates:
			if segment_clear(at,_graph.get_point_position(id)):
				_graph.connect_points(temporary,id)
				connected+=1
				if connected>=3: break
	var result:=_graph.get_point_path(start,finish)
	_graph.remove_point(start)
	_graph.remove_point(finish)
	return result

func debug_status() -> Dictionary:
	return {"nodes":_graph.get_point_count(),"source":"authored village commute and hub routes","sampleStep":5}
