extends SceneTree

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
		var unsafe := Vector2(float(map.obstacles[0].x)+10,float(map.obstacles[0].y)+10)
		assert(collision.is_walkable(collision.nearest_walkable(unsafe)),"Unsafe legacy save must recover to real ground")
		collision.free()
	assert(JSON.stringify({"player":state.player,"dive":state.dive})==before,"Geometry may not change player resources or progression")
	print("COMPONENT LAND PASS: ",count," real floor/prop/route samples in hub and forest, default blocked water, physics bodies and safe save recovery")
	quit()
