extends RefCounted

var _hub: Dictionary = {}
var _last: Dictionary = {}
var _elevation := -1.0
var _previous := Vector2.INF
var _reduced_motion := false

func configure(hub: Dictionary) -> void:
	_hub = hub
	_last = {}
	_elevation = -1
	_previous = Vector2.INF

func set_reduced_motion(value: bool) -> void:
	_reduced_motion = value

func sample(feet: Vector2, velocity := Vector2.ZERO, _delta := 0.0) -> Dictionary:
	if _elevation < 0 or (_previous.is_finite() and feet.distance_to(_previous)>240):
		_elevation = _floor_at(feet.y)
	_previous = feet
	var closest: Dictionary = {}
	var nearest := INF
	var progress := 0.0
	for stair in _hub.get("stairs",[]):
		var path: Array = stair.get("path",[])
		if path.size()<2: continue
		var lower := Vector2(float(path[0][0]),float(path[0][1]))
		var upper := Vector2(float(path[1][0]),float(path[1][1]))
		var along_progress := (feet-lower).dot(upper-lower)/maxf(1,(upper-lower).length_squared())
		if along_progress< -0.04 or along_progress>1.04: continue
		var point := Geometry2D.get_closest_point_to_segment(feet,lower,upper)
		var distance := feet.distance_to(point)
		if distance>float(stair.get("width",90))*0.5 or distance>=nearest: continue
		nearest = distance
		closest = stair
		progress = clampf((feet-lower).dot(upper-lower)/maxf(1,(upper-lower).length_squared()),0,1)
	var moving := velocity.length()>4
	var direction := "idle"
	var foot_bob := 0.0
	var pace := 1.0
	var on_stairs := false
	var step_index := -1
	if not closest.is_empty():
		var path: Array = closest.path
		var tangent := Vector2(float(path[1][0])-float(path[0][0]),float(path[1][1])-float(path[0][1])).normalized()
		var along := velocity.dot(tangent)
		direction = "up" if along>4 else "down" if along< -4 else "idle"
		on_stairs = str(closest.get("type","stairs"))=="stairs"
		var lower_elevation := _floor_elevation(str(closest.from))
		var upper_elevation := _floor_elevation(str(closest.to))
		_elevation = lerpf(lower_elevation,upper_elevation,progress)
		var count := maxi(1,int(closest.get("steps",4)))
		step_index = clampi(floori(progress*count),0,count-1)
		if moving and absf(along)>4:
			pace = (0.80 if direction=="up" else 0.88) if on_stairs else 0.96
			if on_stairs and not _reduced_motion:
				foot_bob = -absf(sin(progress*float(count)*PI))*1.6
	elif not _last.is_empty() and bool(_last.get("onConnector",false)):
		_elevation = roundf(_elevation)
	var material := str(closest.get("material","stone")) if not closest.is_empty() else "wood" if feet.y>1090 else "grass"
	_last = {
		"onStairs":on_stairs,"onConnector":not closest.is_empty(),
		"connectorId":str(closest.get("id","")),"type":str(closest.get("type","ground")),
		"from":str(closest.get("from","")),"to":str(closest.get("to","")),
		"progress":progress,"elevation":_elevation,"floor":_floor_name(_elevation),
		"paceScale":pace,"footBob":foot_bob,"footstepMaterial":material,
		"direction":direction,"steps":int(closest.get("steps",0)),"stepIndex":step_index,
	}
	return _last.duplicate()

func _floor_at(y: float) -> float:
	for terrace in _hub.get("terraces",[]):
		if y>=float(terrace.get("minY",0)) and y<float(terrace.get("maxY",0)):
			return float(terrace.get("elevation",0))
	return 0.0

func _floor_elevation(id: String) -> float:
	for terrace in _hub.get("terraces",[]):
		if str(terrace.get("id",""))==id:
			return float(terrace.get("elevation",0))
	return 0.0

func _floor_name(value: float) -> String:
	for terrace in _hub.get("terraces",[]):
		if int(terrace.get("elevation",0))==roundi(value):
			return str(terrace.get("id","ground"))
	return "ground"

func debug_status() -> Dictionary:
	return _last.duplicate()
