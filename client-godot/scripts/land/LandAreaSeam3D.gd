extends RefCounted

var status: Dictionary = {}

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _frame(renderer: Node, gate: Dictionary, place: String) -> Transform3D:
	var segment: Array=gate.route.segment
	var forward: Vector3=(renderer.map_point(_point(segment[1]))-renderer.map_point(_point(segment[0]))).normalized()
	var right:=forward.cross(Vector3(0,0,1))
	var portal:=_point(segment[1 if place=="hub" else 0])
	return Transform3D(Basis(right,forward,Vector3(0,0,1)),renderer.map_point(portal,float(gate.elevation)*renderer.LEVEL_HEIGHT))

func _top(renderer: Node, label: String, points: PackedVector3Array, material: String) -> void:
	var planar:=PackedVector2Array()
	for point in points: planar.append(Vector2(point.x,point.y))
	var indices:=Geometry2D.triangulate_polygon(planar)
	if not indices.is_empty(): renderer._mesh(label,points,indices,renderer._materials.get_material(material))

func build(renderer: Node) -> void:
	status={}
	var maps: Dictionary=GameState.world.get("landMaps",{})
	var destination: String="forest" if renderer.area=="hub" else "hub"
	if not renderer.area in ["hub","forest"] or renderer.map.get("gateways",[]).is_empty(): return
	var remote: Dictionary=maps.get(destination,{})
	if remote.get("gateways",[]).is_empty(): return
	var local_gate: Dictionary=renderer.map.gateways[0]
	var remote_gate: Dictionary=remote.gateways[0]
	var local_frame:=_frame(renderer,local_gate,renderer.area)
	var remote_frame:=_frame(renderer,remote_gate,destination)
	var transform:=local_frame*remote_frame.affine_inverse()
	var direction:=1.0 if renderer.area=="hub" else -1.0
	# Both scenes share one portal plane; the adjacent map is a bounded visual preview.
	var clip:=PackedVector2Array()
	for uv in [Vector2(-410,0),Vector2(410,0),Vector2(410,860*direction),Vector2(-410,860*direction)]:
		clip.append(renderer.ground_projection(remote_frame*Vector3(uv.x,uv.y,0)))
	var surfaces:=0
	var vertices:=0
	for surface in remote.get("surfaces",[]):
		if surface.has("connectorId") or str(surface.material) in ["dock","bridge","wood"]: continue
		var height: float=float(surface.get("elevation",0))*renderer.LEVEL_HEIGHT+float(surface.get("priority",0))*.018
		if height<remote_frame.origin.z-2.0: continue
		for intersection in Geometry2D.intersect_polygons(renderer._polygon(surface.polygon),clip):
			var points:=PackedVector3Array()
			for point in intersection: points.append(transform*renderer.map_point(point,height))
			_top(renderer,"AdjacentAreaGround",points,str(surface.material))
			if int(surface.get("priority",0))==0:
				var local_polygon:=PackedVector2Array()
				for point in points: local_polygon.append(renderer.ground_projection(point))
				renderer._natural_edges.build_surface(renderer,{"id":"Adjacent_"+str(surface.id),"material":str(surface.material),"heightPixels":points[0].z},local_polygon,points[0].z)
			surfaces+=1
			vertices+=points.size()
	var road_half:=absf(float(local_gate.roadSection[1])-float(local_gate.roadSection[0]))*.5
	var remote_half:=absf(float(remote_gate.roadSection[1])-float(remote_gate.roadSection[0]))*.5
	var shoulder:=PackedVector3Array()
	var trail:=PackedVector3Array()
	# An irregular shoulder bridges the small difference between authored portal edges.
	for uv in [Vector2(-118,-24),Vector2(112,-24),Vector2(134,58),Vector2(111,130),Vector2(139,202),Vector2(-132,202),Vector2(-145,112),Vector2(-124,44)]:
		shoulder.append(local_frame*Vector3(uv.x,uv.y*direction,-.12))
	_top(renderer,"AreaSeamShoulder",shoulder,"grass")
	for uv in [Vector2(-road_half,0),Vector2(road_half,0),Vector2(remote_half,170*direction),Vector2(-remote_half,170*direction)]:
		trail.append(local_frame*Vector3(uv.x,uv.y,.42))
	_top(renderer,"AreaSeamTrail",trail,"dirt")
	var trees:=0
	var houses:=0
	var preview_centers: Array=[]
	for entry in remote.get("obstacles",[]):
		if str(entry.kind)!="tree": continue
		var feet:=Vector2(float(entry.x)+float(entry.width)*.5,float(entry.y)+float(entry.height)*.5)
		var at: Vector3=renderer.map_point(feet,float(entry.get("elevation",0))*renderer.LEVEL_HEIGHT)
		var relative: Vector3=remote_frame.affine_inverse()*at
		if relative.y*direction<100 or relative.y*direction>820 or absf(relative.x)>385: continue
		var center: Vector3=transform*at
		var preview: Dictionary=entry.duplicate()
		preview["vista"]=true
		renderer._tree(preview,Rect2(Vector2.ZERO,Vector2(float(entry.width),float(entry.height))),center)
		preview_centers.append([center.x,center.y,center.z])
		trees+=1
		if trees>=12: break
	for entry in remote.get("obstacles",[]):
		if str(entry.kind)!="house" or float(entry.get("elevation",0))*renderer.LEVEL_HEIGHT<remote_frame.origin.z-2.0: continue
		var rect:=Rect2(float(entry.x),float(entry.y),float(entry.width),float(entry.height))
		var at: Vector3=renderer.map_point(rect.get_center(),float(entry.get("elevation",0))*renderer.LEVEL_HEIGHT)
		var relative: Vector3=remote_frame.affine_inverse()*at
		if relative.y*direction<50 or relative.y*direction>650 or absf(relative.x)>300: continue
		var center: Vector3=transform*at
		var preview: Dictionary=entry.duplicate(true)
		var footprint: Array=[]
		for value in entry.get("footprint",[]):
			var mapped: Vector2=renderer.ground_projection(transform*renderer.map_point(_point(value),at.z))
			footprint.append([mapped.x,mapped.y])
		preview["footprint"]=footprint
		preview["id"]="Vista_"+str(entry.id)
		preview["elevation"]=center.z/renderer.LEVEL_HEIGHT
		renderer._house(preview,rect,center)
		houses+=1
		if houses>=3: break
	status={"destination":destination,"visualOnly":true,"surfaces":surfaces,"vertices":vertices,"trees":trees,"houses":houses,"treeCenters":preview_centers,"origin":[local_frame.origin.x,local_frame.origin.y,local_frame.origin.z],"forward":[local_frame.basis.y.x,local_frame.basis.y.y,local_frame.basis.y.z],"right":[local_frame.basis.x.x,local_frame.basis.x.y,local_frame.basis.x.z],"trailHalfWidth":road_half,"remoteTrailHalfWidth":remote_half,"previewDepth":860,"trail":[trail[0],trail[1],trail[2],trail[3]]}

func debug_status() -> Dictionary:
	return status.duplicate(true)
