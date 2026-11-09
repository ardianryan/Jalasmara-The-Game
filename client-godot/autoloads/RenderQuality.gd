extends Node

signal profile_changed(profile: Dictionary)

const SETTINGS_PATH := "user://graphics.cfg"
const PROFILES := ["auto", "low", "balanced"]
var settings_path := SETTINGS_PATH
var _requested := "auto"
var _coarse := false

func _ready() -> void:
	RenderingServer.directional_shadow_atlas_set_size(1024,true)
	if OS.has_feature("web"):
		var window=JavaScriptBridge.get_interface("window")
		_coarse=bool(window.matchMedia("(pointer: coarse)").matches)
	else:
		_coarse=DisplayServer.is_touchscreen_available()
	var settings:=ConfigFile.new()
	if settings.load(settings_path)==OK:
		var saved:=str(settings.get_value("graphics","quality","auto"))
		if saved in PROFILES: _requested=saved

func get_profile() -> Dictionary:
	var effective: String=("low" if _coarse else "balanced") if _requested=="auto" else _requested
	return {"requested":_requested,"effective":effective,"sunShadows":effective!="low","sunShadowAtlasSize":1024,"sunShadowDistance":2400.0,"spotShadowAtlasSize":512}

func set_profile(value: String, persist := true) -> bool:
	if value not in PROFILES: return false
	if value==_requested: return true
	_requested=value
	if persist:
		var settings:=ConfigFile.new()
		settings.set_value("graphics","quality",value)
		settings.save(settings_path)
	profile_changed.emit(get_profile())
	return true
