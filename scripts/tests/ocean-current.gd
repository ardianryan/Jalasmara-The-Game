extends SceneTree
class Swimmer extends Node2D:
	var velocity := Vector2(90,0)
	var direction := 1
class Source extends Node2D:
	var camera: Camera2D
	var nala: Swimmer
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var polygons: Array[PackedVector2Array]=[PackedVector2Array([Vector2(300,400),Vector2(360,400),Vector2(360,950),Vector2(300,950)])]
	var field=load("res://scripts/hybrid/OceanCurrentField.gd").new()
	field.configure(polygons)
	var ambient:=Vector2(10,0)
	assert(field.sample(Vector2(100,650),ambient).is_equal_approx(ambient))
	var turning: Vector2=field.sample(Vector2(250,650),ambient)
	assert(turning.x<8 and absf(turning.y)>3 and turning.length()<=10.001,"Flow must turn along the actual wall, not accelerate")
	assert(field.sample(Vector2(292,650),Vector2(-10,0))==Vector2(-10,0),"Flow leaving the reef must not be bent back into it")
	var stopped: Vector2=field.trace(Vector2(250,650),Vector2(200,0))
	assert(stopped.x<300 and stopped.x>298 and not field.solid(stopped))
	var point:=Vector2(250,650)
	for tick in range(600):
		point=field.trace(point,field.sample(point,ambient)*.05)
		assert(not field.solid(point))
	assert(point.y<640 or point.y>660,"A visual mote must pass along the wall instead of freezing at it")
	var state=root.get_node("GameState")
	var clock=root.get_node("EnvironmentState")
	var quality=root.get_node("RenderQuality")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.clock_paused=false
	clock.reduced_motion=false
	state.world={"surface":400,"terrainContours":[[[300,400],[360,400],[360,950],[300,950]]]}
	state.dive={"id":"current-field-fixture","oxygen":77,"loot":[]}
	state.player={"coins":700,"progress":{"day":2}}
	var unchanged:=JSON.stringify({"world":state.world,"dive":state.dive,"player":state.player})
	var source:=Source.new()
	root.add_child(source)
	source.nala=Swimmer.new()
	source.nala.position=Vector2(250,650)
	source.add_child(source.nala)
	source.camera=Camera2D.new()
	source.camera.position=source.nala.position
	source.add_child(source.camera)
	source.camera.force_update_scroll()
	var water=load("res://scripts/hybrid/LivingWater.gd").new()
	source.add_child(water)
	water.setup(source)
	water.set_process(false)
	water.set_active(true)
	quality.set_profile("low",false)
	for tick in range(50):water._process(.11)
	var status: Dictionary=water.debug_status()
	assert(status.qualityBudgets.motes==16 and status.motes<=16 and status.wakes<=8 and status.shafts<=2)
	for mote in water.get("_motes"):
		assert(not field.solid(mote.at))
		var center:=source.camera.get_screen_center_position()
		var projected: Vector2=center+(Vector2(mote.at)-center)*(1.05 if bool(mote.near) else .82)
		assert(not field.solid(projected),"Parallax must not place the visible particle over reef pixels")
	var elapsed: float=water.elapsed
	clock.clock_paused=true
	water._process(.5)
	assert(water.elapsed==elapsed,"Reading/menu pause must freeze cosmetic advection without touching dive timers")
	clock.clock_paused=false
	quality.set_profile("balanced",false)
	water._process(.2)
	assert(water.debug_status().qualityBudgets.motes==48)
	assert(JSON.stringify({"world":state.world,"dive":state.dive,"player":state.player})==unchanged)
	water.set_active(false)
	assert(water.get("_motes").is_empty() and water.get("_wakes").is_empty())
	print("OCEAN CURRENT PASS: indexed reef-tangent flow, no speed gain, long-frame clipping,600 safe advected steps, parallax occlusion, low16/8/2 budget, pause, cleanup, unchanged physics/economy/O2")
	source.queue_free()
	await process_frame
	quit()
