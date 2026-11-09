extends SceneTree

class Walker extends Node2D:
	var traversal_state: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../scripts/tests/fixtures/ground-query-consumers.json"))
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var state: Node = root.get_node("GameState")
	var original_world: Dictionary = state.world
	var account_before := JSON.stringify({"player":state.player,"dive":state.dive})
	var samples: Array = []
	var mismatches: Array[String] = []
	var manifest: Dictionary = world.landMaps.hub
	if int(manifest.layoutVersion) != int(expected.layoutVersion):
		printerr("GROUND CONSUMERS: review changed layout before running frozen expectations")
		quit(1)
		return
	state.world = world
	var traversal = load("res://scripts/SurfaceTraversal.gd").new()
	traversal.configure(manifest)
	var walker := Walker.new()
	var foley = load("res://scripts/WorldFoley.gd").new()
	foley.configure(walker,"hub")
	var renderer = load("res://scripts/land/LandWorld3D.gd").new()
	renderer.map = manifest
	renderer._cache_ground_queries()
	for sample in expected.cases:
		var point := Vector2(float(sample.point[0]),float(sample.point[1]))
		walker.position = point
		walker.traversal_state = traversal.sample(point,Vector2(0,-100),1.0/60.0)
		var actual: Dictionary = walker.traversal_state
		var material: String = foley.material_at(point)
		var rendered_height: float = renderer.ground_height(point)
		var differences: Array[String] = []
		if absf(float(actual.groundHeight)-float(sample.groundHeight))>.0001:
			differences.append("traversal-ground")
		if bool(actual.onConnector)!=bool(sample.onConnector):
			differences.append("connector")
		if str(actual.footstepMaterial)!=str(sample.material):
			differences.append("traversal-material")
		if material!=str(sample.material):
			differences.append("foley-material")
		if absf(rendered_height-float(sample.groundHeight))>.0001:
			differences.append("renderer-ground")
		if not is_zero_approx(float(actual.bodyLift)) or absf(float(actual.paceScale)-float(sample.paceScale))>.0001:
			differences.append("body-lift-or-pace")
		samples.append({"expected":sample,"traversal":actual.duplicate(true),"foleyMaterial":material,"rendererHeight":rendered_height,"differences":differences})
		for difference in differences: mismatches.append(str(sample.point)+":"+difference)
	state.world = original_world
	if JSON.stringify({"player":state.player,"dive":state.dive})!=account_before:
		mismatches.append("account-mutation")
	foley.free()
	walker.free()
	renderer.free()
	var directory := "res://../artifacts/godot/ground-query-consumers-"+str(Time.get_unix_time_from_system()).replace(".","-")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var output := FileAccess.open(directory+"/results.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"outcome":"passed" if mismatches.is_empty() else "failed","layoutVersion":manifest.layoutVersion,"samples":samples,"mismatches":mismatches,"limits":"Actual point-query components only; no body rendering, audible footstep or browser/device claim"},"  "))
	output.close()
	print("GROUND CONSUMERS samples=",samples.size()," mismatches=",mismatches.size()," results=",directory+"/results.json")
	if not mismatches.is_empty(): printerr("GROUND CONSUMERS FAILED: ",mismatches)
	quit(0 if mismatches.is_empty() else 1)
