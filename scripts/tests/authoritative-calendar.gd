extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var clock=root.get_node("EnvironmentState")
	var state=root.get_node("GameState")
	clock.set_process(false)
	root.get_node("CalendarSync").set_process(false)
	clock.clock_paused=false
	state.apply_result({"player":{"id":"calendar-test","version":1},"calendar":{"calendarRevision":10,"calendarDay":4,"minuteOfDay":600,"writer":true,"leaseExpiresAt":100},"homestead":{"revision":4}})
	clock._process(9.0)
	assert(absf(clock.visual_minutes-606)<.01,"Authoritative clock interpolates at 90 seconds per game hour")
	clock.update_story(2,"night")
	assert(clock.calendar_day==4 and absf(clock.visual_minutes-606)<.01,"Story cycles cannot overwrite calendar time")
	clock.clock_paused=true
	var weather_before:float=clock.elapsed_seconds
	clock._process(2)
	assert(absf(clock.visual_minutes-606)<.01 and clock.elapsed_seconds>weather_before,"Reading pauses calendar, not ambient animation")
	clock.clock_paused=false
	clock._process(10)
	var disconnected:float=clock.visual_minutes
	clock._process(2)
	assert(clock.visual_minutes==disconnected and not clock.snapshot().clockConnected,"Disconnected writer freezes after bounded extrapolation")
	state.apply_result({"calendar":{"calendarRevision":11,"calendarDay":4,"minuteOfDay":610,"writer":false,"leaseExpiresAt":200}})
	clock._process(2)
	assert(clock.visual_minutes==610 and not clock.snapshot().clockWriter,"Another tab owns the clock")
	state.apply_result({"calendar":{"calendarRevision":12,"calendarDay":4,"minuteOfDay":611,"writer":true,"leaseExpiresAt":200}})
	state.apply_result({"calendar":{"calendarRevision":13,"calendarDay":4,"minuteOfDay":612,"writer":false}})
	clock._process(1.5)
	assert(absf(clock.visual_minutes-613)<.01,"Normal action views cannot release the heartbeat lease")
	state.apply_result({"player":{"id":"calendar-test","version":0},"calendar":{"calendarRevision":1,"calendarDay":1,"minuteOfDay":360},"homestead":{"revision":1}})
	assert(state.calendar.calendarRevision==13 and state.homestead.revision==4 and state.player.version==1,"Late replay cannot replace newer progress")
	state.apply_result({"player":{"id":"calendar-test","version":2},"calendar":{"calendarRevision":0,"calendarDay":1,"minuteOfDay":360},"homestead":{"revision":0}},true)
	assert(clock.calendar_day==1 and clock.visual_minutes==360 and state.homestead.revision==0,"Explicit server refresh accepts admin reset")
	state.player={}
	state.calendar={}
	print("AUTHORITATIVE CALENDAR PASS: 36-minute day, story separation, reading pause, animated weather, lease ownership, disconnect freeze, replay ordering, admin reset")
	quit()
