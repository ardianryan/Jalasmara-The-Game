extends "res://../scripts/tests/nala-production-gait.gd"

var boundary_log:FileAccess
var overspeed:Array=[]
var boundary_results:Array=[]

func _boundary_tick(input:Vector2,label:String) -> bool:
	_input(input)
	var before_tick:=Engine.get_physics_frames()
	await physics_frame
	await process_frame
	var observations:Array=[]
	for entry in input_driver.get("observations"):
		if int(entry.tick)>before_tick: observations.append(entry)
	if not _check(not observations.is_empty(),"No actual input-driver physics observation "+label): return false
	for index in range(observations.size()):
		var entry:Dictionary=observations[index]
		var before:Vector2=entry.position
		var after:Vector2=observations[index+1].position if index+1<observations.size() else player.position
		var logical_speed:=before.distance_to(after)*float(Engine.physics_ticks_per_second)
		var physical:Vector3=renderer.ground_point(after)-renderer.ground_point(before)
		var world_speed:=Vector2(physical.x,physical.y).length()*float(Engine.physics_ticks_per_second)
		var sampled_arc_speed:=_sampled_world_arc(before,after)*float(Engine.physics_ticks_per_second)
		if not _check(logical_speed<=PhysicalMotion.LOGICAL_CAP+.03,"Boundary input exceeded actual logical authority cap "+label): return false
		var record:={"case":label,"tick":entry.tick,"before":[before.x,before.y],"after":[after.x,after.y],"requested":[input.x,input.y],"delivered":entry.delivered,"gradient":entry.gradient,"logicalSpeed":logical_speed,"worldXYSpeed":world_speed,"independentlySampledArcSpeed":sampled_arc_speed,"inputOnly":true,"footGeometryChecked":false}
		if sampled_arc_speed>PhysicalMotion.WORLD_XY_SPEED+.03: overspeed.append(record)
		boundary_log.store_line(JSON.stringify(record))
		boundary_log.flush()
	return true

func _side_limits(profile:Dictionary) -> bool:
	var axis:Vector2=(Vector2(profile.end)-Vector2(profile.start)).normalized()
	var side:=Vector2(-axis.y,axis.x)
	var cases:Array=[]
	var old_rejections:=0
	for progress in [.1,.5,.9]:
		var middle:Vector2=Vector2(profile.start).lerp(profile.end,float(progress))
		for sign in [-1.0,1.0]:
			for direction in [-1.0,1.0]:
				var from:Vector2=middle+side*float(sign)*(float(profile.width)-.001*float(direction))
				var velocity:Vector2=side*float(sign)*float(direction)*100.0
				var proposed:=from+velocity/60.0
				if not collision.is_walkable(from) or not collision.is_walkable(proposed): continue
				var limited:=PhysicalMotion.limit_position(renderer,from,proposed,1.0/60.0)
				var arc:=_sampled_world_arc(from,limited)
				var original_arc:=_sampled_world_arc(from,proposed)
				if original_arc>100.0/60.0+.001: old_rejections+=1
				cases.append({"from":from,"proposed":proposed,"limited":limited,"actualSampledArc":arc,"unlimitedArc":original_arc})
				FileAccess.open(output+"/side-probes.json",FileAccess.WRITE).store_string(JSON.stringify(cases,"  "))
				if not _check(collision.is_walkable(limited),"Connector-side limiter invented non-walkable prefix"): return false
				if not _check(arc<=100.0/60.0+.001,"Connector-side limiter smeared a discontinuous XY jump"): return false
				if not _check(from.distance_to(limited)<=from.distance_to(proposed)+.0001 and (limited-from).dot(velocity)>=-.0001,"Connector-side limiter enlarged or reversed actual segment"): return false
	if not _check(cases.size()>=2 and old_rejections>=1,"Side probes missed actual walkable connector embedding discontinuity"): return false
	print("PHYSICAL CONNECTOR SIDE PASS ",cases.size()," actual-ground prefixes, original segments rejected=",old_rejections)
	return true

