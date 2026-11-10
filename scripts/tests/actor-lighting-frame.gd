extends SceneTree

class TintRenderer extends Node3D:
	var _lanterns: Array=[]
	var map: Dictionary={}
	func map_point(feet: Vector2,height: float) -> Vector3:
		return Vector3(feet.x,feet.y,height)

func _initialize() -> void:
	_run.call_deferred()

func _same(actual: Color,expected: Color,label: String) -> void:
	assert(absf(actual.r-expected.r)<.000001 and absf(actual.g-expected.g)<.000001 and absf(actual.b-expected.b)<.000001,label)

func _legacy(tinter: Node,feet: Vector2,height: float) -> Color:
	var weather: Dictionary=root.get_node("EnvironmentState").snapshot()
	var daylight:=clampf((float(weather.get("daylight",.8))-.24)/.76,0,1)
	var tint:=Color(.74,.82,.86).lerp(Color(1,1,.98),daylight)
	var at: Vector3=tinter.renderer.map_point(feet,height+30)
	var warmth:=0.0
	for lamp in tinter.renderer.get("_lanterns"):
		var reach: float=lamp.omni_range
		var proximity:=clampf(1.0-at.distance_to(lamp.global_position)/reach,0,1)
		warmth=maxf(warmth,proximity*proximity*(1-daylight)*.42)
	return tint.lerp(Color(1,.89,.73),warmth)

func _batch(tinter: Node,weather: Node,cached: bool) -> Dictionary:
	var checksum:=Vector3.ZERO
	var started:=Time.get_ticks_usec()
	for frame in range(240):
		weather.visual_minutes=float([0,420,720,1050][frame%4])
		if cached: tinter.set("_lighting_frame",tinter._lighting_context())
		for index in range(24):
			var at:=Vector2(index*37+frame%7,index*23-frame%9)
			var height:=float((index%4)*48)
			var tint: Color=tinter._readable_tint(at,height) if cached else _legacy(tinter,at,height)
			checksum+=Vector3(tint.r,tint.g,tint.b)
		tinter.set("_lighting_frame",{})
	return {"micros":Time.get_ticks_usec()-started,"checksum":[checksum.x,checksum.y,checksum.z],"frames":240,"actorsPerFrame":24}

func _run() -> void:
	var weather=root.get_node("EnvironmentState")
	weather.set_process(false)
	weather.visual_minutes=0
	var renderer:=TintRenderer.new()
	root.add_child(renderer)
	var lamp:=OmniLight3D.new()
	lamp.omni_range=300
	lamp.position=Vector3(0,0,30)
	renderer.add_child(lamp)
	renderer._lanterns.append(lamp)
	var tinter=load("res://scripts/land/LandActors3D.gd").new()
	root.add_child(tinter)
	tinter.renderer=renderer
	_same(tinter._readable_tint(Vector2.ZERO,0),Color(.8492,.8494,.8054),"Night actor at lantern center retains warm readable tint")
	_same(tinter._readable_tint(Vector2(150,0),0),Color(.7673,.82735,.84635),"Half-range falloff is squared, not linear")
	_same(tinter._readable_tint(Vector2(300,0),0),Color(.74,.82,.86),"Range boundary stays cool")
	_same(tinter._readable_tint(Vector2.ZERO,300),Color(.74,.82,.86),"Elevation participates in light distance")
	weather.visual_minutes=720
	_same(tinter._readable_tint(Vector2.ZERO,0),Color(1,1,.98),"Full daylight retains the original warm-white tint")
	assert(tinter._lighting_context().lamps.is_empty(),"Daylight must not read unused positional lights")
	weather.visual_minutes=0
	tinter.set("_lighting_frame",tinter._lighting_context())
	lamp.position.x=600
	weather.visual_minutes=720
	_same(tinter._readable_tint(Vector2.ZERO,0),Color(.8492,.8494,.8054),"One synchronous actor batch has one lighting state")
	tinter.set("_lighting_frame",{})
	_same(tinter._readable_tint(Vector2.ZERO,0),Color(1,1,.98),"Direct calls after batch observe new clock state")
	weather.visual_minutes=0
	_same(tinter._readable_tint(Vector2.ZERO,0),Color(.74,.82,.86),"Direct calls after batch observe moved light")
	renderer._lanterns.clear()
	lamp.free()
	tinter.actor=Node2D.new()
	root.add_child(tinter.actor)
	tinter.source=tinter.actor
	renderer.set("_lanterns",[])
	tinter.update_actors(0)
	assert(tinter.get("_lighting_frame").is_empty(),"A completed actor batch must release its lighting context")
	# An invalid actor must clear any unfinished frame context before returning.
	var actor: Node2D=tinter.actor
	tinter.actor=null
	tinter.set("_lighting_frame",{"daylight":1.0,"lamps":[]})
	tinter.update_actors(0)
	assert(tinter.get("_lighting_frame").is_empty())
	actor.free()
	for index in range(11):
		var light:=OmniLight3D.new()
		light.position=Vector3(index*83,index*47,30+index%3*48)
		light.omni_range=300
		renderer.add_child(light)
		renderer._lanterns.append(light)
	var rounds: Array=[]
	for round_index in range(5):
		var old_result: Dictionary
		var new_result: Dictionary
		if round_index%2==0:
			old_result=_batch(tinter,weather,false)
			new_result=_batch(tinter,weather,true)
		else:
			new_result=_batch(tinter,weather,true)
			old_result=_batch(tinter,weather,false)
		assert(old_result.checksum==new_result.checksum,"Identical points/clocks/lamps must produce identical accumulated RGB")
		rounds.append({"legacy":old_result,"frameContext":new_result})
	var output:=OS.get_environment("ACTOR_LIGHTING_REPORT")
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		var file:=FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify({"rounds":rounds,"fpsClaim":false},"  "))
	tinter.free()
	renderer.free()
	print("ACTOR LIGHTING FRAME PASS: fixed night/day/falloff/elevation colors, bounded frame state, direct-call invalidation, invalid-actor cleanup; five AB/BA checksum-matched CPU batches, not device FPS")
	quit()
