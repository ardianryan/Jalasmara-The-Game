extends SceneTree

class Walker extends Node2D:
	var traversal_state: Dictionary = {}

class LegacyTraversal extends "res://scripts/SurfaceTraversal.gd":
	func _surface_at(point: Vector2) -> Dictionary:
		var selected: Dictionary = {}
		for surface in _hub.get("surfaces",[]):
			var polygon := PackedVector2Array()
			for vertex in surface.get("polygon",[]): polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
			if Geometry2D.is_point_in_polygon(point,polygon) and (selected.is_empty() or int(surface.get("priority",0))>=int(selected.get("priority",0))): selected = surface
		return selected

class LegacyFoley extends "res://scripts/WorldFoley.gd":
	var baseline_state: Node
	func material_at(point: Vector2) -> String:
		var maps: Dictionary = baseline_state.world.get("landMaps",{})
		var map: Dictionary = maps.get(area,{})
		if _has_traversal:
			var traversal: Dictionary = actor.get("traversal_state")
			if bool(traversal.get("onConnector",false)):
				var surface := str(traversal.get("footstepMaterial",""))
				if FOOTSTEPS.has(surface): return surface
		for stair in map.get("stairs",[]):
			var path: Array = stair.get("path",[])
			if path.size()<2: continue
			for index in range(path.size()-1):
				var a := Vector2(float(path[index][0]),float(path[index][1]))
				var b := Vector2(float(path[index+1][0]),float(path[index+1][1]))
				var progress := (point-a).dot(b-a)/maxf(1,(b-a).length_squared())
				if progress>=0 and progress<=1 and point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b)) <= float(stair.get("width",90))/2:
					var surface := str(stair.get("material","stone"))
					if FOOTSTEPS.has(surface): return surface
		var selected := ""
		var priority := -INF
		var elevation := -INF
		for surface in map.get("surfaces",[]):
			var polygon := PackedVector2Array()
			for vertex in surface.get("polygon",[]): polygon.append(Vector2(float(vertex[0]),float(vertex[1])))
			if polygon.size()<3 or not Geometry2D.is_point_in_polygon(point,polygon): continue
			var candidate := str(surface.get("material",""))
			var candidate_priority := float(surface.get("priority",0))
			var candidate_elevation := float(surface.get("elevation",0))
			if FOOTSTEPS.has(candidate) and (candidate_priority>priority or (candidate_priority==priority and candidate_elevation>elevation)):
				selected = candidate
				priority = candidate_priority
				elevation = candidate_elevation
		return selected

const BASELINE_COMMIT := "4795d28"
const BASELINE_SURFACE_BODY_SHA256 := "a66cdae37d9cc5c8591973483c8abb6cb42b05623ab3d948b963a36167e31dee"
const BASELINE_FOLEY_BODY_SHA256 := "23fd12f66bd37c707641ce2f04290f28d256186766c251771a641769b2f1cd56"
const ROUNDS := 3
const REPEATS := 5
const BUDGET_USEC := 17000000
var _deadline := 0
var _records: Array = []
var _instances: Array = []
var _original_world: Dictionary = {}
var _output := ""

func _initialize() -> void:
	_run.call_deferred()

func _batch(query: Callable, points: Array[Vector2], states: Array, actor: Node2D, repeats: int, material: bool) -> Dictionary:
	var start := Time.get_ticks_usec()
	var checksum := 0.0
	var count := 0
	for repetition in range(repeats):
		for index in range(points.size()):
			if count%32==0 and Time.get_ticks_usec()>=_deadline:
				return {"completed":false,"queries":count,"microseconds":Time.get_ticks_usec()-start,"checksum":checksum}
			actor.traversal_state=states[index]
			var value = query.call(points[index])
			checksum+=float(str(value).length()) if material else float(value.get("elevation",0))
			count+=1
	return {"completed":true,"queries":count,"microseconds":Time.get_ticks_usec()-start,"checksum":checksum}

