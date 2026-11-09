extends Node
signal changed
var player: Dictionary = {}
var catalog: Dictionary = {}
var world: Dictionary = {}
var dive: Dictionary = {}
var shift: Dictionary = {}
var adventure: Dictionary = {}
var surface: Dictionary = {}
var calendar: Dictionary = {}
var homestead: Dictionary = {}
var homestead_definitions: Dictionary = {}

func apply_result(result: Dictionary, allow_clock_reset := false) -> void:
	var incoming_player: Dictionary=result.get("player",{})
	var newer_player:bool=not incoming_player.is_empty() and (incoming_player.get("id","")!=player.get("id","") or int(incoming_player.get("version",0))>int(player.get("version",0)))
	if not incoming_player.is_empty() and incoming_player.get("id","")==player.get("id","") and int(incoming_player.get("version",0))<int(player.get("version",0)): return
	var incoming_calendar: Dictionary=result.get("calendar",{})
	var reset_clock:bool=allow_clock_reset and newer_player and not incoming_calendar.is_empty() and int(incoming_calendar.get("calendarRevision",0))<int(calendar.get("calendarRevision",0))
	for key in ["player","catalog","world","adventure","surface","homestead"]:
		if not result.get(key) is Dictionary: continue
		if key=="player" and not newer_player and int(incoming_player.get("version",0))<int(player.get("version",0)): continue
		if key=="homestead" and not reset_clock and int(result[key].get("revision",0))<int(homestead.get("revision",0)): continue
		set(key,result[key])
	if not incoming_calendar.is_empty() and (reset_clock or int(incoming_calendar.get("calendarRevision",0))>=int(calendar.get("calendarRevision",0))):
		calendar=incoming_calendar
		var clock:=get_node_or_null("/root/EnvironmentState")
		if clock!=null:
			if reset_clock: clock.authoritative=false
			clock.apply_calendar(calendar)
	if result.get("homesteadDefinitions") is Dictionary:
		homestead_definitions=result.homesteadDefinitions
	for key in ["dive","shift"]:
		if result.has(key): set(key,result[key] if result[key] is Dictionary else {})
	changed.emit()

func refresh() -> Dictionary:
	var result: Dictionary = await ApiClient.get_api("/adventure/state")
	if result.get("ok", false):
		apply_result(result,true)
	return result
func fragment_name(id: String) -> String:
	for item in catalog.get("fragments", []):
		if item.id == id:
			return item.name
	return id
