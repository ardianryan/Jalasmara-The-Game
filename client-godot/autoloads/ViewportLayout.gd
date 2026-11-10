extends Node

var safe_area := Vector4.ZERO
var host_paused := false
var _host_control := Rect2()
var _performance_clock := 0.0
signal host_pause_changed(paused: bool)
var _callback: JavaScriptObject

func _ready() -> void:
	get_viewport().size_changed.connect(_resize)
	if OS.has_feature("web"):
		_callback = JavaScriptBridge.create_callback(_host_message)
		JavaScriptBridge.get_interface("window").addEventListener("message", _callback)
	_resize()

func _host_message(args: Array) -> void:
	if args.is_empty(): return
	var event: JavaScriptObject = args[0]
	var window := JavaScriptBridge.get_interface("window")
	var objects := JavaScriptBridge.get_interface("Object")
	if str(event.origin) != str(window.location.origin) or not bool(objects.call("is",event.source,window.parent)): return
	var data = event.data
	if data == null: return
	if str(data.type)=="jalasmara:ui-sfx" and int(data.version)==1:
		AudioManager.play_sfx("wooden_click_light",1.0,-8.0)
		return
	if str(data.type)!="jalasmara:viewport" or int(data.version)!=1: return
	# CSS safe insets arrive in physical pixels and are converted during layout.
	if data.safeArea != null:
		safe_area = Vector4(float(data.safeArea.left), float(data.safeArea.top), float(data.safeArea.right), float(data.safeArea.bottom))
	if data.hostControl != null:
		var physical:=Vector2(get_window().size)
		var width:=64.0 if data.hostControl.width==null else clampf(float(data.hostControl.width),48,160)
		var height:=48.0 if data.hostControl.height==null else clampf(float(data.hostControl.height),48,100)
		var left:=physical.x/2-width/2 if data.hostControl.x==null else clampf(float(data.hostControl.x),0,maxf(0,physical.x-width))
		var top:=maxf(4,safe_area.y) if data.hostControl.y==null else clampf(float(data.hostControl.y),0,maxf(0,physical.y-height))
		_host_control=Rect2(left,top,width,height)
	if data.performanceCapture != null:
		preload("res://scripts/Diagnostics.gd").set_capture(bool(data.performanceCapture))
		if bool(data.performanceCapture): _publish_performance()
	if data.graphicsQuality != null: RenderQuality.set_profile(str(data.graphicsQuality))
	var paused := bool(data.hostMenuOpen) or not bool(data.focused)
	if paused != host_paused:
		host_paused = paused
		host_pause_changed.emit(paused)
	_resize()

func _process(delta: float) -> void:
	if not OS.has_feature("web") or not preload("res://scripts/Diagnostics.gd").capture_enabled(): return
	_performance_clock+=delta
	if _performance_clock<1.0: return
	_performance_clock=0
	_publish_performance()

func _publish_performance() -> void:
	if not OS.has_feature("web"): return
	var sample:Dictionary=preload("res://scripts/Diagnostics.gd").performance_sample(self)
	JavaScriptBridge.get_interface("window").jalasmaraPerformance=JavaScriptBridge.get_interface("JSON").parse(JSON.stringify(sample))

func _resize() -> void:
	var window := get_window()
	var physical := Vector2(window.size)
	if physical.x <= 0 or physical.y <= 0: return
	var aspect := physical.x / physical.y
	var next := Vector2i(roundi(maxf(667.0, 540.0 * aspect)), roundi(maxf(540.0, 667.0 / aspect)))
	if window.content_scale_size != next: window.content_scale_size = next

func insets() -> Vector4:
	var physical := Vector2(get_window().size)
	var logical := get_viewport().get_visible_rect().size
	var factor := logical.x / maxf(1.0, physical.x)
	return safe_area * factor

func host_control_bounds() -> Rect2:
	var physical:=Vector2(get_window().size)
	var logical:=get_viewport().get_visible_rect().size
	var factor:=logical.x/maxf(1,physical.x)
	var bounds:=_host_control
	if bounds.size.x<=0 or bounds.size.y<=0:
		bounds=Rect2(physical.x/2-32,maxf(4,safe_area.y),64,48)
	return Rect2(bounds.position*factor,bounds.size*factor)

func _exit_tree() -> void:
	if OS.has_feature("web") and _callback != null:
		JavaScriptBridge.get_interface("window").removeEventListener("message", _callback)
