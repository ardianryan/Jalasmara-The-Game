extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	var renderer=load("res://scripts/land/LandWorld3D.gd")
	var samples: Dictionary={}
	for sample in [{"name":"day","minute":720.0},{"name":"dusk","minute":1050.0},{"name":"night","minute":1200.0}]:
		clock.visual_minutes=sample.minute
		var weather: Dictionary=clock.snapshot()
		samples[sample.name]=renderer.lighting_palette("hub",weather)
	var day: Dictionary=samples.day
	var dusk: Dictionary=samples.dusk
	var night: Dictionary=samples.night
	assert(day.daylight==1.0 and day.dusk==0.0)
	assert(dusk.daylight>.45 and dusk.daylight<.55 and dusk.dusk>.99)
	assert(night.daylight==0.0 and night.dusk==0.0)
	assert(dusk.sun_color.r>dusk.sun_color.b and dusk.sun_color.r>day.sun_color.r*.94,"Sunset must read as a warm key light")
	assert(dusk.ambient_color.b>dusk.ambient_color.r,"Sunset shadows must remain cool")
	assert(night.ambient_color.b>night.ambient_color.r and night.ambient_energy>=.54,"Unlit night paths need colored, readable ambient")
	assert(day.sun_energy>dusk.sun_energy and dusk.sun_energy>night.sun_energy)
	var home_night: Dictionary=renderer.lighting_palette("home",{"daylight":.24,"phase":"malam"})
	assert(home_night.ambient_energy>.6,"Home night retains its lantern-friendly ambient")
	var dawn: Dictionary=renderer.lighting_palette("hub",{"daylight":.62,"phase":"fajar"})
	assert(dawn.dusk==0.0,"Dawn must not inherit the sunset coral accent")
	print("LAND LIGHTING PALETTE PASS: day, sunset, night, home and dawn roles")
	quit()
