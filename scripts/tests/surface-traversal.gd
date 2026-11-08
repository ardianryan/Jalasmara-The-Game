extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var world_before := JSON.stringify(world)
	var state := root.get_node("GameState")
	var account_before := JSON.stringify({"player":state.player,"dive":state.dive})
	var traversal = load("res://scripts/SurfaceTraversal.gd").new()
	traversal.configure(world.landMaps.hub)
	var profiles := {}
	for terrace in world.hub.terraces: profiles[str(terrace.id)] = float(terrace.elevation)
	var samples := 0
	var directions := {}
	for connector in world.hub.stairs:
		assert(connector.path.size()>=2 and int(connector.steps)>=1)
		var start := Vector2(float(connector.path[0][0]),float(connector.path[0][1]))
		var end := Vector2(float(connector.path[-1][0]),float(connector.path[-1][1]))
		var velocity := (end-start).normalized()*140.0
		var previous_progress := -1.0
		var previous_height := float(profiles[str(connector.from)])
		var previous_step := -1
		for index in range(21):
			var expected := float(index)/20.0
			var feet := start.lerp(end,expected)
			var original_feet := feet
			var result: Dictionary = traversal.sample(feet,velocity,0.05)
			assert(result.onConnector and str(result.connectorId)==str(connector.id))
			assert(bool(result.onStairs)==(str(connector.type)=="stairs"))
			assert(absf(float(result.progress)-expected)<0.025,"Stair progress must follow the real connector path")
			assert(float(result.progress)>=previous_progress)
			assert(float(result.elevation)>=previous_height-0.001,"Ascending must not jump down a floor")
			assert(int(result.stepIndex)>=previous_step and int(result.stepIndex)<int(connector.steps))
			assert(float(result.paceScale)>0 and float(result.paceScale)<=1)
			assert(absf(float(result.footBob))<=1.6)
			assert(feet==original_feet,"Stair sampling must never offset the authoritative body")
			previous_progress = float(result.progress)
			previous_height = float(result.elevation)
			previous_step = int(result.stepIndex)
			directions[str(result.direction)] = true
			samples += 1
		assert(absf(previous_height-float(profiles[str(connector.to)]))<0.01)
		previous_progress = 2.0
		previous_step = int(connector.steps)
		for index in range(20,-1,-1):
			var result: Dictionary = traversal.sample(start.lerp(end,float(index)/20.0),-velocity,0.05)
			assert(result.onConnector)
			assert(float(result.progress)<=previous_progress)
			assert(int(result.stepIndex)<=previous_step)
			previous_progress = float(result.progress)
			previous_step = int(result.stepIndex)
			directions[str(result.direction)] = true
			samples += 1
		var idle: Dictionary = traversal.sample(start.lerp(end,.5),Vector2.ZERO,.2)
		assert(is_zero_approx(float(idle.footBob)),"Idle stair pose must not keep stepping")
		traversal.set_reduced_motion(true)
		var reduced: Dictionary = traversal.sample(start.lerp(end,.5),velocity,.2)
		assert(is_zero_approx(float(reduced.footBob)))
		assert(absf(float(reduced.progress)-.5)<.025)
		traversal.set_reduced_motion(false)
	var outside: Dictionary = traversal.sample(Vector2(-10000,-10000),Vector2(100,0),.1)
	assert(not outside.onStairs and is_zero_approx(float(outside.footBob)))
	assert(directions.size()>=2,"Ascent and descent must be distinguished")
	assert(JSON.stringify(world)==world_before,"Stair sampling changed world/collision metadata")
	assert(JSON.stringify({"player":state.player,"dive":state.dive})==account_before,"Stairs changed account resources or progression")
	print("SURFACE TRAVERSAL PASS: ",samples," ascending/descending path samples, continuous elevation, step indices, idle/outside/reduced motion and unchanged body/world/account state")
	quit()
