extends Node

var session_id := ""
var busy := false
var _cooldown := 0.0
var _last_paused := false
var _last_focused := true
var last_error := ""

func _ready() -> void:
	session_id=ApiClient._uuid()

func _focused() -> bool:
	if not OS.has_feature("web"): return true
	return not bool(JavaScriptBridge.get_interface("document").hidden)

func _process(delta: float) -> void:
	if GameState.player.is_empty() or GameState.calendar.is_empty(): return
	_cooldown-=delta
	var focused:=_focused()
	var paused:=EnvironmentState.clock_paused or ViewportLayout.host_paused
	if not busy and (_cooldown<=0 or paused!=_last_paused or focused!=_last_focused):
		sync(paused,focused)

func sync(paused: bool,focused: bool) -> void:
	if busy: return
	busy=true
	_cooldown=5.0
	_last_paused=paused
	_last_focused=focused
	var result: Dictionary=await ApiClient.call_api("/calendar/heartbeat",{"sessionId":session_id,"paused":paused,"focused":focused})
	busy=false
	if result.get("ok",false):
		last_error=""
		GameState.apply_result(result)
	else:
		last_error=str(result.get("error","Jam belum tersambung."))
