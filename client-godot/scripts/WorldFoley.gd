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

func configure(player: Node2D, place := "hub") -> void:
	actor = player
	area = place
	_initialized = false

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
	if not AudioManager.can_play_environment(): return
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
			var wood := area=="hub" and actor.position.y>1090
			AudioManager.play_sfx("footstep_wood" if wood else "footstep_grass",0.94+float(_step%4)*0.035,-17)
			_step += 1
		if area=="hub" and actor.position.y>1090 and _ambience>13:
			_ambience = 0
			AudioManager.play_sfx("rope_creak",0.94,-25)

func debug_status() -> Dictionary:
	return {"steps":_step,"area":area,"underwater":_was_underwater}
