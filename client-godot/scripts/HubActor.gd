extends Node2D

var actor_name := ""
var crate := false
var appearance_index := -1
var custom_tint := Color.WHITE
var custom_sheet: Texture2D
var custom_grid := Vector2i(2,2)
var route: Array = []
var walkable := Callable()
var route_index := 1
var rest_time := 2.0
var _elapsed := 0.0
var _frame := -1
var player: Node2D
var _attention := 0.0
var _facing := 1.0
var _anchor := Vector2.ZERO
var _anchored := false
var activity_profile: Dictionary = {}
var activity_kind := "idle"
var activity_phase := "idle"
var activity_motion := 0.0
var moving := false
var _navigation: RefCounted
var _activity_goal := ""
var _activity_path := PackedVector2Array()
var _activity_index := 0
var _activity_target := Vector2.ZERO
const ROUTE_RETRY_DELAYS := [0.5,1.0,2.0,8.0]
var _activity_routes: Array = []
var _route_attempts := 0
var _route_retry_in := 0.0
var _blocked_seconds := 0.0
var _body_animation := preload("res://scripts/NpcAnimationState.gd").new()
var moved_velocity := Vector2.ZERO

func configure_activity(profile: Dictionary) -> void:
	activity_profile=profile.get("activity",{}).duplicate(true)
	if activity_profile.is_empty(): return
	activity_kind=str(activity_profile.get("kind","idle"))
	if activity_kind=="fishing": _body_animation.direction="west"
	elif activity_kind in ["gardening","weaving"]: _body_animation.direction="east"
	var paths: Array=GameState.world.get("landMaps",{}).get("hub",{}).get("routes",[]).duplicate(true)
	for resident in GameState.world.get("surface_hub",{}).get("residents",[]):
		var commute: Array=resident.get("activity",{}).get("commute",[])
		if commute.size()>1: paths.append(commute)
	var own_commute: Array=activity_profile.get("commute",[])
	if own_commute.size()>1: paths.append(own_commute)
	_navigation=preload("res://scripts/NpcActivityNavigation.gd").new()
	_activity_routes=paths
	_navigation.configure(_activity_routes,walkable)
	_activity_goal=""
	_route_attempts=0
	_route_retry_in=0
	_blocked_seconds=0

func _plan_activity_path() -> void:
	# Rebuild edges against current walkability, so a blocked cached edge is not reused.
	_navigation.configure(_activity_routes,walkable)
	_activity_path=_navigation.path_between(position,_activity_target)
	_activity_index=1 if _activity_path.size()>1 else 0
	_route_attempts+=1
	_route_retry_in=float(ROUTE_RETRY_DELAYS[mini(_route_attempts-1,ROUTE_RETRY_DELAYS.size()-1)])

func _activity_update(delta: float,nearby: bool) -> void:
	moving=false
	activity_motion=0.0 if EnvironmentState.reduced_motion or EnvironmentState.clock_paused else sin(_elapsed*1.8)
	if EnvironmentState.clock_paused: return
	var weather:=EnvironmentState.snapshot()
	var minute: float=EnvironmentState.visual_minutes
	var open:=minute>=float(activity_profile.get("startMinute",420)) and minute<float(activity_profile.get("endMinute",1080))
	var desired:="shelter" if float(weather.get("rain",0))>.42 else "work" if open else "rest"
	if desired!=_activity_goal:
		if activity_phase=="work": _body_animation.begin_departure()
		_activity_goal=desired
		var point: Array=activity_profile.get(desired,activity_profile.get("work",[position.x,position.y]))
		_activity_target=Vector2(float(point[0]),float(point[1]))
		_route_attempts=0
		_route_retry_in=0
		_blocked_seconds=0
		_plan_activity_path()
	var arrived:=position.distance_to(_activity_target)<2.0
	activity_phase=desired if arrived else "walking_"+desired if not _activity_path.is_empty() else "blocked_"+desired
	if arrived:
		_blocked_seconds=0
		return
	if nearby or _body_animation.movement_locked: return
	if _activity_path.is_empty():
		_blocked_seconds+=delta
		_route_retry_in=maxf(0,_route_retry_in-delta)
		if _route_retry_in<=0: _plan_activity_path()
		return
	if _activity_index>=_activity_path.size(): return
	var target:=_activity_path[_activity_index]
	var candidate:=position.move_toward(target,delta*26.0)
	if _navigation.segment_clear(position,candidate):
		if absf(candidate.x-position.x)>.01: _facing=signf(candidate.x-position.x)
		moving=position.distance_to(candidate)>.001
		position=candidate
		_blocked_seconds=0
		if position.distance_to(target)<.3: _activity_index+=1
	else:
		_activity_path.clear()
		_route_attempts=0
		_route_retry_in=float(ROUTE_RETRY_DELAYS[0])
		activity_phase="blocked_"+desired

func activity_state() -> Dictionary:
	return {"kind":activity_kind,"phase":activity_phase,"moving":moving,"atStation":not moving and position.distance_to(_activity_target)<2,"destination":[_activity_target.x,_activity_target.y],"remaining":maxi(0,_activity_path.size()-_activity_index),"minute":EnvironmentState.visual_minutes,"reducedMotion":EnvironmentState.reduced_motion,"routeAttempts":_route_attempts,"retryIn":_route_retry_in,"blockedSeconds":_blocked_seconds}


