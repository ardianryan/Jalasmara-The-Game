extends SceneTree

const FootPlane=preload("res://scripts/NalaFootPlane.gd")
const StairCurve=preload("res://scripts/NalaStairSupportCurve.gd")

func _initialize() -> void: call_deferred("run")

func _check(valid:bool,message:String) -> bool:
	if not valid:
		push_error(message)
		quit(1)
	return valid

func _geometry(data:Dictionary,image:Image,direction:String) -> Dictionary:
	var view:Dictionary=data.views[direction]
	var leg:Dictionary=view.legs.left
	return {"leg":leg,"vertices":FootPlane.opaque_vertices(image,int(view.sourceColumn),leg.parts.foot),"right":Vector3(sqrt(.5),-sqrt(.5),0),"vertical":cos(deg_to_rad(35))}

func run() -> void:
	var output:=OS.get_environment("NALA_LOWER_OUTPUT")
	if not _check(not output.is_empty() and not DirAccess.dir_exists_absolute(output),"Stair view fixture needs fresh evidence"): return
	DirAccess.make_dir_recursive_absolute(output)
	var path:="res://../scripts/tests/fixtures/nala-stair-view-441add7.json"
	var context:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var data_path:="res://resources/art/player-lower-body/male-nusantara-daily-v1.json"
	if not _check(FileAccess.get_sha256(data_path)==str(context.dataSha256),"Stair view original source changed"): return
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data_path))
	var image:Image=load(str(data.source)).get_image()
	if image.is_compressed(): image.decompress()
	var plan:Dictionary={"curveType":"stair_swept_support","physicalRiserNormal":Vector2(0,1),"leadingOriginalCorner":float(context.plannedLeading),"initialPivot":Vector3.ZERO}
	var original:=StairCurve.view_envelope(plan,_geometry(data,image,str(context.originalView)),Vector3.ZERO,Quaternion.IDENTITY)
	var pivot:=Vector3(float(context.currentPivot[0]),float(context.currentPivot[1]),float(context.currentPivot[2]))
	var failed:=StairCurve.view_envelope(plan,_geometry(data,image,str(context.candidateView)),pivot,Quaternion.IDENTITY)
	if not _check(bool(original.supported) and not bool(failed.supported) and absf(float(failed.leading)-5.58701)<.003,"Original frozen envelope did not reject the actual leading-corner failure"): return
	var geometry:=_geometry(data,image,"north_east")
	var old_ankle:=FootPlane.ankle_offset(_geometry(data,image,"east"),Quaternion.IDENTITY)
	var rotated:=old_ankle-FootPlane.ankle_offset(geometry,Quaternion.IDENTITY)
	var early:=StairCurve.view_envelope(plan,geometry,rotated,Quaternion.IDENTITY)
	if not _check(not bool(early.supported),"Earlier EAST to NE handover still enters an uncertified remaining path"): return
	if not _check(not bool(StairCurve.view_envelope(plan,geometry,Vector3(NAN,0,0),Quaternion.IDENTITY).supported),"Invalid pivot accepted"): return
	if not _check(not bool(StairCurve.view_envelope(plan,geometry,Vector3.ZERO,Quaternion(Vector3.RIGHT,.1)).supported),"Unproved rotated stair plane accepted"): return
	if not _check(bool(StairCurve.view_envelope({"curveType":"ramp_support_profile"},geometry,Vector3.ZERO,Quaternion.IDENTITY).supported),"Ordinary ramp handover was changed"): return
	FileAccess.open(output+"/results.json",FileAccess.WRITE).store_string(JSON.stringify({"context":context,"contextSha256":FileAccess.get_sha256(path),"helperSha256":FileAccess.get_sha256("res://scripts/NalaStairSupportCurve.gd"),"original":original,"failed":failed,"earlierHandover":early,"movingProof":false,"naturalAccepted":false},"  "))
	print("NALA STAIR VIEW ENVELOPE PASS original mask, actual failing corner, earlier handover and unsupported-family guards; moving recovery remains pending")
	quit(0)
