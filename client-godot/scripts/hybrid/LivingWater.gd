extends Node2D

const PixelFX = preload("res://scripts/PixelEffects.gd")
const MAX_MOTES := 48
const MAX_WAKES := 18
var source: Node2D
var enabled := false
var elapsed := 0.0
var _sample_clock := 0.0
var _wake_clock := 0.0
var _world_id := 0
var _polygons: Array[PackedVector2Array] = []
var _shafts: Array[Dictionary] = []
var _motes: Array[Dictionary] = []
var _caustics: Array[Vector2] = []
var _wakes: Array[Dictionary] = []
var _weather: Dictionary = {}
var _depth := 0.0
var _clips := 0
var _fx: Node2D
var _last_loot := -1
var _was_active := false

func setup(main: Node2D) -> void:
	source = main
	_fx = PixelFX.new()
	add_child(_fx)

func set_active(value: bool) -> void:
	enabled = value
	visible = value
	if not value:
		_wakes.clear()
		_last_loot = -1

func _screen(point: Vector2, parallax: float = 1.0) -> Vector2:
	var camera: Camera2D = source.get("camera")
	if not is_instance_valid(camera): return point
	return (point-camera.get_screen_center_position())*camera.zoom*parallax+get_viewport_rect().size/2.0

func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(source) or GameState.dive.is_empty():
		_was_active = false
		return
	var player: Node2D = source.get("nala")
	if not is_instance_valid(player): return
	_weather = EnvironmentState.snapshot()
	_depth = maxf(0.0,(player.position.y-float(GameState.world.get("surface",400)))/28.0)
	var reduced := bool(_weather.get("reduced_motion",false))
	elapsed += delta*(0.2 if reduced else 1.0)
	var world_id := hash(GameState.world.get("terrainContours",[]))
	if world_id != _world_id:
		_world_id = world_id
		_build_contours()
	if not _was_active and _depth<10 and not reduced:
		_fx.add_effect("bubble-splash",_screen(player.position),1.0,0,true)
	_was_active = true
	var loot: int = GameState.dive.get("loot",[]).size()
	if _last_loot>=0 and loot>_last_loot:
		_fx.add_effect("memory-spark",_screen(player.position+Vector2(24,-8)),0.8,0,true)
	_last_loot = loot
	for index in range(_wakes.size()-1,-1,-1):
		_wakes[index].age += delta
		if float(_wakes[index].age)>1.1: _wakes.remove_at(index)
	_wake_clock += delta
	var velocity: Vector2 = player.get("velocity")
	if velocity.length()>25 and _wake_clock>0.10 and not reduced:
		_wake_clock = 0.0
		if _wakes.size()>=MAX_WAKES: _wakes.pop_front()
		var facing := float(player.get("direction"))
		_wakes.append({"at":player.position+Vector2(-facing*35,8),"age":0.0,"facing":facing})
	_sample_clock += delta
	if _sample_clock>=0.16:
		_sample_clock = 0.0
		_sample_water(player.position,reduced)
	queue_redraw()

func _build_contours() -> void:
	_polygons.clear()
	for contour in GameState.world.get("terrainContours",[]):
		var polygon := PackedVector2Array()
		for point in contour: polygon.append(Vector2(float(point[0]),float(point[1])))
		if polygon.size()>2: _polygons.append(polygon)

func clip_ray(origin: Vector2, target: Vector2) -> Vector2:
	var closest := target
	var distance := origin.distance_squared_to(target)
	for polygon in _polygons:
		for index in range(polygon.size()):
			var hit: Variant = Geometry2D.segment_intersects_segment(origin,target,polygon[index],polygon[(index+1)%polygon.size()])
			if hit is Vector2 and origin.distance_squared_to(hit)<distance:
				distance = origin.distance_squared_to(hit)
				closest = hit
	return closest

func _solid(point: Vector2) -> bool:
	for polygon in _polygons:
		if Geometry2D.is_point_in_polygon(point,polygon): return true
	return false

