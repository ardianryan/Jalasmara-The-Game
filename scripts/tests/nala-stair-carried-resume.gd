extends "res://../scripts/tests/nala-restart-body-budget.gd"

const StairCurve=preload("res://scripts/NalaStairSupportCurve.gd")

func run() -> void:
	output=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Carried stair fixture needs fresh evidence path"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var context_path:="res://../scripts/tests/fixtures/nala-stair-carry-a7e7ace.json"
	var context:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(context_path))
	var data_path:="res://resources/art/player-lower-body/male-nusantara-daily-v1.json"
	if not _check(FileAccess.get_sha256("res://../.runtime/world-map.json")==str(context.worldSha256) and FileAccess.get_sha256(data_path)==str(context.dataSha256),"Carried stair source geometry or world changed"): return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data_path))
	if not _check(FileAccess.get_sha256(str(data.source))==str(context.atlasSha256),"Carried stair original bitmap changed"): return
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
	var view:Dictionary=data.views[context.footDirection]
	var body:Dictionary=data.views[context.bodyDirection]
	var image:Image=load(str(data.source)).get_image()
	if image.is_compressed(): image.decompress()
	var basis:Basis=renderer.camera_3d.global_basis.orthonormalized()
	var geometry:Dictionary={"id":"daily/"+str(context.footDirection)+"/left","leg":view.legs.left,"bodyLeg":body.legs.left,"bodyFootViewSteps":1,"vertices":FootPlane.opaque_vertices(image,int(view.sourceColumn),view.legs.left.parts.foot),"plane":Quaternion.IDENTITY,"pivot":_three(context.initialPivot),"right":basis.x,"vertical":basis.y.z}
	var raw_start:=_three(context.fromWorld)
	var target:=_three(context.toWorld)
	var before:=geometry.duplicate(true)
	if not _check((raw_start+Vector3(geometry.pivot)+FootPlane.ankle_offset(geometry,Quaternion.IDENTITY)).distance_to(_three(context.initialAnkle))<.003,"Carried source start does not reproduce the original actual ankle"): return
	var plan:=StairCurve.build(renderer,profile,_two(context.fromLogical),_two(context.toLogical),raw_start,target,geometry,10.0,true)
	if not _check(bool(plan.get("supported",false)) and bool(plan.valid) and bool(plan.carriedResume),"Real carried ascending resume unexpectedly unsupported: "+str(plan)): return
	if not _check(geometry==before and float(plan.distance)==float(context.expectedDistance) and absf(float(plan.arcXYZ)-float(context.expectedArcXYZ))<.003 and absf(float(plan.curveSpeedBound)-float(context.expectedBound))<.001,"Carried path changed pivot or disagrees with independent CPU geometry"): return
	if not _check(plan.knots.size()==context.expectedKnots.size(),"Carried resume skipped a remaining riser"): return
	for index in range(plan.knots.size()):
		if not _check(Vector3(plan.knots[index]).distance_to(_three(context.expectedKnots[index]))<.003,"Carried original-corner waypoint changed"): return
	for u in [0.0,1.0]:
		var point:=StairCurve.sample(renderer,plan,u)
		if not _check(bool(point.valid) and Vector3(point.world).distance_to(raw_start if u==0 else target)<.003,"Carried resume changed its retained endpoint"): return
	if not _check(StairCurve.floor_stitch(plan,1.0)==0 and StairCurve.floor_stitch(plan,1.0-1e-6)<1e-6,"Carried contact stitch has a nonzero terminal jump"): return
	var broken:=geometry.duplicate(true)
	broken.bodyFootViewSteps=2
	if not _check(not bool(StairCurve.build(renderer,profile,_two(context.fromLogical),_two(context.toLogical),raw_start,target,broken,10.0,true).supported),"Unproved multi-view carried transition was accepted"): return
	broken=geometry.duplicate(true)
	broken.bodyLeg.ankle[1]+=1
	if not _check(not bool(StairCurve.build(renderer,profile,_two(context.fromLogical),_two(context.toLogical),raw_start,target,broken,10.0,true).supported),"Unproved vertical source-ankle change was accepted"): return
	if not _check(not bool(StairCurve.build(renderer,profile,_two(context.fromLogical),_two(context.toLogical),raw_start,target,geometry,10.0).supported),"Fresh default silently accepted a carried pivot"): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"context":context,"contextSha256":FileAccess.get_sha256(context_path),"helperSha256":FileAccess.get_sha256("res://scripts/NalaStairSupportCurve.gd"),"plan":plan,"coupledMovementProof":false,"futureViewChangesIncludedInCertificate":false,"naturalAccepted":false},"  "))
	print("NALA CARRIED STAIR PASS original NORTH/C start, remaining risers/derived budget/continuous exact contact and unsupported-family guards; coupled movement pending")
	controller.free()
	quit(0)
