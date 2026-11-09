extends "res://../scripts/tests/nala-restart-body-budget.gd"

func run() -> void:
	output=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Upper approach fixture needs fresh evidence path"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var context_path:="res://../scripts/tests/fixtures/nala-stair-upper-approach-08bbf42.json"
	var context:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(context_path))
	var data_path:="res://resources/art/player-lower-body/male-nusantara-daily-v1.json"
	if not _check(FileAccess.get_sha256("res://../.runtime/world-map.json")==str(context.worldSha256) and FileAccess.get_sha256(data_path)==str(context.dataSha256),"Upper approach canonical world or original foot changed"): return
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	physical_pilot=true
	_open("daily")
	var profile:Dictionary={}
	for candidate in renderer.get("_stair_queries"):
		if str(candidate.id)==str(context.connectorId): profile=candidate
	if not _check(not profile.is_empty(),"Upper approach missing actual connector"): return
	var heading:Vector2=(Vector2(profile.start)-Vector2(profile.end)).normalized()
	var origin:Vector2=Vector2(profile.end)-heading*20.0
	var world_delta:Vector3=renderer.ground_point(origin+heading)-renderer.ground_point(origin)
	var at:Vector2=origin+heading*10.0/Vector2(world_delta.x,world_delta.y).length()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data_path))
	var body_view:Dictionary=data.views[context.bodyDirectionAtBegin]
	var foot_view:Dictionary=data.views[context.footDirection]
	var leg:Dictionary=foot_view.legs.right
	var texture:Texture2D=load(str(data.source))
	var image:Image=texture.get_image()
	if image.is_compressed(): image.decompress()
	var basis:Basis=renderer.camera_3d.global_basis.orthonormalized()
	var geometry:Dictionary={"id":"daily/"+str(context.footDirection)+"/right","leg":leg,"vertices":FootPlane.opaque_vertices(image,int(foot_view.sourceColumn),leg.parts.foot),"plane":Quaternion.IDENTITY,"pivot":Vector3.ZERO,"right":basis.x,"vertical":basis.y.z}
	var planner:=preload("res://scripts/NalaFootPlant.gd").new()
	planner.configure(renderer,PhysicalMotion.gait_contract())
	planner.set("_heading",heading)
	planner.set("_right",basis.x)
	planner.set("_landing_geometry",{"right":geometry})
	var offset:float=float(body_view.legs.right.parts.foot[0])+float(body_view.legs.right.solePixel[0])-64.0
	var support:Vector2=_two(context.supportLogical)
	planner.set("_feet",{"left":{"logical":support,"plant":_three(context.supportWorld),"grounded":true},"right":{"logical":_two(context.fromLogical),"sole":_three(context.fromWorld),"lateralOffset":offset,"grounded":false}})
	var provisional:Vector2=_two(context.oldTarget)
	var actual:=planner.call("_next_tread","right",at,provisional) as Dictionary
	if not _check(bool(actual.get("valid",false)) and str(actual.supportClassification)=="upper_flat_approach" and not bool(actual.actorOnConnector) and not bool(actual.supportOnConnector),"Upper flat was still aliased to a real highest tread"): return
	var across:=Vector2(-heading.y,heading.x)
	var lane:float=(provisional-Vector2(profile.end)).dot(across)
	var expected:Vector2=Vector2(profile.end)+across*lane
	if not _check(Vector2(actual.target).distance_to(expected)<.003 and float(actual.landingHeight)==float(profile.to) and int(actual.landingOrdinal)==int(profile.steps),"Upper approach skipped the genuine highest contact"): return
	if not _check(planner.landing_geometry_supported(actual.target,geometry),"Upper approach original opaque foot does not fit actual floor"): return
	var feet:Dictionary=planner.get("_feet")
	feet.left.logical=actual.target
	feet.left.plant=renderer.ground_point(actual.target)
	var next:=planner.call("_next_tread","right",at,provisional) as Dictionary
	if not _check(bool(next.get("valid",false)) and str(next.supportClassification)=="actual_tread" and int(next.landingOrdinal)==int(profile.steps)-1,"A genuine boundary support failed to unlock the next lower tread"): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"context":context,"contextSha256":FileAccess.get_sha256(context_path),"plannerSha256":FileAccess.get_sha256("res://scripts/NalaFootPlant.gd"),"actorAtBegin":at,"originalFoot":geometry.id,"approach":actual,"afterHypotheticalCanonicalBoundarySupport":next,"movingAnnuliProof":false,"intermediateContactPosesValidated":false,"naturalAccepted":false},"  "))
	print("NALA UPPER APPROACH PASS actual canonical membership, genuine original-foot96 support before84; movement/both-leg guards pending")
	controller.free()
	quit(0)
