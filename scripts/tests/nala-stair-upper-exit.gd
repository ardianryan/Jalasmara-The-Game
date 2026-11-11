extends "res://../scripts/tests/nala-restart-body-budget.gd"

func run() -> void:
	output=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Upper exit fixture needs fresh evidence path"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var path:="res://../scripts/tests/fixtures/nala-upper-exit-6b6a7e3.json"
	var context:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	if not _check(FileAccess.get_sha256("res://../.runtime/world-map.json")==str(context.worldSha256),"Upper exit canonical world changed"): return
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
	if not _check(not profile.is_empty(),"Upper exit missing actual profile"): return
	var heading:Vector2=(Vector2(profile.end)-Vector2(profile.start)).normalized()
	var basis:Basis=renderer.camera_3d.global_basis.orthonormalized()
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://resources/art/player-lower-body/male-nusantara-daily-v1.json"))
	var view:Dictionary=data.views[context.bodyDirection]
	var leg:Dictionary=view.legs.right
	var image:Image=load(str(data.source)).get_image()
	if image.is_compressed(): image.decompress()
	var geometry:Dictionary={"id":"daily/north_west/right","leg":leg,"vertices":FootPlane.opaque_vertices(image,int(view.sourceColumn),leg.parts.foot),"right":basis.x,"vertical":basis.y.z,"plane":Quaternion.IDENTITY,"pivot":Vector3.ZERO}
	var planner:=preload("res://scripts/NalaFootPlant.gd").new()
	planner.configure(renderer,PhysicalMotion.gait_contract())
	planner.set("_heading",heading)
	planner.set("_right",basis.x)
	planner.set("_landing_geometry",{"right":geometry})
	var at:=_two(context.at)
	var motion:Vector3=renderer.ground_point(at+heading)-renderer.ground_point(at)
	at-=heading*float(context.swingDistance)/Vector2(motion.x,motion.y).length()
	var offset:float=float(leg.parts.foot[0])+float(leg.solePixel[0])-64.0
	planner.set("_feet",{"left":{"logical":_two(context.supportLogical),"plant":_three(context.supportWorld),"grounded":true},"right":{"logical":_two(context.fromLogical),"sole":_three(context.fromWorld),"lateralOffset":offset,"grounded":false}})
	var plan:=planner.call("_next_tread","right",at,_two(context.oldTarget)) as Dictionary
	if not _check(bool(plan.get("valid",false)) and str(plan.landingClassification)=="upper_flat_exit" and str(plan.supportClassification)=="actual_tread","Genuine highest support failed upper exit classification: "+str(plan)): return
	var tangent:Vector2=(Vector2(profile.end)-Vector2(profile.start)).normalized()
	var across:=Vector2(-tangent.y,tangent.x)
	var boundary:Vector2=Vector2(profile.end)+across*(Vector2(plan.exitTargetRequested)-Vector2(profile.end)).dot(across)
	var depth:float=Vector2(renderer.ground_point(plan.target).x-renderer.ground_point(boundary).x,renderer.ground_point(plan.target).y-renderer.ground_point(boundary).y).length()
	if not _check(absf(depth-float(plan.treadDistance))<.003 and planner.landing_geometry_supported(plan.target,geometry),"Upper exit changed physical depth or original-mask floor/obstacle fit"): return
	var feet:Dictionary=planner.get("_feet")
	feet.left.logical=plan.target
	feet.left.plant=renderer.ground_point(plan.target)
	var next:=planner.call("_next_tread","right",at,plan.target-heading*10.0) as Dictionary
	if not _check(next.is_empty(),"Actual upper-flat support repeated an exit/boundary contact"): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"context":context,"contextSha256":FileAccess.get_sha256(path),"plannerSha256":FileAccess.get_sha256("res://scripts/NalaFootPlant.gd"),"plan":plan,"actualPhysicalDepth":depth,"afterHypotheticalOutsideSupport":next,"coupledMotionValidated":false,"thirdObstructedContactAccepted":false},"  "))
	print("NALA UPPER EXIT PASS actual highest-support classification, physical depth/full original mask/outside membership, no repeated exit; coupled movement pending")
	controller.free()
	quit(0)
