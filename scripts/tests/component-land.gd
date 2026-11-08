extends SceneTree

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _polygon(values: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for value in values: polygon.append(_point(value))
	return polygon

func _check_bridges(map: Dictionary, collision) -> int:
	var bridges: Array = map.get("bridges",[])
	if str(map.id)!="forest": return 0
	assert(bridges.size()==2,"Forest needs two distinct authored river crossings")
	var decks: Array[PackedVector2Array] = []
	var centers: Array[Vector2] = []
	var samples := 0
	for bridge in bridges:
		var surface: Dictionary = {}
		for candidate in map.surfaces:
			if str(candidate.get("bridgeId",""))==str(bridge.id): surface=candidate
		assert(not surface.is_empty() and surface.material=="bridge","Each crossing must reference an actual bridge deck")
		decks.append(_polygon(surface.polygon))
		var a:=_point(bridge.path[0])
		var b:=_point(bridge.path[1])
		var axis:=(b-a).normalized()
		centers.append((a+b)*.5)
		assert(float(bridge.width)>=80,"Bridge needs room for the body between real rails")
		for step in range(55):
			var point:=a.lerp(b,float(step)/54.0)
			assert(collision.is_walkable(point),"Bridge centerline must remain open between physical rails")
			samples+=1
		for bank in [a-axis*20,b+axis*20]:
			assert(collision.is_walkable(bank),"Bridge must join actual traversable riverbanks")
		assert(bridge.railIds.size()==2,"Both rail edges need authoritative blockers")
		for rail_id in bridge.railIds:
			var rail: Dictionary = {}
			for obstacle in map.obstacles:
				if str(obstacle.id)==str(rail_id): rail=obstacle
			assert(not rail.is_empty() and rail.variant=="bridge_rail","Visible bridge rails must use the same obstacle metadata as physics")
			var center:=Vector2.ZERO
			for value in rail.footprint: center+=_point(value)
			center/=rail.footprint.size()
			assert(not collision.is_walkable(center),"Bridge rails cannot be traversed as decoration")
			var query:=PhysicsPointQueryParameters2D.new()
			query.position=center
			assert(not collision.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Each rail needs an actual physics shape")
	assert(Geometry2D.intersect_polygons(decks[0],decks[1]).is_empty(),"Separate river crossings must not form overlapping V-shaped decks")
	assert(centers[0].distance_to(centers[1])>250,"Two crossings must occupy distinct stretches of river")
	assert(not collision.is_walkable((centers[0]+centers[1])*.5),"The river between bridges must remain water")
	return samples

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var state := root.get_node("GameState")
	var before := JSON.stringify({"player":state.player,"dive":state.dive})
	var count := 0
	for area in ["hub","forest"]:
		var map: Dictionary = world.landMaps[area]
		var collision = load("res://scripts/land/LandCollision.gd").new()
		collision.configure(map)
		root.add_child(collision)
		await physics_frame
		var spawn := Vector2(float(map.spawn.x),float(map.spawn.y))
		assert(collision.is_walkable(spawn),area+" spawn must have an actual floor")
		assert(not collision.is_walkable(Vector2(20,1580)),"Unmodeled water is not a floor")
		for obstacle in map.obstacles:
			var center := Vector2(float(obstacle.x)+float(obstacle.width)/2,float(obstacle.y)+float(obstacle.height)/2)
			assert(not collision.is_walkable(center),"Roof, garden, rock, tree, crate and fence footprints must all block")
			var query := PhysicsPointQueryParameters2D.new()
			query.position = center
			assert(not collision.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Visible prop footprint needs a real physics body")
			count += 1
		for route in map.routes:
			for index in range(1,route.size()):
				var a := Vector2(float(route[index-1][0]),float(route[index-1][1]))
				var b := Vector2(float(route[index][0]),float(route[index][1]))
				var steps := maxi(1,ceili(a.distance_to(b)/6.0))
				for step in range(steps+1):
					assert(collision.is_walkable(a.lerp(b,float(step)/steps)),"Authored route crosses a solid or water in "+area)
					count += 1
		count += _check_bridges(map,collision)
		var unsafe := Vector2(float(map.obstacles[0].x)+10,float(map.obstacles[0].y)+10)
		assert(collision.is_walkable(collision.nearest_walkable(unsafe)),"Unsafe legacy save must recover to real ground")
		collision.free()
	assert(JSON.stringify({"player":state.player,"dive":state.dive})==before,"Geometry may not change player resources or progression")
	print("COMPONENT LAND PASS: ",count," real floor/prop/route samples in hub and forest, default blocked water, physics bodies, separate bank-connected bridges with solid rails, and safe save recovery")
	quit()
