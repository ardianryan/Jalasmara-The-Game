extends SceneTree

const Model = preload("res://scripts/PollutionBubbles.gd")
const Surface = preload("res://scripts/hybrid/PollutionSurface.gd")
const Underwater = preload("res://scripts/hybrid/PollutionUnderwater.gd")

func _initialize() -> void:
	var before := {"progress": {"bossDefeated": false}}
	var after := {"progress": {"bossDefeated": true}}
	var intact := {"puzzles": []}
	var repaired := {"puzzles": ["valve"]}
	assert(Model.intensity(before, intact) == 1.0)
	assert(Model.intensity(before, repaired, "valve") < Model.intensity(before, intact, "valve"))
	assert(Model.intensity(before, repaired, "main") == 1.0)
	assert(Model.intensity(after, intact) == 0.0)
	assert(Model.intensity(after, repaired, "valve") == 0.0)
	var nearly_won := {"mode": "boss", "hits": 5, "requiredHits": 6}
	var won := {"mode": "boss", "hits": 6, "requiredHits": 6}
	assert(Model.intensity(before, intact, "valve", nearly_won) == 1.0)
	assert(Model.intensity(before, intact, "valve", won) == 0.0)
	assert(Model.intensity(before, intact, "valve", {"mode": "dive", "hits": 6, "requiredHits": 6}) == 1.0)
	var world := {"landmarks": [{"id": "corporate_pipe", "x": 4420, "y": 2520}], "puzzles": [{"id": "valve", "x": 4650, "y": 2630}]}
	assert(Model.source_position(world, "corporate_pipe", Vector2.ZERO) == Vector2(4420, 2520))
	assert(Model.source_position(world, "valve", Vector2.ZERO) == Vector2(4650, 2630))
	assert(Model.bubble_offset(5, 1.0, 174.0, true).y > -174.0)
	assert(Model.bubble_offset(5, 1.0, 174.0, true).distance_to(Model.bubble_offset(5, 2.0, 174.0, true)) < Model.bubble_offset(5, 1.0, 174.0, false).distance_to(Model.bubble_offset(5, 2.0, 174.0, false)))
	var surface := Surface.new()
	assert(surface.debug_status().budget == Model.MAX_SURFACE_BUBBLES)
	surface.free()
	var underwater := Underwater.new()
	assert(underwater.debug_status().budget == Model.MAX_UNDERWATER_BUBBLES)
	underwater.free()
	print("POLLUTION BUBBLES PASS: authoritative boss completion/reload, valve reduction, source anchors, reduced motion, fixed pool")
	quit()
