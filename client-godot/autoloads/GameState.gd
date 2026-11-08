extends Node
signal changed
var player: Dictionary = {}
var catalog: Dictionary = {}
var world: Dictionary = {}
var dive: Dictionary = {}
var shift: Dictionary = {}
var adventure: Dictionary = {}
func refresh() -> Dictionary:
	var result: Dictionary = await ApiClient.get_api("/adventure/state")
	if result.get("ok", false):
		player = result.player
		catalog = result.catalog
		world = result.world
		dive = result.get("dive", {}) if result.get("dive") != null else {}
		shift = result.get("shift", {}) if result.get("shift") != null else {}
		adventure = result.get("adventure", {})
		changed.emit()
	return result
func fragment_name(id: String) -> String:
	for item in catalog.get("fragments", []):
		if item.id == id:
			return item.name
	return id