func _finish(completed: bool, reason: String, start: int, metadata: Dictionary) -> void:
	var summary: Array = []
	for area in ["hub","forest"]:
		for consumer in ["surface","foley"]:
			for mode in ["legacy_packed","canonical_cached_exact"]:
				var values: Array[float] = []
				for record in _records:
					if record.area==area and record.consumer==consumer and record.mode==mode and record.completed and record.pairComplete:
						values.append(float(record.microseconds)/float(record.queries))
				values.sort()
				if not values.is_empty():
					summary.append({"area":area,"consumer":consumer,"mode":mode,"pairs":values.size(),"medianUsec":values[values.size()/2],"minUsec":values[0],"maxUsec":values[-1]})
	var state: Node = root.get_node("GameState")
	state.world = _original_world
	for instance in _instances:
		if instance is Node: instance.free()
	_instances.clear()
	var result := {"completed":completed,"reason":reason,"wallMicroseconds":Time.get_ticks_usec()-start,"budgetMicroseconds":BUDGET_USEC,"metadata":metadata,"raw":_records,"summary":summary,"limits":"Hot point-query bodies only. Alternating AB/BA same324 corpus points; cache build excluded. Legacy checksums can differ because membership is wrong. No full sample(), render, FPS, Windows or S23 claim. Partial pairs excluded."}
	FileAccess.open(_output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GROUND CONSUMER BENCHMARK ","COMPLETE" if completed else "INCOMPLETE"," ",JSON.stringify({"output":_output,"summary":summary,"wallMicroseconds":result.wallMicroseconds}))
	quit(0 if completed else 2)

func _run() -> void:
	var start := Time.get_ticks_usec()
	_deadline = start+BUDGET_USEC
	_output = "res://../artifacts/godot/ground-consumers-benchmark-"+str(Time.get_unix_time_from_system()).replace(".","-")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_output))
	var corpus_path := "res://../scripts/tests/fixtures/ground-query-canonical.json"
	var world_path := "res://../.runtime/world-map.json"
	var corpus: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(corpus_path))
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(world_path))
	var state: Node = root.get_node("GameState")
	_original_world = state.world
	state.world = world
	var metadata := {"baselineCommit":BASELINE_COMMIT,"baselineSurfaceBodySHA256":BASELINE_SURFACE_BODY_SHA256,"baselineFoleyBodySHA256":BASELINE_FOLEY_BODY_SHA256,"baselineFoleyWorldAccess":"Same GameState Node captured before timing; standalone baseline replaces only global alias with cached reference","corpusSHA256":FileAccess.get_sha256(corpus_path),"manifestSHA256":FileAccess.get_sha256(world_path),"engine":Engine.get_version_info(),"os":OS.get_name(),"cacheBuildIncluded":false,"points":corpus.cases.size(),"rounds":ROUNDS,"repeats":REPEATS,"sourceSHA256":{}}
	for path in ["res://scripts/SurfaceTraversal.gd","res://scripts/WorldFoley.gd","res://scripts/land/LandSurfaceQueryCache.gd","res://scripts/land/LandGeometry.gd","res://../scripts/benchmark-ground-consumers.gd"]:
		metadata.sourceSHA256[path]=FileAccess.get_sha256(path)
	if corpus.cases.size()!=324:
		_finish(false,"Expected frozen324 points",start,metadata)
		return
	for area in ["hub","forest"]:
		var map: Dictionary = world.landMaps[area]
		var ids: Array = []
		for surface in map.surfaces: ids.append(str(surface.id))
		if int(map.layoutVersion)!=int(corpus.metadata[area].layoutVersion) or ids!=corpus.metadata[area].surfaceIds:
			_finish(false,"Frozen manifest changed",start,metadata)
			return
		var actor := Walker.new()
		var canonical_traversal = load("res://scripts/SurfaceTraversal.gd").new()
		var legacy_traversal := LegacyTraversal.new()
		var canonical_foley = load("res://scripts/WorldFoley.gd").new()
		var legacy_foley := LegacyFoley.new()
		legacy_foley.baseline_state = state
		_instances.append_array([actor,canonical_traversal,legacy_traversal,canonical_foley,legacy_foley])
		canonical_traversal.configure(map)
		legacy_traversal.configure(map)
		canonical_foley.configure(actor,area)
		legacy_foley.configure(actor,area)
		var points: Array[Vector2] = []
		var states: Array = []
		for sample in corpus.cases:
			if str(sample.area)!=area: continue
			var point := Vector2(float(sample.point[0]),float(sample.point[1]))
			points.append(point)
			states.append(canonical_traversal.sample(point,Vector2(0,-100),1.0/60.0))
		for consumer in ["surface","foley"]:
			var canonical := Callable(canonical_traversal,"_surface_at") if consumer=="surface" else Callable(canonical_foley,"material_at")
			var legacy := Callable(legacy_traversal,"_surface_at") if consumer=="surface" else Callable(legacy_foley,"material_at")
			for query in [legacy,canonical]:
				if not _batch(query,points,states,actor,1,consumer=="foley").completed:
					_finish(false,"Budget during warmup",start,metadata)
					return
			for round_index in range(ROUNDS):
				var order := [true,false] if round_index%2==0 else [false,true]
				var pair: Array = []
				for old in order:
					var record := _batch(legacy if old else canonical,points,states,actor,REPEATS,consumer=="foley")
					record.area=area
					record.consumer=consumer
					record.mode="legacy_packed" if old else "canonical_cached_exact"
					record.round=round_index
					record.pairComplete=false
					_records.append(record)
					pair.append(record)
					if not record.completed:
						_finish(false,"Budget reached; partial pair excluded",start,metadata)
						return
				for record in pair: record.pairComplete=true
	_finish(true,"All same-point AB/BA pairs completed",start,metadata)
