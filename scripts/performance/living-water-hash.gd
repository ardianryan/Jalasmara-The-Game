extends SceneTree

const ITERATIONS:=10000
const ROUNDS:=9
const LIMIT_MS:=5000
var sink:=0

func _initialize() -> void: run.call_deferred()
func run() -> void:
	var input:=OS.get_environment("WORLD_HASH_INPUT")
	assert(not input.is_empty() and FileAccess.file_exists(input),"WORLD_HASH_INPUT must name the generated local WORLD JSON")
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(input))
	var contours:Array=world.get("terrainContours",[])
	assert(not contours.is_empty())
	var points:=0
	for contour in contours: points+=contour.size()
	var expected:=hash(contours)
	for warmup in range(2000): sink=sink ^ hash(world.get("terrainContours",[]))
	var costs:Array[float]=[]
	var cached:Array[float]=[]
	var started:=Time.get_ticks_msec()
	for round_index in range(ROUNDS):
		assert(Time.get_ticks_msec()-started<LIMIT_MS,"Bounded CPU probe exceeded its time budget")
		var tick:=Time.get_ticks_usec()
		for iteration in range(ITERATIONS):
			var world_id:=hash(world.get("terrainContours",[]))
			if world_id==expected: sink=sink ^ world_id
		costs.append(float(Time.get_ticks_usec()-tick)/ITERATIONS)
		tick=Time.get_ticks_usec()
		for iteration in range(ITERATIONS):
			var world_id:=expected
			if world_id==expected: sink=sink ^ world_id
		cached.append(float(Time.get_ticks_usec()-tick)/ITERATIONS)
	costs.sort()
	cached.sort()
	var report:Dictionary={"kind":"isolated-native-variant-hash-cost","engine":Engine.get_version_info().string,"cpu":OS.get_processor_name(),"os":OS.get_name(),"contourCount":contours.size(),"pointCount":points,"contourJsonBytes":JSON.stringify(contours).to_utf8_buffer().size(),"contourSha256":JSON.stringify(contours).sha256_text(),"iterationsPerRound":ITERATIONS,"rounds":ROUNDS,"fullHashUsPerCall":{"median":costs[ROUNDS>>1],"min":costs[0],"max":costs[-1],"sortedRoundAverages":costs},"cachedReadReferenceUsPerCall":{"median":cached[ROUNDS>>1],"min":cached[0],"max":cached[-1],"sortedRoundAverages":cached},"elapsedMs":Time.get_ticks_msec()-started,"limits":["Godot native hash plus source-style lookup/comparison only; no game frame, GPU, particle update or API work measured.","Cached read is a reference loop, not an implemented production invalidation strategy or a measured game speedup.","This local CPU is not a Windows or Samsung S23 measurement."]}
	var output:=OS.get_environment("WORLD_HASH_OUTPUT")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE)
		assert(file!=null)
		file.store_string(JSON.stringify(report,"  ")+"\n")
	print("WATER HASH COST ",JSON.stringify(report))
	quit()