func _endpoint_diagnostics(profile:Dictionary,held:Vector2,tangent:Vector2,sign:float) -> void:
	var at:=player.position
	var positions:Array=[]
	for offset in [-.01,-.001,0.0,.001,.01]:
		var point:Vector2=at+tangent*sign*float(offset)
		var ground:Vector3=renderer.ground_point(point)
		var matching:Array=[]
		var queries:Array=renderer.get("_surface_queries")
		for index in range(queries.size()):
			var query:Dictionary=queries[index]
			if Geometry2D.is_point_in_polygon(point,query.polygon):
				matching.append({"id":renderer.map.surfaces[index].id,"priority":query.priority,"height":query.height})
		positions.append({"matchingSurfaceQueries":matching,"offset":offset,"logical":[point.x,point.y],"ground":[ground.x,ground.y,ground.z],"groundHeight":renderer.ground_height(point),"gradient":renderer.ground_gradient(point),"contact":preload("res://scripts/SurfaceTraversal.gd").connector_ground(profile,point)})
	var delivered:=PhysicalMotion.screen_input(renderer,held,at)
	var logical:Vector2=renderer.input_motion(delivered,at)
	var desired:Vector2=logical*100.0*float(player.get("traversal_state").get("paceScale",1.0))
	var step:=1.0/float(Engine.physics_ticks_per_second)
	var accelerated:Vector2=Vector2(player.velocity).move_toward(desired,step*850.0)
	var trials:Array=[]
	for velocity in [accelerated,tangent*sign*100.0]:
		var target:Vector2=at+Vector2(velocity)*step
		var cuts:=PhysicalMotion._segment_cuts(renderer,at,target)
		var spans:Array=[]
		for index in range(1,cuts.size()):
			var start:float=cuts[index-1]
			var end:float=cuts[index]
			var span:=end-start
			if span<.00000001: continue
			var probe:=minf(.001/maxf(.001,(target-at).length()),span*.25)
			var before:Vector3=renderer.ground_point(at.lerp(target,start))
			var after:Vector3=renderer.ground_point(at.lerp(target,end))
			var near_start:Vector3=renderer.ground_point(at.lerp(target,start+probe))
			var near_end:Vector3=renderer.ground_point(at.lerp(target,end-probe))
			var extension:=Vector2(near_end.x-near_start.x,near_end.y-near_start.y)*(probe/maxf(.000000001,span-2.0*probe))
			var expected_start:=Vector2(near_start.x,near_start.y)-extension
			var expected_end:=Vector2(near_end.x,near_end.y)+extension
			spans.append({"start":start,"end":end,"probe":probe,"before":[before.x,before.y,before.z],"after":[after.x,after.y,after.z],"nearStart":[near_start.x,near_start.y,near_start.z],"nearEnd":[near_end.x,near_end.y,near_end.z],"expectedStart":[expected_start.x,expected_start.y],"expectedEnd":[expected_end.x,expected_end.y],"startError":expected_start.distance_to(Vector2(before.x,before.y)),"endError":expected_end.distance_to(Vector2(after.x,after.y))})
		trials.append({"velocity":velocity,"target":target,"cuts":cuts,"limitedVelocity":PhysicalMotion.limit_velocity(renderer,at,velocity,step),"spans":spans})
	FileAccess.open(output+"/endpoint-diagnostic.json",FileAccess.WRITE).store_string(JSON.stringify({"at":[at.x,at.y],"actualVelocity":player.velocity,"desired":desired,"oneSidedPositions":positions,"trials":trials,"sourceOnlyInterpretationPending":true},"  "))

