extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var current = load("res://scripts/CoralCurrentMotion.gd")
	var at := Vector2(180, 670)
	var varied := false
	for second in range(100):
		var angle: float = current.angle(float(second) * 0.13, at, 8.0)
		assert(absf(angle) <= current.MAX_ANGLE)
		if absf(angle - current.angle(0.0, at, 8.0)) > 0.005:
			varied = true
	assert(varied, "Water current must move the coral tips")
	assert(current.angle(1.25, at, 14.0) > current.angle(1.25, at, -14.0), "The directional current must affect the pose")
	var terrain = load("res://scripts/hybrid/TerrainGeometry.gd").new()
	root.add_child(terrain)
	terrain.world = {"terrain":[[0,600,500,400]],"terrainContours":[[[0,600],[500,600],[500,1000],[0,1000]]]}
	terrain._build_growth()
	assert(not terrain._coral_pivots.is_empty())
	for entry in terrain._coral_pivots:
		var pivot: Node3D = entry.node
		var plant := pivot.get_child(0) as Sprite3D
		assert(pivot.position == terrain._point(entry.position,50.0), "The coral root must stay planted at its visible stone contact")
		assert(is_equal_approx(plant.position.y, float(entry.size.y) * 0.5))
		assert(is_equal_approx(plant.position.z, 0.0), "Sway must not shift the coral through depth planes")
		assert(plant.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Billboarding would cancel root rotation")
		assert(plant.alpha_cut == SpriteBase3D.ALPHA_CUT_DISCARD)
	var environment: Node = root.get_node("EnvironmentState")
	var reduced_before: bool = environment.reduced_motion
	environment.reduced_motion = true
	terrain._process(0.016)
	for entry in terrain._coral_pivots:
		assert(is_zero_approx(entry.node.rotation.z), "Reduced motion must freeze coral sway")
	environment.reduced_motion = reduced_before
	terrain.free()
	print("CORAL CURRENT MOTION PASS: rooted XY sway, bounded phase, directional current, alpha threshold and reduced motion")
	quit()
