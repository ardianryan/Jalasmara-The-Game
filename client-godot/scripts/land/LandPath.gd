extends RefCounted

var _points: Array[Dictionary] = []
var _last := Vector2.ZERO
var _direction := Vector2.ZERO
var _ready := false
var _serial := 0

func reset(point: Vector2) -> void:
	_points.clear()
	_last = point
	_direction = Vector2.ZERO
	_ready = true

func record(point: Vector2) -> void:
	if not _ready:
		reset(point)
		return
	var direction := (point-_last).normalized()
	if point.distance_to(_last)<0.5: return
	if _direction!=Vector2.ZERO and direction.dot(_direction)<0.9:
		_append(_last)
	if _points.is_empty() or point.distance_to(Vector2(float(_points[-1].x),float(_points[-1].y)))>=6:
		_append(point)
	_last = point
	_direction = direction

func _append(point: Vector2) -> void:
	if _points.size()>=62: return
	if not _points.is_empty() and point.distance_to(Vector2(float(_points[-1].x),float(_points[-1].y)))<0.5: return
	_serial += 1
	_points.append({"x":point.x,"y":point.y,"serial":_serial})

func snapshot(point: Vector2) -> Dictionary:
	var path: Array[Dictionary] = []
	for value in _points: path.append({"x":value.x,"y":value.y})
	path.append({"x":point.x,"y":point.y})
	return {"path":path,"ticket":_serial}

func acknowledge(ticket: int) -> void:
	while not _points.is_empty() and int(_points[0].serial)<=ticket: _points.pop_front()

func needs_flush() -> bool:
	return _points.size()>=40

func full() -> bool:
	return _points.size()>=62

func size() -> int:
	return _points.size()