func _sample_water(player: Vector2,reduced: bool) -> void:
	var camera: Camera2D = source.get("camera")
	var center := camera.get_screen_center_position()
	_shafts.clear()
	_clips = 0
	var daylight := float(_weather.get("daylight",0.8))
	if _depth<36 and daylight>0.3:
		var surface := float(GameState.world.get("surface",400))+8
		for index in range(3):
			var x := floorf(center.x/390.0)*390.0+(index-1)*390.0
			var start := Vector2(x,surface)
			var finish := Vector2(x+110+float(_weather.get("wind_x",9))*2,surface+900)
			var width := minf(55,start.distance_to(finish)*0.07)
			var left_start := start-Vector2(4,0)
			var right_start := start+Vector2(4,0)
			var left_target := finish-Vector2(width,0)
			var right_target := finish+Vector2(width,0)
			var left_end := clip_ray(left_start,left_target)
			var right_end := clip_ray(right_start,right_target)
			if left_end.distance_to(left_target)>2: _clips += 1
			if right_end.distance_to(right_target)>2: _clips += 1
			_shafts.append({"leftStart":left_start,"rightStart":right_start,"leftEnd":left_end,"rightEnd":right_end,"phase":x*0.01})
	_motes.clear()
	var offset := Vector2i(floori(center.x/128),floori(center.y/128))
	var current := Vector2(float(_weather.get("current_x",7)),float(_weather.get("current_y",0)))
	for y in range(offset.y-4,offset.y+5):
		for x in range(offset.x-6,offset.x+7):
			var seed_value := posmod(x*431+y*157,997)
			if seed_value%3!=0: continue
			var local := Vector2(fposmod(seed_value*17.0+elapsed*current.x,128),fposmod(seed_value*31.0+elapsed*current.y-elapsed*2,128))
			var point := Vector2(x*128,y*128)+local
			if _solid(point): continue
			var fade := minf(minf(local.x,128-local.x),minf(local.y,128-local.y))/18.0
			_motes.append({"at":point,"near":seed_value%2==0,"alpha":clampf(fade,0,1)})
			if _motes.size()>= (16 if reduced else MAX_MOTES): break
		if _motes.size()>= (16 if reduced else MAX_MOTES): break
	_caustics.clear()
	if _depth<75 and daylight>0.3:
		for polygon in _polygons:
			for index in range(0,polygon.size(),3):
				var point := polygon[index]
				if point.y>500 and point.y<2400 and point.distance_to(center)<850:
					_caustics.append(point)
					if _caustics.size()>=20: break
			if _caustics.size()>=20: break

func _draw() -> void:
	if not enabled: return
	var daylight := float(_weather.get("daylight",0.8))
	var clouds := float(_weather.get("clouds",0.0))
	var shallow := (1.0-smoothstep(15.0,65.0,_depth))*daylight*(1.0-clouds*0.85)
	for shaft in _shafts:
		var strength := 0.025*shallow*(0.8+sin(elapsed*0.4+float(shaft.phase))*0.2)
		if strength<0.001: continue
		draw_colored_polygon(PackedVector2Array([_screen(shaft.leftStart),_screen(shaft.rightStart),_screen(shaft.rightEnd),_screen(shaft.leftEnd)]),Color(0.78,0.94,0.78,strength))
	for mote in _motes:
		var near: bool = mote.near
		var point := _screen(mote.at,1.05 if near else 0.82).round()
		if not get_viewport_rect().grow(3).has_point(point): continue
		draw_rect(Rect2(point,Vector2.ONE*(1.0 if near else 0.75)),Color(0.70,0.88,0.82,float(mote.alpha)*(0.26 if near else 0.12)))
	for point in _caustics:
		var at := _screen(point)
		var phase := elapsed*0.8+point.x*0.04
		var alpha := maxf(0,sin(phase))*shallow*0.12
		if alpha>0.005:
			draw_polyline(PackedVector2Array([at+Vector2(-9,1),at+Vector2(-3,-2),at+Vector2(5,0),at+Vector2(10,-2)]),Color(0.68,0.91,0.78,alpha),1)
	for wake in _wakes:
		var age := float(wake.age)
		var flow := Vector2(float(_weather.get("current_x",7)),float(_weather.get("current_y",0)))*age
		var at := _screen(wake.at+flow+Vector2(0,-age*6)).round()
		var length := 3+age*5
		draw_line(at,at+Vector2(-float(wake.facing)*length,1),Color(0.65,0.89,0.84,(1-age/1.1)*0.23),1)

func debug_status() -> Dictionary:
	return {"active":enabled,"depth":_depth,"motes":_motes.size(),"wakes":_wakes.size(),"shafts":_shafts.size(),"contourClips":_clips,"causticPatches":_caustics.size(),"current":[float(_weather.get("current_x",0)),float(_weather.get("current_y",0))],"reducedMotion":bool(_weather.get("reduced_motion",false)),"threeDParticles":0}
