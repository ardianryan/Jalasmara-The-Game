extends "res://../scripts/tests/nala-production-gait.gd"

const BodyBudget=preload("res://scripts/NalaRestartBodyBudget.gd")
const FootPlane=preload("res://scripts/NalaFootPlane.gd")

func _three(values:Array) -> Vector3: return Vector3(float(values[0]),float(values[1]),float(values[2]))
func _two(values:Array) -> Vector2: return Vector2(float(values[0]),float(values[1]))

func run() -> void:
	output=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"Frozen helper replay needs fresh evidence path"): return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var fixture_path:="res://../scripts/tests/fixtures/nala-restart-body-b05a211.json"
	var frozen:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(fixture_path))
	if not _check(FileAccess.get_sha256("res://../.runtime/world-map.json")==str(frozen.fixtureWorldSha256),"Frozen helper world changed"): return
	var data_path:="res://resources/art/player-lower-body/male-nusantara-daily-v1.json"
	if not _check(FileAccess.get_sha256(data_path)==str(frozen.dataSha256),"Frozen helper source geometry changed"): return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data_path))
	var state:=root.get_node("GameState")
	state.world=JSON.parse_string(FileAccess.get_file_as_string("res://../.runtime/world-map.json"))
	state.player={"appearance":"male_nusantara","progress":{"day":2,"stage":"dive"}}
	state.dive={}
	clock=root.get_node("EnvironmentState")
	clock.set_process(false)
	physical_pilot=true
	_open("daily")
	var right:Vector3=renderer.camera_3d.global_basis.orthonormalized().x
	var vertical:float=1.0/float(frozen.calibration)
	var feet:Dictionary={}
	var geometry:Dictionary={}
	for side in ["left","right"]:
		var foot:Dictionary=frozen.feet[side]
		var q:Array=foot.rotation
		var plane:=Quaternion(float(q[0]),float(q[1]),float(q[2]),float(q[3]))
		geometry[side]={"leg":data.views[foot.footDirection].legs[side],"bodyLeg":data.views[frozen.bodyDirection].legs[side],"right":right,"vertical":vertical,"plane":plane,"pivot":_three(foot.pivot)}
		# Captured output soles include C; the planner owns the raw sole.
		feet[side]={"sole":_three(foot.renderedSole)-_three(foot.pivot)}
		var ankle:Vector3=feet[side].sole+geometry[side].pivot+FootPlane.ankle_offset(geometry[side],plane)
		if not _check(ankle.distance_to(_three(foot.actualAnkle))<.001,"Frozen helper duplicated pivot or changed held source "+side): return
	var plan:Dictionary=frozen.plan.duplicate(true)
	plan.fromWorld=_three(plan.fromWorld)
	plan.toWorld=_three(plan.toWorld)
	for knot in plan.groundKnots:
		knot.world=_three(knot.world)
		knot.logical=_two(knot.logical)
	var before:=JSON.stringify(plan)
	var preview:=BodyBudget.propose(renderer,plan,str(frozen.side),feet,geometry,_two(frozen.at),_three(frozen.heading),float(frozen.bodyHeight),float(frozen.bodyRate))
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"fixture":frozen,"fixtureSha256":FileAccess.get_sha256(fixture_path),"helperSha256":FileAccess.get_sha256("res://scripts/NalaRestartBodyBudget.gd"),"preview":preview,"fullRuntimeProof":false},"  "))
	if not _check(JSON.stringify(plan)==before,"Frozen helper mutated original landing plan"): return
	if not _check(bool(preview.valid) and float(preview.distance)==float(frozen.expectedPreviewDistance),"Frozen helper diverged from original-marker/common-height preview: "+str(preview)): return
	if not _check(int(preview.markerQueries)==64 and int(preview.samples)==32 and int(preview.testedCandidates)==6,"Frozen helper repeated ground work per duration"): return
	print("NALA RESTART BODY BUDGET PASS frozen b05 context; distance=",preview.distance," marker inversions=",preview.markerQueries," microseconds=",preview.elapsedMicroseconds,"; coupled motion remains unaccepted")
	controller.free()
	quit(0)
