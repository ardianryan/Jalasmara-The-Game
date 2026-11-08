extends Node

var actor: Node2D
var area := "hub"
var _previous := Vector2.ZERO
var _distance := 0.0
var _cadence := 0.0
var _breath := 0.0
var _ambience := 0.0
var _step := 0
var _initialized := false
var _was_underwater := false
var _has_traversal := false
var _material := ""
var _last_step := ""
const FOOTSTEPS := {
	"dock":"footstep_dock", "bridge":"footstep_bridge", "sand":"footstep_sand",
	"stone":"footstep_stone", "dirt":"footstep_dirt", "grass":"footstep_grass",
	"wood":"footstep_wood", "water_shallow":"footstep_water_shallow",
}

func configure(player: Node2D, place := "hub") -> void:
	actor = player
	area = place
	_initialized = false
	_cadence = 0
	_ambience = 0
	_has_traversal = false
	for property in actor.get_property_list():
		if str(property.name) == "traversal_state": _has_traversal = true

func material_at(point: Vector2) -> String:
	var maps: Dictionary = GameState.world.get("landMaps",{})
	var map: Dictionary = maps.get(area,{})
	if _has_traversal:
		var traversal: Dictionary = actor.get("traversal_state")
		if bool(traversal.get("onConnector",false)):
			var surface := str(traversal.get("footstepMaterial",""))
			if FOOTSTEPS.has(surface): return surface
	for stair in map.get("stairs",[]):
		var path: Array = stair.get("path",[])
		if path.size()<2: continue
		for index in range(path.size()-1):
			var a := Vector2(float(path[index][0]),float(path[index][1]))
			var b := Vector2(float(path[index+1][0]),float(path[index+1][1]))
			var progress := (point-a).dot(b-a)/maxf(1,(b-a).length_squared())
			if progress>=0 and progress<=1 and point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)) <= float(stair.get("width",90))/2:
				var surface := str(stair.get("material","stone"))
				if FOOTSTEPS.has(surface): return surface
	var selected := ""
	var priority := -INF
	var elevation := -INF
	for surface in map.get("surfaces",[]):
		var polygon := PackedVector2Array()
		for vertex in surface.get("polygon",[]): polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
		if polygon.size()<3 or not Geometry2D.is_point_in_polygon(point,polygon): continue
		var candidate := str(surface.get("material",""))
		var candidate_priority := float(surface.get("priority",0))
		var candidate_elevation := float(surface.get("elevation",0))
		if FOOTSTEPS.has(candidate) and (candidate_priority>priority or (candidate_priority==priority and candidate_elevation>elevation)):
			selected = candidate
			priority = candidate_priority
			elevation = candidate_elevation
	return selected

func _process(delta: float) -> void:
	if not is_instance_valid(actor): return
	var underwater := not GameState.dive.is_empty()
	if not _initialized or underwater!=_was_underwater:
		_previous = actor.position
		_distance = 0
		_breath = 0
		_initialized = true
		_was_underwater = underwater
	var travelled := actor.position.distance_to(_previous)
	_previous = actor.position
	if travelled>80:
		_distance = 0
		return
	_material = "underwater" if underwater else material_at(actor.position)
	if not AudioManager.can_play_environment():
		_distance = 0
		_cadence = 0
		_breath = 0
		_ambience = 0
		return
	_cadence += delta
	_breath += delta
	_ambience += delta
	if underwater:
		if _breath>3.4:
			_breath = 0
			AudioManager.play_sfx("diver_breath",0.97+float(_step%3)*0.025,-18)
		if travelled>0.4 and _cadence>1.6:
			_cadence = 0
			AudioManager.play_sfx("swoosh_water",0.94+float(_step%3)*0.035,-23)
			_step += 1
		if actor.position.y>1900 and _ambience>7.5:
			_ambience = 0
			AudioManager.play_sfx("water_drip",0.88+float(_step%4)*0.04,-22)
	else:
		_distance += travelled
		if _distance>38 and _cadence>0.24:
			_distance = fmod(_distance,38)
			_cadence = 0
			if FOOTSTEPS.has(_material):
				_last_step = FOOTSTEPS[_material]
				AudioManager.play_sfx(_last_step,0.94+float(_step%4)*0.035,-17)
				_step += 1
		if _material in ["dock","bridge"] and _ambience>13:
			_ambience = 0
			AudioManager.play_sfx("rope_creak",0.94,-25)

func debug_status() -> Dictionary:
	return {"steps":_step,"area":area,"underwater":_was_underwater,"material":_material,"lastStep":_last_step}
