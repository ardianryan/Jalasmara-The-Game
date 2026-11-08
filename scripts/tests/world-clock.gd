extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var clock := root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.update_story(2,"dive")
	clock.visual_minutes = 480.0
	clock.clock_paused = false
	assert(clock.day_length_minutes==36.0)
	clock._process(90.0)
	assert(absf(clock.visual_minutes-540.0)<0.01,"One in-game hour must take 90 real seconds")
	clock.visual_minutes = 480.0
	clock._process(1080.0)
	assert(absf(clock.visual_minutes-1200.0)<0.01 and clock.snapshot().night,"18 real minutes advance half a day")
	clock._process(1080.0)
	assert(absf(clock.visual_minutes-480.0)<0.01 and not clock.snapshot().night,"36 real minutes complete the full clock cycle")
	clock.clock_paused = true
	var before: float = clock.visual_minutes
	var weather_before: float = clock.elapsed_seconds
	clock._process(180.0)
	assert(clock.visual_minutes==before,"Dialog or quiz must pause the clock")
	assert(clock.elapsed_seconds>weather_before,"Weather animation may continue while reading")
	clock.clock_paused = false
	clock.update_story(2,"night")
	assert(clock.snapshot().night)
	clock._process(180.0)
	var after: float = clock.visual_minutes
	clock.update_story(2,"night")
	assert(clock.visual_minutes==after,"Repeated story sync must not reset the visual clock")
	assert(clock.snapshot().day==2,"Visual time must not grant story-day progression")
	print("WORLD CLOCK PASS: 36-minute full day, 90-second hours, continuous midnight, reading pause, animated weather and authoritative story progression")
	quit()
