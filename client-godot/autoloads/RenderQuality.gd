extends Node

signal profile_changed(profile: Dictionary)

const SETTINGS_PATH := "user://graphics.cfg"
const PROFILES := ["auto", "low", "balanced", "sharp"]
var settings_path := SETTINGS_PATH
var _requested := "auto"
var _coarse := false
var _auto_drop := 0
var _auto_upgrade := false
var _elapsed := 0.0
var _slow_seconds := 0.0
var _fast_seconds := 0.0

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
	var effective: String=_requested
	if _requested=="auto":
		if _coarse:
			effective="low" if _auto_drop>0 else "sharp" if _auto_upgrade else "balanced"
		else:
			effective="balanced" if _auto_drop>0 else "sharp"
	return {"requested":_requested,"effective":effective,"sunShadows":effective!="low","sunShadowAtlasSize":1024,"sunShadowDistance":2400.0,"spotShadowAtlasSize":512}

func _process(delta: float) -> void:
	if not OS.has_feature("web") or _requested!="auto" or _auto_drop>0: return
	if GameState.player.is_empty() or ViewportLayout.host_paused: return
	_elapsed+=delta
	if _elapsed<12.0: return
	if Engine.get_frames_per_second()<42:
		_slow_seconds+=delta
		_fast_seconds=0.0
	else:
		_slow_seconds=maxf(0.0,_slow_seconds-delta*2.0)
		if _coarse and not _auto_upgrade and Engine.get_frames_per_second()>=56:
			_fast_seconds+=delta
		else:
			_fast_seconds=0.0
	if _fast_seconds>=25.0:
		_auto_upgrade=true
		_fast_seconds=0.0
		_slow_seconds=0.0
		profile_changed.emit(get_profile())
	if _slow_seconds>=5.0:
		if _auto_upgrade: _auto_upgrade=false
		else: _auto_drop=1
		_slow_seconds=0.0
		profile_changed.emit(get_profile())

func set_profile(value: String, persist := true) -> bool:
	if value not in PROFILES: return false
	if value==_requested: return true
	_requested=value
	_auto_drop=0
	_auto_upgrade=false
	_elapsed=0.0
	_slow_seconds=0.0
	_fast_seconds=0.0
	if persist:
		var settings:=ConfigFile.new()
		settings.set_value("graphics","quality",value)
		settings.save(settings_path)
	profile_changed.emit(get_profile())
	return true
