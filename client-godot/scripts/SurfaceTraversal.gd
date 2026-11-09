extends RefCounted

const LEVEL_HEIGHT := 48.0
var _hub: Dictionary = {}
var _connectors: Array[Dictionary] = []
var _last: Dictionary = {}
var _elevation := -1.0
var _previous := Vector2.INF
var _reduced_motion := false

func configure(hub: Dictionary) -> void:
	_hub = hub
	_last = {}
	_elevation = -1
	_previous = Vector2.INF
	_connectors.clear()
	for stair in hub.get("stairs",[]):
		if stair.get("path",[]).size()<2: continue
		_connectors.append(connector_profile(stair,_floor_elevation(str(stair.from))*LEVEL_HEIGHT,_floor_elevation(str(stair.to))*LEVEL_HEIGHT))

static func connector_profile(stair: Dictionary,from_height: float,to_height: float) -> Dictionary:
	var path: Array=stair.get("path",[])
	assert(path.size()>=2)
	var start:=Vector2(float(path[0][0]),float(path[0][1]))
	var end:=Vector2(float(path[1][0]),float(path[1][1]))
	return {"id":str(stair.get("id","")),"type":str(stair.get("type","stairs")),"start":start,"end":end,"lengthSquared":maxf(1,(end-start).length_squared()),"width":float(stair.get("width",90))*.5,"from":from_height,"to":to_height,"steps":maxi(1,int(stair.get("steps",4))),"material":str(stair.get("material","stone")),"fromId":str(stair.get("from","")),"toId":str(stair.get("to",""))}

static func connector_ground(profile: Dictionary,feet: Vector2) -> Dictionary:
	var start: Vector2=profile.start
	var end: Vector2=profile.end
	var progress: float=(feet-start).dot(end-start)/float(profile.lengthSquared)
	if progress<0 or progress>1 or feet.distance_to(Geometry2D.get_closest_point_to_segment(feet,start,end))>float(profile.width): return {}
	var count:=maxi(1,int(profile.steps))
	var step_index:=clampi(floori(progress*count),0,count-1)
	var stairs:=str(profile.type)=="stairs"
	var height:=lerpf(float(profile.from),float(profile.to),float(step_index+1)/count if stairs else progress)
	return {"connectorId":str(profile.id),"type":str(profile.type),"onStairs":stairs,"progress":progress,"stepIndex":step_index,"stepProgress":clampf(progress*count-step_index,0,1),"groundHeight":height,"riserHeight":(float(profile.to)-float(profile.from))/count if stairs else 0.0,"treadLength":start.distance_to(end)/count if stairs else start.distance_to(end)}

func set_reduced_motion(value: bool) -> void:
	_reduced_motion = value

func sample(feet: Vector2, velocity := Vector2.ZERO, _delta := 0.0, paused := false) -> Dictionary:
	if paused and not _last.is_empty() and feet.is_equal_approx(_previous):
		var held:=_last.duplicate()
		held["paused"]=true
		return held
	if _elevation < 0 or (_previous.is_finite() and feet.distance_to(_previous)>240):
		_elevation = _floor_at_point(feet)
	_previous = feet
	var closest: Dictionary = {}
	var nearest := INF
	var ground: Dictionary = {}
	for stair in _connectors:
		var candidate:=connector_ground(stair,feet)
		if candidate.is_empty(): continue
		var point := Geometry2D.get_closest_point_to_segment(feet,stair.start,stair.end)
		var distance := feet.distance_to(point)
		if distance>=nearest: continue
		nearest = distance
		closest = stair
		ground = candidate
	var progress:=float(ground.get("progress",0))
	var moving := velocity.length()>4
	var direction := "idle"
	var foot_bob := 0.0
	var pace := 1.0
	var on_stairs := false
	var step_index := -1
	if not closest.is_empty():
		var tangent: Vector2=(closest.end-closest.start).normalized()
		var along := velocity.dot(tangent)
		var vertical_direction:=along*signf(float(closest.to)-float(closest.from))
		direction = "up" if vertical_direction>4 else "down" if vertical_direction< -4 else "idle"
		on_stairs = bool(ground.onStairs)
		_elevation = float(ground.groundHeight)/LEVEL_HEIGHT
		step_index = int(ground.stepIndex)
		if moving and absf(along)>4:
			pace = (0.80 if direction=="up" else 0.88) if on_stairs else 0.96
			if on_stairs and not _reduced_motion:
				foot_bob = -sin(float(ground.stepProgress)*PI)*1.6
	else:
		_elevation = _floor_at_point(feet)
	var material := str(closest.get("material","stone")) if not closest.is_empty() else str(_surface_at(feet).get("material","grass"))
	_last = {
		"onStairs":on_stairs,"onConnector":not closest.is_empty(),
		"connectorId":str(closest.get("id","")),"type":str(closest.get("type","ground")),
		"from":str(closest.get("fromId","")),"to":str(closest.get("toId","")),
		"progress":progress,"elevation":_elevation,"floor":_floor_name(_elevation),
		"paceScale":pace,"footBob":foot_bob,"footstepMaterial":material,
		"direction":direction,"steps":int(closest.get("steps",0)),"stepIndex":step_index,
		"groundHeight":_elevation*LEVEL_HEIGHT,"bodyLift":-foot_bob,
		"stepProgress":float(ground.get("stepProgress",0)),"riserHeight":float(ground.get("riserHeight",0)),"treadLength":float(ground.get("treadLength",0)),
		"paused":paused,
	}
	return _last.duplicate()

func _surface_at(point: Vector2) -> Dictionary:
	var selected: Dictionary = {}
	for surface in _hub.get("surfaces",[]):
		var polygon := PackedVector2Array()
		for vertex in surface.get("polygon",[]): polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
		if Geometry2D.is_point_in_polygon(point,polygon) and (selected.is_empty() or int(surface.get("priority",0))>=int(selected.get("priority",0))): selected = surface
	return selected

func _floor_at_point(point: Vector2) -> float:
	var surface := _surface_at(point)
	return float(surface.get("elevation",0)) if not surface.is_empty() else _floor_at(point.y)

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
