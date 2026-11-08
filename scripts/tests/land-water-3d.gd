extends SceneTree

class WaterProjectionFixture extends Node3D:
	func map_point(point: Vector2,height := 0.0) -> Vector3:
		return Vector3(point.x,-point.y/cos(PI/4)-height,height)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var state := root.get_node("GameState")
	var before := JSON.stringify({"player":state.player,"dive":state.dive})
	for area in ["hub","forest"]:
		var projection := WaterProjectionFixture.new()
		root.add_child(projection)
		var water = load("res://scripts/land/LandWater3D.gd").new()
		projection.add_child(water)
		water.configure(projection,world.landMaps[area])
		water.set_process(false)
		var first: Dictionary = water.debug_status()
		assert(first.mesh and first.vertexWaves and first.shoreFoam and first.rainRings)
		assert(first.waterCells>0 and not first.walkable)
		assert(first.directionalFlow==(area=="forest"),"River currents must be distinct from coastal surface motion")
		var arrays: Array = water.mesh_instance.mesh.surface_get_arrays(0)
		assert(arrays[Mesh.ARRAY_VERTEX].size()==32*24*6,"Waves need a subdivided mesh, not only four moving corners")
		var a: float = water.elapsed
		water._process(3.0)
		assert(water.elapsed>a+2.9)
		assert(float(water.material.get_shader_parameter("clock"))==water.elapsed)
		var environment := root.get_node("EnvironmentState")
		environment.reduced_motion = true
		water._process(0.1)
		assert(float(water.material.get_shader_parameter("motion"))<=0.2)
		environment.reduced_motion = false
		projection.free()
	assert(JSON.stringify({"player":state.player,"dive":state.dive})==before)
	print("LAND WATER 3D PASS: two area shoreline masks, subdivided real mesh, animated waves/foam/rain, reduced motion and unchanged account state")
	quit()
