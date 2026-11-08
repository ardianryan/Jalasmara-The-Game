extends SceneTree

class Swimmer extends Node2D:
	var velocity := Vector2(90,0)
	var direction := 1
class Source extends Node2D:
	var camera: Camera2D
	var nala: Swimmer

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state = root.get_node("GameState")
	var conditions = root.get_node("EnvironmentState")
	conditions.set_process(false)
	conditions.reduced_motion = false
	conditions.update_story(2,"dive")
	conditions.elapsed_seconds = 0
	var clear: Dictionary = conditions.snapshot()
	conditions.elapsed_seconds = conditions.weather_cycle_seconds/2.0
	var rain: Dictionary = conditions.snapshot()
	assert(clear.rain<0.01 and rain.rain>0.5)
	assert(float(rain.wind_x)>float(clear.wind_x))
	assert(float(rain.current_x)>float(clear.current_x))
	assert(rain.day==2 and not rain.night)
	conditions.update_story(2,"night")
	assert(conditions.snapshot().night)
	assert(float(conditions.snapshot().daylight)<0.3)
	conditions.update_story(2,"dive")
	conditions.elapsed_seconds = conditions.weather_cycle_seconds/2.0
	state.world = {"surface":400,"terrainContours":[[[250,410],[290,410],[290,1000],[250,1000]],[[0,740],[1000,740],[1000,900],[0,900]]],"hub":{"paths":[[[100,450],[500,450]]]},"forest":{}}
	state.player = {"id":"visual-unit-fixture","coins":700,"progress":{"day":2,"stage":"dive"}}
	state.dive = {"id":"visual-unit-fixture","oxygen":77,"loot":[]}
	var source := Source.new()
	root.add_child(source)
	current_scene = source
	source.nala = Swimmer.new()
	source.nala.position = Vector2(200,500)
	source.add_child(source.nala)
	source.camera = Camera2D.new()
	source.camera.position = source.nala.position
	source.add_child(source.camera)
	source.camera.force_update_scroll()
	var water = load("res://scripts/hybrid/LivingWater.gd").new()
	source.add_child(water)
	water.setup(source)
	water.set_active(true)
	water._process(0.2)
	var hit: Vector2 = water.clip_ray(Vector2(200,500),Vector2(400,500))
	assert(absf(hit.x-250)<0.01,"Visibility must stop at the actual wall contour")
	assert(water.clip_ray(Vector2(200,500),Vector2(120,500))==Vector2(120,500))
	for index in range(120): water._process(0.11)
	var info: Dictionary = water.debug_status()
	assert(info.motes<=48 and info.wakes<=18 and info.shafts<=3)
	assert(info.contourClips>0)
	assert(info.threeDParticles==0)
	assert(state.dive.oxygen==77 and state.player.coins==700,"Visual conditions must never mutate game resources")
	conditions.reduced_motion = true
	water._process(0.2)
	assert(water.debug_status().motes<=16)
	water.set_active(false)
	assert(not water.visible and water.debug_status().wakes==0)
	var effects = load("res://scripts/EnvironmentEffects.gd").new()
	source.add_child(effects)
	effects.configure("forest")
	effects._process(0.5)
	assert(effects._canvas.area=="forest" and effects._canvas.reduced_motion)
	assert(effects._pixel_fx.get_child_count()==0)
	effects.configure("hub")
	conditions.reduced_motion = false
	effects._ground_rain_impacts(rain)
	assert(effects.debug_status().rainImpacts==1,"Rain impact must use an actual visible road path")
	assert(effects._pixel_fx.get_child_count()<=8)
	print("LIVING WATER PASS: deterministic weather/current, night light, contour occlusion, bounded wake/motes/shafts, reduced motion, surface effects, unchanged oxygen/coins.")
	source.queue_free()
	quit()
