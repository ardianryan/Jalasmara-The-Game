extends Node

var story_day := 1
var story_stage := "dive"
var elapsed_seconds := 0.0
var visual_minutes := 480.0
var _night := false
var reduced_motion := false

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
	if day != story_day or next_night != _night:
		story_day = maxi(1,day)
		_night = next_night
		elapsed_seconds = 0.0
		visual_minutes = 1110.0 if _night else 480.0
	story_stage = stage

func _process(delta: float) -> void:
	elapsed_seconds += delta
	var start := 1110.0 if _night else 480.0
	var ending := 1430.0 if _night else 1070.0
	visual_minutes = minf(ending,start+elapsed_seconds/3.0)

func snapshot() -> Dictionary:
	var coverage := (1.0-cos(TAU*fmod(elapsed_seconds,90.0)/90.0))*0.5
	var rain := smoothstep(0.35,0.95,coverage)*0.6
	var weather := "Cerah" if coverage<0.25 else "Berawan" if coverage<0.62 else "Hujan ringan"
	var daylight := 0.24 if _night else lerpf(0.88,0.58,clampf((visual_minutes-900.0)/170.0,0.0,1.0))
	if not _night and visual_minutes<900.0:
		daylight = 0.88+sin(clampf((visual_minutes-480.0)/420.0,0.0,1.0)*PI)*0.12
	var minute := int(visual_minutes)
	var wind := 9.0+coverage*22.0+sin(elapsed_seconds*0.21+story_day)*4.0
	var current := 7.0+coverage*11.0+sin(elapsed_seconds*0.13)*3.0
	return {"clock":"%02d:%02d" % [minute/60,minute%60],"weather":weather,"rain":rain,"clouds":coverage,"daylight":daylight,"night":_night,"day":story_day,"wind_x":wind,"wind_y":2.0+coverage*3.0,"current_x":current,"current_y":sin(elapsed_seconds*0.08)*2.2,"sea_state":0.2+coverage*0.6,"reduced_motion":reduced_motion,"phase":"malam" if _night else "senja" if minute>=990 else "siang"}
