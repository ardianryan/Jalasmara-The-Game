extends Node

var story_day := 1
var story_stage := "dive"
var elapsed_seconds := 0.0
var visual_minutes := 480.0
var day_length_minutes := 36.0
var clock_paused := false
var weather_cycle_seconds := 360.0
var _story_night := false
var _night := false
var reduced_motion := false
var authoritative := false
var calendar_day := 1
var _calendar_revision := -1
var _since_sync := 0.0
var _clock_writer := true
var _server_rain := false
var _rain_amount := 0.0

func apply_calendar(value: Dictionary) -> void:
	if not value.has("minuteOfDay"): return
	var revision:=int(value.get("calendarRevision",0))
	if authoritative and revision<_calendar_revision: return
	authoritative=true
	_calendar_revision=revision
	calendar_day=maxi(1,int(value.get("calendarDay",1)))
	visual_minutes=fposmod(float(value.minuteOfDay),1440.0)
	_since_sync=0.0
	if value.has("leaseExpiresAt"): _clock_writer=bool(value.get("writer",true))
	_server_rain=bool(value.get("weather",{}).get("raining",false))
	_night=visual_minutes<360.0 or visual_minutes>=1110.0

func _ready() -> void:
	if OS.has_feature("web"):
		reduced_motion = bool(JavaScriptBridge.get_interface("window").matchMedia("(prefers-reduced-motion: reduce)").matches)
	var preferences := ConfigFile.new()
	if preferences.load("user://environment.cfg")==OK:
		reduced_motion = bool(preferences.get_value("visual","reduced_motion",reduced_motion))

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	var preferences := ConfigFile.new()
	preferences.set_value("visual","reduced_motion",value)
	preferences.save("user://environment.cfg")

func update_story(day: int, stage: String) -> void:
	var next_night := stage == "night"
	if not authoritative and (day != story_day or next_night != _story_night):
		story_day = maxi(1,day)
		_story_night = next_night
		_night = next_night
		elapsed_seconds = 0.0
		visual_minutes = 1110.0 if _night else 480.0
	story_stage = stage
	story_day=maxi(1,day)

func _process(delta: float) -> void:
	elapsed_seconds += delta
	_since_sync+=delta
	_rain_amount=move_toward(_rain_amount,.55 if _server_rain else 0.0,delta*.08)
	if not clock_paused and (not authoritative or (_since_sync<15.0 and _clock_writer)):
		visual_minutes = fposmod(visual_minutes+delta*24.0/day_length_minutes,1440.0)
	_night = visual_minutes<360.0 or visual_minutes>=1110.0

func snapshot() -> Dictionary:
	var coverage := (1.0-cos(TAU*fmod(elapsed_seconds,weather_cycle_seconds)/weather_cycle_seconds))*0.5
	var rain := smoothstep(0.35,0.95,coverage)*0.6
	if authoritative:
		rain=_rain_amount
		coverage=lerpf(.12,.85,clampf(_rain_amount/.55,0,1))
	var weather := "Cerah" if coverage<0.25 else "Berawan" if coverage<0.62 else "Hujan ringan"
	var hour := visual_minutes/60.0
	var sunlight := smoothstep(5.5,7.5,hour)*(1.0-smoothstep(16.5,18.5,hour))
	var daylight := lerpf(0.24,1.0,sunlight)
	var minute := int(visual_minutes)
	var wind := 9.0+coverage*22.0+sin(elapsed_seconds*0.21+story_day)*4.0
	var current := 7.0+coverage*11.0+sin(elapsed_seconds*0.13)*3.0
	return {"clock":"%02d:%02d" % [minute/60,minute%60],"weather":weather,"rain":rain,"clouds":coverage,"daylight":daylight,"night":_night,"day":story_day,"calendarDay":calendar_day,"authoritative":authoritative,"clockConnected":not authoritative or _since_sync<15.0,"clockWriter":_clock_writer,"wind_x":wind,"wind_y":2.0+coverage*3.0,"current_x":current,"current_y":sin(elapsed_seconds*0.08)*2.2,"sea_state":0.2+coverage*0.6,"reduced_motion":reduced_motion,"dayLengthMinutes":day_length_minutes,"clockPaused":clock_paused,"phase":"malam" if _night else "senja" if minute>=990 else "fajar" if minute<480 else "siang"}
