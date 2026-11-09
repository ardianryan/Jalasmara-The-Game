extends SceneTree

const Traversal=preload("res://scripts/SurfaceTraversal.gd")
const ROUNDS:=5
const REPEATS:=10
const BUDGET_USEC:=18000000
var renderer:Node2D
var deadline_usec:=0
var records:Array=[]
var warmups:Array=[]
var output:=""

func _initialize() -> void:
	_run.call_deferred()

func _legacy_height(point:Vector2) -> float:
	var elevation:=0.0
	var priority:=-10000
	for surface in renderer.get("_surface_queries"):
		if surface.priority>=priority and Geometry2D.is_point_in_polygon(point,surface.polygon):
			priority=surface.priority
			elevation=surface.height
	for stair in renderer.get("_stair_queries"):
		var contact:Dictionary=Traversal.connector_ground(stair,point)
		if not contact.is_empty(): elevation=float(contact.groundHeight)
	return elevation

func _batch(points:Array[Vector2],legacy:bool,repeats:int) -> Dictionary:
	var began:=Time.get_ticks_usec()
	var checksum:=0.0
	var queries:=0
	for repetition in range(repeats):
		for point in points:
			if queries%32==0 and Time.get_ticks_usec()>=deadline_usec:
				return {"completed":false,"queries":queries,"microseconds":Time.get_ticks_usec()-began,"checksum":checksum}
			checksum+=_legacy_height(point) if legacy else float(renderer.ground_height(point))
			queries+=1
	return {"completed":true,"queries":queries,"microseconds":Time.get_ticks_usec()-began,"checksum":checksum}

func _summary() -> Array:
	var summary:Array=[]
	for area in ["hub","forest"]:
		for mode in ["packed_geometry2d","canonical_scalar"]:
			var values:Array[float]=[]
			for record in records:
				if record.area==area and record.mode==mode and record.completed and record.pairCompleted:
					values.append(float(record.microseconds)/float(record.queries))
			values.sort()
			if values.is_empty(): continue
			var middle:=values.size()/2
			var median:float=values[middle] if values.size()%2==1 else (values[middle-1]+values[middle])*.5
			summary.append({"area":area,"mode":mode,"completePairs":values.size(),"usecPerQueryMedian":median,"usecPerQueryMin":values[0],"usecPerQueryMax":values[-1]})
	return summary

func _finish(completed:bool,reason:String,started:int,metadata:Dictionary,corpus:Dictionary) -> void:
	var result:Dictionary={"completed":completed,"reason":reason,"wallMicroseconds":Time.get_ticks_usec()-started,"runtimeBudgetMicroseconds":BUDGET_USEC,"plannedRounds":ROUNDS,"repeatsPerRound":REPEATS,"points":corpus.get("cases",[]).size(),"metadata":metadata,"warmups":warmups,"raw":records,"summary":_summary(),"correctnessChecked":false,"limits":"Hot query timing only; correctness remains ground-query-canonical. Legacy checksums may differ because its endpoint predicate is wrong. No FPS or device claim. Partial pairs excluded from summary."}
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	if is_instance_valid(renderer): renderer.free()
	print("GROUND QUERY BENCHMARK ","COMPLETE" if completed else "INCOMPLETE"," ",JSON.stringify({"output":output,"reason":reason,"wallMicroseconds":result.wallMicroseconds,"summary":result.summary}))
	quit(0 if completed else 2)

func _run() -> void:
	var started:=Time.get_ticks_usec()
	deadline_usec=started+BUDGET_USEC
	output=OS.get_environment("GROUND_QUERY_BENCH_OUTPUT")
	if output.is_empty(): output="res://../artifacts/godot/ground-query-benchmark-"+str(int(Time.get_unix_time_from_system()))
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)):
		printerr("GROUND QUERY BENCHMARK: preserve existing output ",output)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var corpus_path:="res://../scripts/tests/fixtures/ground-query-canonical.json"
	var manifest_path:="res://../.runtime/world-map.json"
	var corpus:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(corpus_path))
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	var metadata:Dictionary={"engine":Engine.get_version_info(),"os":OS.get_name(),"corpusSHA256":FileAccess.get_sha256(corpus_path),"manifestSHA256":FileAccess.get_sha256(manifest_path),"sourceSHA256":{},"areas":{},"cacheBuildIncluded":false,"order":"AB for even rounds, BA for odd rounds; fixed point order"}
	for path in ["res://scripts/land/LandGeometry.gd","res://scripts/land/LandWorld3D.gd","res://scripts/SurfaceTraversal.gd","res://../scripts/benchmark-ground-query.gd"]:
		metadata.sourceSHA256[path]=FileAccess.get_sha256(path)
	if corpus.cases.size()!=324 or int(world.landMaps.hub.layoutVersion)!=11:
		_finish(false,"Expected frozen324 points/hub layout11; review source before benchmark",started,metadata,corpus)
		return
	renderer=load("res://scripts/land/LandWorld3D.gd").new()
	for area in ["hub","forest"]:
		var map:Dictionary=world.landMaps[area]
		var ids:Array=[]
		for surface in map.surfaces: ids.append(str(surface.id))
		if ids!=corpus.metadata[area].surfaceIds or int(map.layoutVersion)!=int(corpus.metadata[area].layoutVersion):
			_finish(false,"Frozen manifest surface identity/order/version differs: "+area,started,metadata,corpus)
			return
		var points:Array[Vector2]=[]
		for sample in corpus.cases:
			if str(sample.area)==area: points.append(Vector2(float(sample.point[0]),float(sample.point[1])))
		renderer.map=map
		renderer._cache_ground_queries()
		metadata.areas[area]={"layoutVersion":map.layoutVersion,"points":points.size(),"surfaces":renderer.get("_surface_queries").size(),"connectors":renderer.get("_stair_queries").size()}
		for legacy in [true,false]:
			var warm:Dictionary=_batch(points,legacy,1)
			warm.area=area
			warm.mode="packed_geometry2d" if legacy else "canonical_scalar"
			warmups.append(warm)
			if not warm.completed:
				_finish(false,"Runtime budget reached during warmup",started,metadata,corpus)
				return
		for round_index in range(ROUNDS):
			var pair:Array=[]
			var order:Array=[true,false] if round_index%2==0 else [false,true]
			for legacy in order:
				var record:Dictionary=_batch(points,legacy,REPEATS)
				record.area=area
				record.mode="packed_geometry2d" if legacy else "canonical_scalar"
				record.round=round_index
				record.order="AB" if round_index%2==0 else "BA"
				record.pairCompleted=false
				pair.append(record)
				records.append(record)
				if not record.completed:
					_finish(false,"Runtime budget reached; partial pair excluded",started,metadata,corpus)
					return
			for record in pair: record.pairCompleted=true
	_finish(true,"All equal-count AB/BA pairs completed",started,metadata,corpus)
