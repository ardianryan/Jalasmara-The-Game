extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var clock:=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.authoritative=true
	clock.clock_paused=true
	var renderer=load("res://scripts/land/LandWorld3D.gd")
	var effects=load("res://scripts/EnvironmentEffects.gd")
	var largest_palette_step:=0.0
	var largest_tint_step:=0.0
	for boundary in [330.0,360.0,450.0,480.0,960.0,990.0,1045.0,1055.0,1110.0,1120.0]:
		clock.visual_minutes=boundary-.1
		var before: Dictionary=clock.snapshot()
		clock.visual_minutes=boundary+.1
		var after: Dictionary=clock.snapshot()
		var old_light: Dictionary=renderer.lighting_palette("hub",before)
		var new_light: Dictionary=renderer.lighting_palette("hub",after)
		largest_palette_step=maxf(maxf(largest_palette_step,_channel_delta(old_light.sun_color,new_light.sun_color)),maxf(_channel_delta(old_light.ambient_color,new_light.ambient_color),absf(float(old_light.sun_energy)-float(new_light.sun_energy))))
		largest_tint_step=maxf(largest_tint_step,_channel_delta(effects.tint_for("hub",float(before.daylight),.2),effects.tint_for("hub",float(after.daylight),.2)))
	assert(largest_palette_step<.005,"Sun and ambient must cross clock/phase boundaries without a visible step")
	assert(largest_tint_step<.005,"Weather tint must cross day/night flags without a jump")
	var previous_sun_energy:=INF
	var previous_ambient_energy:=INF
	for minute in [1050.0,1080.0,1110.0,1140.0,1200.0]:
		clock.visual_minutes=minute
		var light: Dictionary=renderer.lighting_palette("hub",clock.snapshot())
		assert(float(light.sun_energy)<=previous_sun_energy+.00001,"Evening sun must not brighten again after sunset")
		assert(float(light.ambient_energy)<=previous_ambient_energy+.00001,"Evening ambient must not brighten again after sunset")
		previous_sun_energy=float(light.sun_energy)
		previous_ambient_energy=float(light.ambient_energy)
	var old: Dictionary=renderer.lighting_palette("hub",{"minuteOfDay":720.0,"daylight":1.0,"clouds":0.0})
	var new: Dictionary=renderer.lighting_palette("hub",{"minuteOfDay":1110.0,"daylight":.24,"clouds":.2})
	var one_second: Dictionary=old.duplicate()
	var half_seconds: Dictionary=old.duplicate()
	for frame in range(60): one_second=renderer.smooth_lighting(one_second,new,1.0/60.0)
	for frame in range(30): half_seconds=renderer.smooth_lighting(half_seconds,new,1.0/30.0)
	assert(_channel_delta(one_second.sun_color,half_seconds.sun_color)<.00001,"Lighting smoothing must depend on elapsed time, not frame count")
	assert(absf(float(one_second.sun_energy)-float(half_seconds.sun_energy))<.00001)
	var first_frame: Dictionary=renderer.smooth_lighting(old,new,1.0/60.0)
	assert(_channel_delta(first_frame.sun_color,old.sun_color)<.05,"A server correction must not flash in one frame")
	assert(float(first_frame.sun_energy)>float(new.sun_energy),"A server correction must retain a visible transition")
	clock.apply_calendar({"calendarRevision":1,"calendarDay":4,"minuteOfDay":1110.0,"weather":{"raining":false}})
	assert(clock.snapshot().calendarDay==4 and is_equal_approx(float(clock.snapshot().minuteOfDay),1110.0),"Visual smoothing must not change the authoritative calendar")
	print("MOODBOARD DAYLIGHT CONTINUITY PASS: max palette step=",largest_palette_step," max tint step=",largest_tint_step)
	quit()

func _channel_delta(a: Color,b: Color) -> float:
	return maxf(maxf(absf(a.r-b.r),absf(a.g-b.g)),absf(a.b-b.b))
