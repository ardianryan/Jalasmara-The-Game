extends RefCounted

static var _checked := false
static var _enabled := false
static var _capture := false

static func enabled() -> bool:
	if _checked: return _enabled
	_checked=true
	_enabled=OS.is_debug_build()
	if OS.has_feature("web"):
		var window=JavaScriptBridge.get_interface("window")
		var query:=str(window.location.search).trim_prefix("?").split("&")
		_enabled=bool(window.jalasmaraDiagnostics) or bool(window.parent.jalasmaraDiagnostics) or query.has("diagnostics=1")
	return _enabled

static func set_enabled(value: bool) -> void:
	_checked=true
	_enabled=value

static func set_capture(value: bool) -> void:
	_capture=value

static func capture_enabled() -> bool:
	return _capture

static func performance_sample(actor: Node = null) -> Dictionary:
	if not enabled() and not _capture: return {}
	var sample: Dictionary={"fps":Performance.get_monitor(Performance.TIME_FPS),"processMs":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physicsMs":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"drawCalls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"renderObjects":Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),"renderPrimitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"quality":{}}
	if is_instance_valid(actor):
		var api=actor.get_node_or_null("/root/ApiClient")
		if api: sample["apiResponseMs"]=api.response_times.duplicate()
		var quality=actor.get_node_or_null("/root/RenderQuality")
		if quality: sample.quality=quality.get_profile()
		for field in actor.get_property_list():
			if str(field.name)=="land_path":
				var path=actor.get("land_path")
				if path and path.has_method("size"): sample.pathQueue=path.size()
				break
	return sample
