extends SceneTree

const Predicate=preload("res://scripts/land/LandGeometry.gd")
var checks:=0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition:bool,message:String) -> bool:
	if condition:
		checks+=1
		return true
	printerr("GROUND QUERY CANONICAL FAILED: ",message)
	quit(1)
	return false

func _run() -> void:
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../scripts/tests/fixtures/ground-query-canonical.json"))
	var world:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	var renderer=load("res://scripts/land/LandWorld3D.gd").new()
	var area:=""
	var legacy_mismatches:=0
	for sample in expected.cases:
		if str(sample.area)!=area:
			area=str(sample.area)
			renderer.map=world.landMaps[area]
			renderer._cache_ground_queries()
			if not _check(int(renderer.map.layoutVersion)==int(expected.metadata[area].layoutVersion),"Review changed manifest version before regenerating expected corpus"): return
			var ids:Array=[]
			for surface in renderer.map.surfaces: ids.append(str(surface.id))
			if not _check(ids==expected.metadata[area].surfaceIds,"Frozen surface order/priority identity changed"): return
		var point:=Vector2(float(sample.point[0]),float(sample.point[1]))
		var matches:Array=[]
		var floor_height:=0.0
		var priority:=-10000
		for index in range(renderer._surface_queries.size()):
			var surface:Dictionary=renderer._surface_queries[index]
			var inside:=Predicate.point_in_polygon(point,surface.canonicalPolygon)
			if inside!=Geometry2D.is_point_in_polygon(point,surface.polygon): legacy_mismatches+=1
			if not inside: continue
			matches.append(index)
			if int(surface.priority)>=priority:
				priority=int(surface.priority)
				floor_height=float(surface.height)
		if not _check(matches==sample.matches,"Canonical surface membership "+str(sample)): return
		if not _check(absf(floor_height-float(sample.floorHeight))<.000001,"Priority/last-surface floor winner "+str(sample)): return
		if not _check(absf(renderer.ground_height(point)-float(sample.groundHeight))<.0001,"Actual ground_height endpoint/connector "+str(sample)): return
	for sample in expected.polygonCases:
		var point:=Vector2(float(sample.point[0]),float(sample.point[1]))
		if not _check(Predicate.point_in_polygon(point,sample.polygon)==bool(sample.inside),"Scalar edge/concave/strict boundary case "+str(sample)): return
	# Preserve the actual priority30 endpoint regression independently of the generated corpus.
	renderer.map=world.landMaps.hub
	renderer._cache_ground_queries()
	for y in [1124.989990234375,1124.9990234375,1125.0]:
		if not _check(absf(renderer.ground_height(Vector2(1135.271484375,y))-48.0)<.000001,"Dock upper endpoint must not fall to height0 just outside connector"): return
	renderer.free()
	print("GROUND QUERY CANONICAL PASS ",expected.cases.size()," actual ground samples + ",expected.polygonCases.size()," independent scalar cases; checks=",checks," legacy Geometry2D membership differences=",legacy_mismatches)
	quit(0)
