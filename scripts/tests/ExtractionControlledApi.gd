extends Node

signal refresh_waiting
signal release_refresh
var extract_result: Dictionary = {}
var refresh_result: Dictionary = {}
var refresh_started := false
var requests: Array[String] = []
var csrf := ""
var origin := "http://127.0.0.1"

func call_api(path: String, _body: Variant = null, _method := HTTPClient.METHOD_POST, _key := "") -> Dictionary:
	requests.append(path)
	await get_tree().process_frame
	assert(path=="/dive/extract","Only extraction may make a request in this controlled transition")
	return extract_result.duplicate(true)

func get_api(path: String) -> Dictionary:
	requests.append(path)
	assert(path=="/adventure/state")
	refresh_started=true
	refresh_waiting.emit()
	await release_refresh
	return refresh_result.duplicate(true)
