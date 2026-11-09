extends "res://../scripts/tests/nala-production-gait.gd"

var terrain_cases:Array=[]
var declared_setups:=0

func _terrain_case(profile:Dictionary,reverse:bool,reduced:bool,label:String) -> bool:
	clock.reduced_motion=reduced
	var a:Vector2=profile.end if reverse else profile.start
	var b:Vector2=profile.start if reverse else profile.end
	var heading:Vector2=(b-a).normalized()
	var origin:=a-heading*20.0
	if not _check(collision.is_walkable(origin),"Terrain setup outside actual authoritative floor "+label): return false
	_reset_case(origin,"daily")
	declared_setups+=1
	input_driver.set("logical_heading",heading)
	_input(Vector2.ZERO)
	_controller_enabled(true)
	await physics_frame
	await process_frame
	_controller_enabled(false)
	renderer.call("_process",0.0)
	last_delta=0.0
	var prior:=checks
	_measure(label+" idle")
	if checks==prior: return false
	sample_log.store_line(JSON.stringify({"case":label+" idle","fixtureInitial":true,"position":[player.position.x,player.position.y],"pose":renderer.actors_3d.counts.nalaLowerBody.duplicate(true)}))
	sample_log.flush()
	player.get("land_path").call("reset",origin)
	player.get("swim_sprite").call("consume_foot_contacts")
	elapsed_physics=0.0
	logical_travel=0.0
	physical_travel=0.0
	legacy_contacts=0
	prior_planner_contacts=0
	windows.clear()
	began_usec=Time.get_ticks_usec()
	last_physics_frame=Engine.get_physics_frames()
	var entered:=false
	var crossed:=false
	var stopped:=false
	var observations:=0
	_controller_enabled(true)
	for index in range(240):
		if not await _production_tick(Vector2.RIGHT,label+" travel"): return false
		observations+=1
		var progress:float=(player.position-a).dot(b-a)/(b-a).length_squared()
		if progress>=0.0 and progress<=1.0: entered=true
		if not stopped and progress>=.45 and progress<=.8:
			for stop_frame in range(10):
				if not await _production_tick(Vector2.ZERO,label+" stop-on-connector"): return false
			var before_pause:Dictionary=renderer.actors_3d.counts.nalaLowerBody.duplicate(true)
			player.frozen=true
			clock.clock_paused=true
			for pause_frame in range(2):
				if not await _production_tick(Vector2.ZERO,label+" paused-on-connector"): return false
			if not _check(renderer.actors_3d.counts.nalaLowerBody==before_pause,"Actual terrain pause changed planted rig "+label): return false
			player.frozen=false
			clock.clock_paused=false
			stopped=true
		if entered and progress>1.2:
			crossed=true
			break
	_controller_enabled(false)
	terrain_cases.append({"case":label,"profileId":profile.id,"profileType":profile.type,"reverse":reverse,"reduced":reduced,"controller":"actual hub Player; its enforced daily outfit","entered":entered,"crossed":crossed,"stopPauseRestart":stopped,"observations":observations,"position":[player.position.x,player.position.y],"physicsSeconds":elapsed_physics,"windows":windows.duplicate(true),"noRootPlacementAfterDeclaredSetup":true})
	FileAccess.open(output+"/terrain-cases.json",FileAccess.WRITE).store_string(JSON.stringify(terrain_cases,"  "))
	return _check(entered and crossed and stopped,"Terrain route did not enter/cross/stop/restart "+label)

func run() -> void:
	root.size=Vector2i(1440,810)
	physical_pilot=true
	capture=OS.get_environment("NALA_LOWER_CAPTURE")=="1"
	capture_stride=clampi(int(OS.get_environment("NALA_LOWER_CAPTURE_STRIDE")) if OS.has_environment("NALA_LOWER_CAPTURE_STRIDE") else 2,1,24)
	output=OS.get_environment("NALA_LOWER_OUTPUT") if OS.has_environment("NALA_LOWER_OUTPUT") else "res://../artifacts/godot/nala-production-terrain-"+str(int(Time.get_unix_time_from_system()))
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Preserve prior terrain evidence; select fresh output"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	sample_log=FileAccess.open(output+"/samples.jsonl",FileAccess.WRITE)
	capture_log=FileAccess.open(output+"/frames.jsonl",FileAccess.WRITE)
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
	var hashes:Dictionary={}
	for path in ["res://scripts/Player.gd","res://scripts/NalaPhysicalMotion.gd","res://scripts/NalaFootPlant.gd","res://scripts/NalaLowerBody3D.gd","res://scripts/CharacterVisual.gd","res://scripts/land/LandWorld3D.gd","res://scripts/land/LandGeometry.gd","res://../scripts/tests/nala-production-gait.gd","res://../scripts/tests/nala-production-terrain.gd","res://../scripts/tests/nala-lower-body.gd"]: hashes[path]=FileAccess.get_sha256(path)
	var filter:=OS.get_environment("NALA_TERRAIN_PROFILE")
	var first:=maxi(0,int(OS.get_environment("NALA_TERRAIN_FIRST")))
	var limit:=maxi(1,int(OS.get_environment("NALA_TERRAIN_CASES"))) if OS.has_environment("NALA_TERRAIN_CASES") else 16
	FileAccess.open(output+"/source.json",FileAccess.WRITE).store_string(JSON.stringify({"files":hashes,"fixtureWorldSha256":FileAccess.get_sha256("res://../.runtime/world-map.json"),"profileFilter":filter,"firstCase":first,"caseLimit":limit,"actualController":"Player","outfit":"daily enforced by actual hub Player","physicalContract":PhysicalMotion.gait_contract(),"postAccelerationLimiter":true,"acceptedPositionLimiter":true,"fixturePathInput":true,"continuousXYMetricIgnoresTreadZ":true,"geometryAcceptance":"pending actual triangle/pixel checks","nativeAcceptance":false,"naturalWalkingAccepted":false},"  "))
	_open("daily")
	var scheduled:=0
	for reduced in [false,true]:
		for profile in renderer.get("_stair_queries"):
			if not filter.is_empty() and str(profile.id)!=filter: continue
			for reverse in [false,true]:
				if scheduled<first:
					scheduled+=1
					continue
				if terrain_cases.size()>=limit: break
				var label:=str(profile.id)+"/"+str(reverse)+"/"+str(reduced)
				if not await _terrain_case(profile,bool(reverse),bool(reduced),label): return
				scheduled+=1
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify(frames,"  "))
	FileAccess.open(output+"/terrain-results.json",FileAccess.WRITE).store_string(JSON.stringify({"cases":terrain_cases,"geometrySamples":checks,"declaredSetups":declared_setups,"complete16Cases":filter.is_empty() and first==0 and terrain_cases.size()==16,"allEightFlatHeadings":"separate production-gait fixture; not eight stair-side crossings","naturalWalkingAccepted":false,"armOppositionAccepted":false},"  "))
	if not _check(JSON.stringify({"world":state.world,"player":state.player})==unchanged,"Terrain fixture changed authoritative source data"): return
	controller.free()
	print("NALA PHYSICAL TERRAIN PASS ",checks," actual triangle/opaque-foot samples/",terrain_cases.size()," daily controller cases; native/arms unaccepted.")
	quit(0)
