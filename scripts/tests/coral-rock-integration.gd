extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var terrain: Node3D = load("res://scripts/hybrid/TerrainGeometry.gd").new()
	root.add_child(terrain)
	terrain.world = {
		"terrain": [[0, 600, 500, 300]],
		"terrainContours": [[[0, 600], [500, 600], [500, 900], [0, 900]]],
	}
	for unused in range(3):
		terrain._materials.append(StandardMaterial3D.new())
	terrain._build_growth()
	assert(not terrain._coral_pivots.is_empty(), "Expected at least one coral on the reef shelf")
	assert(terrain.get_meta("coral_stone_mounts") == terrain._coral_pivots.size(), "Every coral should have a rooted stone contact")
	var stone := terrain.get_node_or_null("CoralRootStone0") as MeshInstance3D
	assert(stone != null and stone.mesh.get_surface_count() == 1, "Contacts should be one batched rock mesh")
	assert(stone.get_child_count() == 0 and stone.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	for entry in terrain._coral_pivots:
		var pivot: Node3D = entry.node
		assert(int(entry.terrain) == 0)
		assert(float(entry.position.y) > 620.0, "The base must be inside the visible reef top, not on its outer outline")
		assert(pivot.position == terrain._point(entry.position, 50.0))
		assert(pivot.get_child(0) is Sprite3D)
	var environment := root.get_node("EnvironmentState")
	var previous: bool = environment.reduced_motion
	environment.reduced_motion = true
	terrain._process(0.016)
	for entry in terrain._coral_pivots:
		assert(is_zero_approx(entry.node.rotation.z), "Reduced motion must retain planted coral")
	environment.reduced_motion = previous
	terrain.free()
	print("CORAL ROCK INTEGRATION PASS: shelf interior contact, batched depth facets, rooted sway, reduced motion")
	quit()