func body_animation_state() -> Dictionary:
	var result: Dictionary=_body_animation.snapshot()
	result["layered"]=bool(get_meta("body_layered",false))
	result["hands"]=get_meta("body_hands",{})
	return result

func _process(delta: float) -> void:
	var previous_position:=position
	if not _anchored and position != Vector2.ZERO:
		_anchor = position
		_anchored = true
	visible = GameState.dive.is_empty() and not bool(get_meta("land_hidden",false))
	_elapsed += delta
	var check_pos := _anchor if _anchored else position
	var nearby := is_instance_valid(player) and player.position.distance_to(check_pos)<165
	_attention = move_toward(_attention,1.0 if nearby else 0.0,delta*2.4)
	if not activity_profile.is_empty():
		_activity_update(delta,nearby)
		_anchor=position
	elif not route.is_empty() and not crate:
		if not nearby and not EnvironmentState.clock_paused:
			rest_time = maxf(0,rest_time-delta)
			if rest_time<=0:
				var target: Vector2 = route[route_index]
				var candidate := position.move_toward(target,delta*22.0)
				if not walkable.is_valid() or walkable.call(candidate):
					if absf(candidate.x-position.x)>.01: _facing = signf(candidate.x-position.x)
					position = candidate
				else:
					route_index = (route_index+1)%route.size()
					rest_time = 3
				if position.distance_to(target)<2:
					route_index = (route_index+1)%route.size()
					rest_time = 4.0+float(appearance_index)
		_anchor = position
	elif _anchored and not crate:
		var motion := 0.0 if EnvironmentState.reduced_motion else (1.0-_attention)
		var offset := Vector2.ZERO
		if actor_name == "Bu Darmi":
			offset = Vector2(sin(_elapsed*0.65)*14.0,cos(_elapsed*0.65)*5.0)*motion
		elif actor_name == "Beno":
			offset = Vector2(sin(_elapsed*0.85+1.1)*12.0,0.0)*motion
		elif actor_name == "Mbah Wira":
			offset = Vector2(sin(_elapsed*0.55+2.0)*9.0,0.0)*motion
		elif actor_name == "Inspektur Raka":
			offset = Vector2(cos(_elapsed*0.48+0.7)*10.0,0.0)*motion
		var next_pos := _anchor + offset
		if motion > 0.15 and absf(next_pos.x - position.x) > 0.08:
			_facing = 1.0 if next_pos.x > position.x else -1.0
		position = next_pos
	if nearby and absf(player.position.x-position.x)>12:
		_facing = 1.0 if player.position.x>position.x else -1.0
	moved_velocity=(position-previous_position)/maxf(delta,.00001) if delta>0 else Vector2.ZERO
	var talking:=nearby and EnvironmentState.clock_paused
	if talking and is_instance_valid(player) and _body_animation.clip not in ["start_work","work_loop","end_work"]:
		var look:=player.position-position
		_body_animation.direction=("east" if look.x>0 else "west") if absf(look.x)>absf(look.y)*.8 else ("south" if look.y>0 else "north")
	_body_animation.update(delta,moved_velocity,activity_phase=="work",activity_phase in ["rest","shelter"],talking,EnvironmentState.clock_paused,EnvironmentState.reduced_motion,activity_kind)
	if is_instance_valid(player) and player.position.distance_to(position)<420 and GameState.dive.is_empty() and not EnvironmentState.clock_paused and not EnvironmentState.reduced_motion:
		for event in _body_animation.events:
			if event in ["cast","water_drop"]: AudioManager.play_sfx("water_splash",1.1,-23.0)
	var frame := int(_elapsed*8)
	if frame != _frame:
		_frame = frame
		queue_redraw()

func _draw() -> void:
	if crate:
		draw_texture_rect(preload("res://scripts/ItemIcons.gd").texture("cache"),Rect2(-35,-44,70,70),false)
		return
	var index: int = {"Mbah Wira":0,"Beno":1,"Bu Darmi":2,"Inspektur Raka":3}.get(actor_name,0)
	if appearance_index>=0: index = appearance_index
	var phase := float(index)*1.9
	var motion := 0.0 if EnvironmentState.reduced_motion else 1.0
	var breath := roundf(sin(_elapsed*1.1+phase)*0.75)*motion
	var glance := roundf(sin(_elapsed*0.19+phase)*0.65+_attention*_facing*1.5)
	var sheet: Texture2D = preload("res://resources/art/npc-atlas.png")
	if custom_sheet!=null: sheet = custom_sheet
	var grid := custom_grid if custom_sheet!=null else Vector2i(2,2)
	var cell := Vector2(sheet.get_size())/Vector2(grid)
	draw_rect(Rect2(-16,12,32,5),Color(0.08,0.10,0.08,0.15))
	draw_rect(Rect2(-11,10,22,8),Color(0.08,0.10,0.08,0.12))
	var working := (1.0-_attention)*sin(_elapsed*(1.6 if index==1 else 0.9)+phase)*motion
	# Pivot at the feet keeps the character grounded while their upper body leans.
	draw_set_transform(Vector2(glance,12),working*0.014,Vector2.ONE)
	draw_texture_rect_region(sheet,Rect2(-50,-96+breath,100,100-breath),Rect2(Vector2(index%grid.x,floori(float(index)/grid.x))*cell,cell))
	draw_set_transform(Vector2.ZERO)
