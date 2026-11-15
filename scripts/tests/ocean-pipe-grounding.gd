extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player = {"progress":{"day":2}}
	state.adventure = {"discoveries":[],"puzzles":[]}
	var entities: Node2D = load("res://scripts/Entities.gd").new()
	root.add_child(entities)
	var actors: Node3D = load("res://scripts/hybrid/OceanActors.gd").new()
	root.add_child(actors)
	actors.debug_counts = {"props":0}
	actors._mirror_props(entities,Vector2(4660,2630))
	var valve: Sprite3D = actors.sprites.get("puzzle:valve")
	var leak: Sprite3D = actors.sprites.get("hazard:leak_cave")
	assert(is_instance_valid(valve) and is_instance_valid(leak), "Both pipe visuals must be present")
	var valve_anchor := Vector2(4660,2630)
	var valve_center := Vector2(valve.position.x,-valve.position.y)
	assert(valve_center.distance_to(valve_anchor)<140.0, "Valve must remain within its server interaction range")
	var reef_top := INF
	for entry in state.world.terrain:
		if float(entry[0])<=valve_center.x and valve_center.x<=float(entry[0])+float(entry[2]) and float(entry[1])>=valve_center.y:
			reef_top=minf(reef_top,float(entry[1]))
	assert(is_finite(reef_top), "The valve needs a reef shelf below it")
	var valve_base := valve_center.y+135.0/2.0
	assert(reef_top-valve_base>=0.0 and reef_top-valve_base<=25.0, "Valve base must meet the reef shelf without sinking")
	var leak_center := Vector2(leak.position.x,-leak.position.y)
	assert(leak_center.distance_to(Vector2(4200,2470))<90.0, "Leak hazard visual must stay near its authoritative source")
	assert(leak_center.x>4200.0 and leak_center.y>2470.0, "Broken elbow must sit into the existing right-hand ledge")
	print("OCEAN PIPE GROUNDING PASS: valve shelf gap %.1f, authoritative markers and hazard unchanged" % (reef_top-valve_base))
	actors.queue_free()
	entities.queue_free()
	await process_frame
	quit()
