extends Node

var safe_area := Vector4.ZERO
var host_paused := false
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
	if data == null or str(data.type) != "jalasmara:viewport" or int(data.version)!=1: return
	# CSS safe insets arrive in physical pixels and are converted during layout.
	if data.safeArea != null:
		safe_area = Vector4(float(data.safeArea.left), float(data.safeArea.top), float(data.safeArea.right), float(data.safeArea.bottom))
	if data.graphicsQuality != null: RenderQuality.set_profile(str(data.graphicsQuality))
	var paused := bool(data.hostMenuOpen) or not bool(data.focused)
	if paused != host_paused:
		host_paused = paused
		host_pause_changed.emit(paused)
	_resize()

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

func _exit_tree() -> void:
	if OS.has_feature("web") and _callback != null:
		JavaScriptBridge.get_interface("window").removeEventListener("message", _callback)
