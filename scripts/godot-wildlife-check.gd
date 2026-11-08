extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.dive = {"id":"ecology-regression","mode":"dive","targets":[]}
	for point in [Vector2(1550,620),Vector2(2650,1250),Vector2(4600,1600),Vector2(2450,2200)]:
		for index in range(6):
			state.dive.targets.append({"id":"fish"+str(state.dive.targets.size()),"x":point.x,"y":point.y,"fragmentId":"klorofil" if index == 0 else "rasio"})
	var Fauna = load("res://scripts/Wildlife.gd")
	var fauna = Fauna.new()
	var player := Node2D.new()
	player.position = Vector2(5900,3200)
	root.add_child(player)
	root.add_child(fauna)
	fauna.set_process(false)
	fauna.player = player
	fauna.session_id = state.dive.id
	fauna._populate()
	assert(fauna.creatures.size() == 29, "24 school fish + 5 distinct solitary species")
	assert(fauna.contour_shapes.size() == state.world.terrainContours.size())
	assert(fauna._blocked(Vector2(1920,870)), "Core is solid")
	assert(not fauna._blocked(Vector2(1783,823),1), "Natural cut corner is water, unlike the old bounding box")
	assert(not fauna._blocked(Vector2(1920,970),12), "Natural cave gap remains water")
	var initial := []
	for creature in fauna.creatures:
		initial.append(creature.position)
		assert(not fauna._blocked(creature.position,Fauna.PROFILES[int(creature.species)].radius), "Spawn intersects wall")
	var observed := {}
	var clips := {}
	var samples := 0
	for tick in range(1500):
		fauna.elapsed += 0.04
		for creature in fauna.creatures:
			fauna._move_creature(creature,0.04)
			assert(not fauna._blocked(creature.position,Fauna.PROFILES[int(creature.species)].radius), "Fauna crossed actual natural terrain or water bounds")
			assert(Vector2(creature.velocity).length() < 165, "Unbounded speed")
			observed[creature.state] = true
			clips[creature.animation_state] = true
			samples += 1
	var moved := 0
	for index in range(fauna.creatures.size()):
		if Vector2(fauna.creatures[index].position).distance_to(initial[index]) > 30: moved += 1
	assert(moved >= 24, "School is static or trapped")
	for behavior in ["idle","feed","swim","flee","hunt"]:
		assert(observed.has(behavior), "Missing observable behavior: "+behavior)
	assert(clips.has("idle") and clips.has("walk"), "Idle and locomotion clips must both be selected")
	assert(Fauna.PROFILES[7].speed > Fauna.PROFILES[6].speed * 2, "Shark and puffer profiles must differ")
	assert(Fauna.PROFILES[7].size > Fauna.PROFILES[1].size * 3, "Authored scale hierarchy")
	assert(fauna.current_at(Vector2(2000,600),4).distance_to(fauna.current_at(Vector2(2000,2800),4)) > 1, "Depth currents must differ")
	# Controlled reaction fixture separates player avoidance from schooling and hunting.
	fauna.creatures.clear()
	fauna._add_creature(1,Vector2(2300,650),0,Vector2.ZERO)
	var prey: Dictionary = fauna.creatures[0]
	prey.velocity = Vector2.ZERO
	player.position = Vector2(2270,650)
	fauna.elapsed = 10
	fauna._move_creature(prey,0.04)
	assert(prey.state == "flee" and Vector2(prey.velocity).x > 0, "Fish must evade player, not orbit them")
	player.position = Vector2(5900,3200)
	fauna._add_creature(7,Vector2(2180,650),-7,Vector2.ZERO)
	fauna._move_creature(prey,0.04)
	assert(prey.state == "flee", "Prey must react to nearby predator")
	fauna._move_creature(fauna.creatures[1],0.04)
	assert(fauna.creatures[1].state == "hunt", "Predator must notice prey")
	# Deliberately crowded fish must separate, without random teleporting.
	fauna.creatures.clear()
	fauna._add_creature(1,Vector2(2300,650),0,Vector2.ZERO)
	fauna._add_creature(1,Vector2(2300,650),0,Vector2(5,0))
	fauna.creatures[0].velocity = Vector2.ZERO
	fauna.creatures[1].velocity = Vector2.ZERO
	for tick in range(75):
		fauna.elapsed += 0.04
		for creature in fauna.creatures: fauna._move_creature(creature,0.04)
	assert(Vector2(fauna.creatures[0].position).distance_to(fauna.creatures[1].position) > 18, "Crowded school must separate")
	var Entities = load("res://scripts/Entities.gd")
	var entities = Entities.new()
	root.add_child(entities)
	entities.set_process(false)
	entities.player = player
	for time in range(300):
		entities.elapsed = time * 0.1
		for target in state.dive.targets:
			var point: Vector2 = entities.target_position(target)
			assert(point.distance_to(Vector2(target.x,target.y)) <= 30.001, "Catch target escaped server anchor allowance")
	state.dive.mode = "boss"
	assert(entities.target_position(state.dive.targets[0]) == Vector2(state.dive.targets[0].x,state.dive.targets[0].y), "Boss anchors must remain fixed")
	print("PASS living fauna: %d water/terrain/speed samples over 60 seconds, 29 creatures, 5 behaviors, 2 animation clips, player/predator reactions, separation, depth currents, 7200 bounded catch positions" % samples)
	entities.queue_free()
	fauna.queue_free()
	player.queue_free()
	quit()