func run() -> void:
	physical_pilot=true
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	var unchanged:=JSON.stringify({"world":state.world,"player":state.player})
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	for action in ["left","right","up","down","interact","journal","inventory","map","character"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
		Input.action_release(action)
	if not _check(float(load("res://scripts/Player.gd").LAND_WALK_SPEED)==PhysicalMotion.LOGICAL_CAP,"Boundary fixture's authority cap differs from actual Player"): return
	output=OS.get_environment("NALA_LOWER_OUTPUT") if OS.has_environment("NALA_LOWER_OUTPUT") else "res://../artifacts/godot/nala-physical-boundary-"+str(int(Time.get_unix_time_from_system()))
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Preserve prior boundary-input evidence"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	boundary_log=FileAccess.open(output+"/physics.jsonl",FileAccess.WRITE)
	var hashes:Dictionary={}
	for path in ["res://scripts/Player.gd","res://scripts/NalaPhysicalMotion.gd","res://scripts/land/LandWorld3D.gd","res://scripts/land/LandViewProjection.gd","res://../scripts/tests/nala-production-gait.gd","res://../scripts/tests/nala-physical-boundary-input.gd"]: hashes[path]=FileAccess.get_sha256(path)
	FileAccess.open(output+"/source.json",FileAccess.WRITE).store_string(JSON.stringify({"files":hashes,"inputOnly":true,"footGeometryChecked":false,"naturalWalkingAccepted":false,"postAccelerationSegmentLimiter":true},"  "))
	_open("daily")
	player.set_meta("nala_lower_body_pilot",false)
	var wanted:=OS.get_environment("NALA_INPUT_PROFILE") if OS.has_environment("NALA_INPUT_PROFILE") else "dock_gangway"
	var profile:Dictionary={}
	for entry in renderer.get("_stair_queries"):
		if str(entry.id)==wanted: profile=entry
	if not _check(not profile.is_empty(),"Unknown actual connector profile "+wanted): return
	if not _side_limits(profile): return
	var tangent:Vector2=(Vector2(profile.end)-Vector2(profile.start)).normalized()
	var middle:Vector2=Vector2(profile.start).lerp(profile.end,.5)
	var gradient:Vector2=renderer.ground_gradient(middle)
	for sign in [1.0,-1.0]:
		var origin:Vector2=Vector2(profile.start)-tangent*15.0 if sign>0 else Vector2(profile.end)+tangent*15.0
		if not _check(collision.is_walkable(origin),"Actual connector approach is not walkable "+wanted): return
		player.position=origin
		player.velocity=Vector2.ZERO
		player.get("land_path").call("reset",origin)
		_input(Vector2.ZERO)
		_controller_enabled(true)
		await physics_frame
		await process_frame
		_controller_enabled(false)
		var logical:=tangent*float(sign)
		var held:Vector2=renderer.view_projection.logical_motion_to_view(logical,gradient.dot(logical)).normalized()
		var label:=wanted+"/"+str(sign)
		var entered:=false
		var crossed:=false
		var visited_frames:=0
		_controller_enabled(true)
		for frame in range(240):
			if not await _boundary_tick(held,label): return
			visited_frames+=1
			var progress:float=(player.position-Vector2(profile.start)).dot(Vector2(profile.end)-Vector2(profile.start))/float(profile.lengthSquared)
			if progress>=0 and progress<=1: entered=true
			if entered and ((sign>0 and progress>1.08) or (sign<0 and progress<-.08)):
				crossed=true
				break
		_controller_enabled(false)
		boundary_results.append({"case":label,"entered":entered,"crossed":crossed,"observations":visited_frames,"position":[player.position.x,player.position.y]})
		if not crossed: _endpoint_diagnostics(profile,held,tangent,float(sign))
		if not _check(crossed,"Held input did not traverse actual connector "+label): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":boundary_results,"overspeed":overspeed,"inputOnly":true,"footGeometryChecked":false,"naturalWalkingAccepted":false},"  "))
	if not _check(JSON.stringify({"world":state.world,"player":state.player})==unchanged,"Input diagnostic mutated authoritative data"): return
	controller.free()
	if not overspeed.is_empty():
		push_error("PHYSICAL INPUT REJECTED: logical inertia exceeded intended world speed at "+str(overspeed.size())+" actual connector ticks; proof retained")
		quit(1)
		return
	print("PHYSICAL BOUNDARY INPUT PASS actual held input across ",wanted," both directions. No foot-geometry or natural-walk acceptance.")
	quit(0)
