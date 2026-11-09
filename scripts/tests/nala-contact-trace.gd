extends "res://../scripts/tests/nala-production-gait.gd"

func run() -> void:
	output=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Contact trace unit needs fresh evidence path"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var hashes:Dictionary={}
	for path in ["res://scripts/NalaFootPlant.gd","res://scripts/NalaLowerBody3D.gd","res://scripts/CharacterVisual.gd","res://../scripts/tests/nala-contact-trace.gd"]: hashes[path]=FileAccess.get_sha256(path)
	FileAccess.open(output+"/source.json",FileAccess.WRITE).store_string(JSON.stringify({"world":FileAccess.get_sha256("res://../.runtime/world-map.json"),"files":hashes,"scope":"raw planner offsets and final runtime-enabled Lower publication/pause; intermediate contact poses unvalidated"},"  "))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	clock.clock_paused=false
	physical_pilot=true
	_open("daily")
	var origin:=_origin()
	if not _check(origin.is_finite(),"Missing canonical flat probe floor"): return
	var planner:=preload("res://scripts/NalaFootPlant.gd").new()
	planner.configure(renderer,PhysicalMotion.gait_contract())
	var hips:Dictionary={"left":-5.0,"right":5.5}
	var right:Vector3=renderer.camera_3d.global_basis.orthonormalized().x
	planner.begin_contact_frame(true)
	planner.update(origin,false,false,hips,right,0.0)
	var walked:Dictionary=planner.update(origin+Vector2(54,0),true,false,hips,right,.54)
	var events:Array=walked.rawContactEvents
	if not _check(events.size()==2 and int(events[0].sequence)+1==int(events[1].sequence),"Macro update lost exact two contact transitions"): return
	if not _check(str(events[0].side)!=str(events[1].side) and str(events[0].purpose)=="walking" and str(events[1].purpose)=="walking","Contact trace inferred wrong step purpose"): return
	if not _check(absf(float(events[0].acceptedDistance)-10.0)<.003 and absf(float(events[1].acceptedDistance)-42.0)<.003,"Contact trace timestamps use frame end instead of consumed phase"): return
	var epoch:=int(walked.rawTraceEpoch)
	planner.begin_contact_frame(false)
	var discarded:Dictionary=planner.snapshot()
	if not _check(discarded.rawContactEvents.is_empty() and int(discarded.rawTraceEpoch)>epoch,"Unvalidated events survived next-frame rejection barrier"): return
	var settled:Dictionary=planner.update(origin+Vector2(54,0),false,false,hips,right,1.0)
	if not _check(settled.rawContactEvents.size()==1 and str(settled.rawContactEvents[0].purpose)=="settling" and float(settled.rawContactEvents[0].acceptedDistance)==54.0,"Real zero-distance replant was hidden or labelled walking"): return
	planner.begin_contact_frame(false)
	var paused:Dictionary=planner.update(origin+Vector2(54,0),false,true,hips,right,1.0)
	if not _check(paused.rawContactEvents.is_empty(),"Pause created or republished discarded raw contacts"): return
	_reset_case(origin,"daily")
	_input(Vector2.RIGHT)
	_controller_enabled(true)
	var published:Dictionary={}
	for index in range(60):
		await physics_frame
		await process_frame
		renderer.call("_process",1.0/float(Engine.physics_ticks_per_second))
		var actual:Dictionary=renderer.actors_3d.counts.get("nalaLowerBody",{})
		if not _check(bool(actual.get("enabled",false)),"Actual Lower rejected contact publication probe"): return
		if not actual.get("contactTrace",{}).get("events",[]).is_empty():
			published=actual.duplicate(true)
			break
	if not _check(not published.is_empty() and bool(published.contactTrace.finalPoseValidated) and not bool(published.contactTrace.intermediateContactPosesValidated),"Actual Lower never published guarded final-pose diagnostics"): return
	player.frozen=true
	clock.clock_paused=true
	await physics_frame
	await process_frame
	renderer.call("_process",0.0)
	_controller_enabled(false)
	var frozen_actual:Dictionary=renderer.actors_3d.counts.get("nalaLowerBody",{}).duplicate(true)
	if not _check(frozen_actual.contactTrace.events.is_empty() and frozen_actual.contacts.rawContactEvents.is_empty(),"Actual Lower echoed its prior nonempty batch on pause"): return
	var visual_before:Dictionary=published.duplicate(true)
	var visual_after:Dictionary=frozen_actual.duplicate(true)
	for visual_pose in [visual_before,visual_after]:
		visual_pose.erase("contactTrace")
		for key in ["rawContactEvents","rawTraceEpoch","rawTraceOverflow"]: visual_pose.contacts.erase(key)
	if not _check(visual_before==visual_after,"Clearing paused diagnostics changed actual frozen pose"): return
	var rejected_cache:Dictionary=published.duplicate(true)
	rejected_cache.enabled=false
	rejected_cache.reachValid=false
	var actual_rig:Node3D=renderer.actors_3d.get("_nala_lower")
	actual_rig.set("_last",rejected_cache)
	renderer.call("_process",0.0)
	var invalid_paused:Dictionary=renderer.actors_3d.counts.get("nalaLowerBody",{})
	if not _check(not bool(invalid_paused.contactTrace.finalPoseValidated) and invalid_paused.contactTrace.events.is_empty(),"Frozen invalid-cache lifecycle advertised final pose validation"): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"rawWalking":events,"rawSettlement":settled.rawContactEvents,"afterBarrier":discarded,"actualPublished":published,"actualPaused":frozen_actual,"invalidCachedPause":{"synthesizedLifecycleCache":true,"pose":invalid_paused},"intermediateContactPosesValidated":false,"audioWired":false,"naturalAccepted":false},"  "))
	print("NALA CONTACT TRACE PASS two exact raw transitions/phase offsets/real settlement/rejection barrier and actual Lower publication/pause without event replay; no transient-pose acceptance")
	controller.free()
	quit(0)
