extends SceneTree

const BASE := Vector2(454,610)
const OUTLINE := [Vector2(338,449),Vector2(395,407),Vector2(467,430),Vector2(528,480),Vector2(553,558),Vector2(483,549),Vector2(475,609),Vector2(434,620),Vector2(411,537),Vector2(335,530)]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var state := root.get_node("GameState")
	var saved_world: Dictionary = state.world
	var before := JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})
	var actors := Node2D.new()
	actors.y_sort_enabled = true
	root.add_child(actors)
	var tree = load("res://scripts/ForestOcclusion.gd").new()
	tree.configure(load("res://resources/art/forest-muara.png"),BASE,OUTLINE,22.0,1.5625,[Vector2(438,535),Vector2(474,530),Vector2(477,610),Vector2(434,620)])
	actors.add_child(tree)
	assert(tree.trunk!=null and tree.trunk.material==null,"Solid wood must remain opaque, fixed and unaffected by foliage shader")
	var actor := Node2D.new()
	actors.add_child(actor)
	var solid_leaf_samples := 0
	var alpha_gap_samples := 0
	for y in range(407,620,8):
		for x in range(335,553,8):
			var world_point := Vector2(x,y)*1.5625
			if not Geometry2D.is_point_in_polygon(tree.to_local(world_point),tree.crown.polygon): continue
			var alpha: float = tree.alpha_at_world(world_point)
			if alpha>0.8: solid_leaf_samples += 1
			if alpha<0.05: alpha_gap_samples += 1
	assert(solid_leaf_samples>20 and alpha_gap_samples>20,"Foreground must retain leaves while excluding soil/gaps")
	tree.set_focus(actor)
	actor.position = Vector2(740,880)
	tree._process(1.0)
	var behind: Dictionary = tree.debug_status()
	assert(is_equal_approx(float(behind.footY),BASE.y*1.5625),"Sorting anchor must be at the trunk foot")
	assert(behind.behind,"Actor behind trunk must sort behind the tree")
	assert(behind.headCovered and behind.fadeActive and behind.alphaAtHead>0.35,"Head under foliage must receive localized readability fade")
	assert(behind.leafMasked,"Opaque map crops must not become foreground soil cards")
	actor.position = Vector2(740,1000)
	tree._process(1.0)
	var front: Dictionary = tree.debug_status()
	assert(not front.behind,"Actor in front must sort ahead of the tree")
	assert(tree.find_children("*","CollisionObject2D",true,false).is_empty(),"Canopy must not introduce crown-wide collision")
	var environment := root.get_node_or_null("EnvironmentState")
	var saved_reduced := false
	if environment != null:
		saved_reduced = bool(environment.snapshot().get("reduced_motion",false))
		environment.set_reduced_motion(true)
		tree._process(1.0)
		var reduced: Dictionary = tree.debug_status()
		assert(is_equal_approx(float(reduced.footY),float(front.footY)))
		assert(is_zero_approx(float(reduced.sway)),"Reduced motion must stop canopy sway")
		environment.set_reduced_motion(saved_reduced)
	assert(JSON.stringify({"world":state.world,"player":state.player,"dive":state.dive})==before,"Land canopy must not change world or account state")
	actors.free()
	state.world = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var forest = load("res://scripts/Forest.gd").new()
	root.add_child(forest)
	forest.set_process(false)
	forest.set_physics_process(false)
	forest.avatar.set_physics_process(false)
	await physics_frame
	await physics_frame
	var query := PhysicsPointQueryParameters2D.new()
	query.position = BASE*1.5625
	var trunk_hits: Array = forest.get_world_2d().direct_space_state.intersect_point(query)
	assert(not trunk_hits.is_empty(),"Actual Forest trunk is not physically blocked")
	var trunk_found := false
	for hit in trunk_hits:
		for shape_node in hit.collider.find_children("*","CollisionShape2D",true,false):
			if shape_node.shape is CircleShape2D:
				assert(shape_node.shape.radius<50,"Tree crown incorrectly became a wide trunk collider")
				trunk_found = true
	assert(trunk_found,"Expected a compact circular trunk collider")
	query.position = Vector2(740,880)
	assert(forest.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Accessible space under canopy is blocked")
	forest.free()
	var hub = load("res://scripts/HubScenery.gd").new()
	hub.configure(state.world.hub)
	root.add_child(hub)
	var hub_actors := Node2D.new()
	hub_actors.y_sort_enabled = true
	root.add_child(hub_actors)
	var hub_player = load("res://scripts/Player.gd").new()
	hub_actors.add_child(hub_player)
	hub_player.set_physics_process(false)
	hub.add_foreground_to(hub_actors)
	await physics_frame
	await physics_frame
	assert(state.world.hub.treeTrunks.size()==7)
	var recovered: Vector2 = hub.nearest_walkable(Vector2(870,780))
	assert(hub.is_walkable(recovered),"A legacy saved position inside the corrected rock must recover onto safe ground")
	assert(recovered.distance_to(Vector2(870,780))<=192,"Recovery must stay near the saved location")
	for trunk in state.world.hub.treeTrunks:
		var foot := Vector2(float(trunk.x),float(trunk.y))
		assert(not hub.is_walkable(foot),"Hub trunk must be rejected by the player land mask")
		query.position = foot
		var hits: Array = hub.get_world_2d().direct_space_state.intersect_point(query)
		var compact := false
		for hit in hits:
			if hit.collider.global_position.distance_to(foot)>0.1: continue
			for shape_node in hit.collider.find_children("*","CollisionShape2D",true,false):
				if shape_node.shape is CircleShape2D and is_equal_approx(shape_node.shape.radius,float(trunk.radius)): compact = true
		assert(compact,"Hub root needs the actual compact physics collider from shared metadata")
	var hub_trees: Array = hub.get("_trees")
	assert(hub_trees.size()==7,"Expected seven real hub root-anchored trees")
	for hub_tree in hub_trees:
		assert(hub_tree.trunk!=null and hub_tree.trunk.material==null)
		for index in range(hub_tree.trunk.polygon.size()):
			var projected: Vector2 = hub_tree.position+hub_tree.trunk.polygon[index]
			var painted: Vector2 = hub_tree.trunk.uv[index]*1.5625
			assert(projected.distance_to(painted)<0.01,"Wood was offset from the painted trunk")
	var selected: Node2D = hub_trees[0]
	hub_player.position = Vector2(780,637)
	assert(hub.is_walkable(hub_player.position))
	selected.update_occlusion()
	assert(selected.debug_status().behind and selected.debug_status().headCovered)
	hub_player.position = Vector2(925.625,944.375)
	assert(hub.is_walkable(hub_player.position))
	selected.update_occlusion()
	assert(not selected.debug_status().behind)
	assert(not hub.is_walkable(Vector2(870.625,704.375)),"Painted rock must block proof traversal")
	assert(not hub.is_walkable(Vector2(870.625,859.375)),"Painted rock edge must remain blocked")
	assert(hub.debug_status().sortByFeet)
	hub.free()
	hub_actors.free()
	state.world = saved_world
	print("LAND OCCLUSION PASS: trunk-foot sorting, front/behind state, masked leaf foreground, actual blocked compact trunk, accessible canopy space, seven UV-aligned hub wood layers and real Player sorting, no canopy collider or world/progression mutation")
	quit()
