extends "res://../scripts/tests/nala-restart-body-budget.gd"

const StairCurve=preload("res://scripts/NalaStairSupportCurve.gd")

class NoInverse extends Node:
	func ground_point(_point:Vector2) -> Vector3: return Vector3.ZERO

func run() -> void:
	output=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Swept curve fixture needs fresh evidence path"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var context_path:="res://../scripts/tests/fixtures/nala-stair-swept-7e14c09.json"
	var context:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(context_path))
	if not _check(FileAccess.get_sha256("res://../.runtime/world-map.json")==str(context.fixtureWorldSha256),"Swept curve canonical world changed"): return
	var data_path:="res://resources/art/player-lower-body/male-nusantara-daily-v1.json"
	if not _check(FileAccess.get_sha256(data_path)==str(context.dataSha256),"Swept curve original source geometry changed"): return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data_path))
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
	if not _check(not profile.is_empty(),"Missing canonical stair profile"): return
	var view:Dictionary=data.views[context.footDirection]
	var leg:Dictionary=view.legs[context.side]
	var texture:Texture2D=load(str(data.source))
	var image:Image=texture.get_image()
	if image.is_compressed(): image.decompress()
	var camera_basis:Basis=renderer.camera_3d.global_basis.orthonormalized()
	var geometry:Dictionary={"id":"daily/"+str(context.footDirection)+"/"+str(context.side),"leg":leg,"vertices":FootPlane.opaque_vertices(image,int(view.sourceColumn),leg.parts.foot),"plane":Quaternion.IDENTITY,"pivot":Vector3.ZERO,"right":camera_basis.x,"vertical":camera_basis.y.z}
	var from:=_two(context.fromLogical)
	var to:=_two(context.toLogical)
	var first:=_three(context.fromWorld)
	var last:=_three(context.toWorld)
	var plan:=StairCurve.build(renderer,profile,from,to,first,last,geometry,10.0)
	if not _check(bool(plan.supported) and bool(plan.valid),"Canonical swept curve unexpectedly unsupported: "+str(plan)): return
	if not _check(float(plan.distance)==float(context.expectedDistance) and absf(float(plan.arcXYZ)-float(context.expectedArcXYZ))<.003,"Swept curve disagrees with independent CPU path budget"): return
	if not _check(plan.knots.size()==context.expectedKnots.size(),"Swept curve skipped a riser waypoint"): return
	for index in range(plan.knots.size()):
		if not _check(Vector3(plan.knots[index]).distance_to(_three(context.expectedKnots[index]))<.003,"Swept original-corner waypoint changed "+str(index)): return
	for u in [0.0,1.0]:
		var sampled:=StairCurve.sample(renderer,plan,u)
		if not _check(bool(sampled.valid) and Vector3(sampled.world).distance_to(first if u==0 else last)<.003,"Swept curve moved retained endpoints"): return
	var broken_profile:=profile.duplicate(true)
	broken_profile.steps=0
	if not _check(not bool(StairCurve.build(renderer,broken_profile,from,to,first,last,geometry,10.0).supported),"Zero treads became a supported straight chord"): return
	var broken_geometry:=geometry.duplicate(true)
	broken_geometry.vertical=NAN
	if not _check(not bool(StairCurve.build(renderer,profile,from,to,first,last,broken_geometry,10.0).supported),"Non-finite source basis accepted"): return
	broken_geometry=geometry.duplicate(true)
	broken_geometry.right=Vector3.ZERO
	if not _check(not bool(StairCurve.build(renderer,profile,from,to,first,last,broken_geometry,10.0).supported),"Degenerate foot direction accepted"): return
	if not _check(not bool(StairCurve.build(renderer,profile,to,from,last,first,geometry,10.0).supported),"DOWN scope silently adopted"): return
	if not _check(not bool(StairCurve.build(renderer,profile,from,from,first,first,geometry,10.0).supported),"Zero span accepted"): return
	var invalid_plan:=plan.duplicate(true)
	invalid_plan.lengths=PackedFloat64Array()
	if not _check(not bool(StairCurve.sample(renderer,invalid_plan,.5).valid),"Corrupt path sampled successfully"): return
	var absent:=NoInverse.new()
	var inverse_result:=StairCurve.sample(absent,plan,.5)
	absent.free()
	if not _check(not bool(inverse_result.valid),"Failed actual inverse was projected into a valid pose"): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"context":context,"contextSha256":FileAccess.get_sha256(context_path),"helperSha256":FileAccess.get_sha256("res://scripts/NalaStairSupportCurve.gd"),"plan":plan,"movingProof":false,"downAnatomyProof":false},"  "))
	print("NALA SWEPT STAIR CURVE PASS actual canonical profile/original mask, independent CPU knots, endpoint and failure guards; moving proof pending")
	controller.free()
	quit(0)
