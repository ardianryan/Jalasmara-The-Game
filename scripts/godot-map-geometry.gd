extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var Map = load("res://scripts/GeoMap.gd")
	var view = Map.new()
	view.size = Vector2(700, 400)
	root.add_child(view)
	var checks := 0
	for area in ["hub", "forest", "sea"]:
		var point := Vector2(1120, 1230) if area == "hub" else Vector2(650, 1050) if area == "forest" else Vector2(1120, 470)
		view.configure(world, area, point)
		for zoom in [1.0, 1.7, 4.0]:
			view.zoom = zoom
			view.pan = Vector2(120, -45)
			for place in view.places:
				assert(view._world_at(view._screen(place.point)).distance_to(place.point) < 0.01, "map coordinate round trip")
				checks += 1
		view.pan = Vector2.ZERO
		view.zoom = 1.0
		assert(Rect2(Vector2.ZERO, view.size).has_point(view._screen(view._player_global())), area + " current position outside map")
		var selection: Dictionary = view.places[0]
		view.select_nearest(view._screen(selection.point))
		assert(not view.selected.is_empty(), "map POI selection failed")
		view.mini = true
		assert(view._screen(view._player_global()).distance_to(view.size / 2.0) < 0.01, "minimap marker not centered")
		view.mini = false
	view.configure(world, "forest", Vector2(world.forest.entry.x, world.forest.entry.y))
	assert(view._player_global().distance_to(Vector2(world.forest.gate.x, world.forest.gate.y)) < 0.01, "forest/hub gate discontinuity")
	var Atlas = load("res://scripts/WorldAtlas.gd")
	var atlas = Atlas.new()
	atlas.configure(world, {"progress": {"day": 1}}, "hub")
	root.add_child(atlas)
	var buttons: Dictionary = {}
	for child in atlas.find_children("*","Button",true,false):
		if child is Button:
			buttons[child.text] = child
	buttons["+"].pressed.emit()
	assert(atlas._map.zoom > 1.0, "Plus button must zoom in")
	buttons["-"].pressed.emit()
	assert(is_equal_approx(atlas._map.zoom, 1.0), "Minus button must zoom out")
	buttons["Palung"].pressed.emit()
	assert(atlas._map.area == "sea", "Ocean section tab")
	buttons["Daratan"].pressed.emit()
	assert(atlas._map.area == "hub", "Land map tab")
	atlas._map.select_nearest(atlas._map._screen(atlas._map.places[0].point))
	assert(atlas._info.text == atlas._map.places[0].name, "Place selection must update information")
	atlas.queue_free()
	view.queue_free()
	print("PASS GeoMap: %d POI coordinate round trips at 3 zoom levels; hub/forest/sea markers, selection, minimap centering, shared gate, atlas zoom buttons/section tabs/location info" % checks)
	quit()
