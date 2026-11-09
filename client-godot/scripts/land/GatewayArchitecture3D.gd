extends RefCounted

var _frames: Dictionary = {}

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _xyz(value: Vector3) -> Array:
	return [value.x,value.y,value.z]

func build(renderer: Node) -> void:
	_frames.clear()
	for gate in renderer.map.get("gateways",[]):
		_build_gate(renderer,gate)
	renderer._components["RouteAlignedGateways"]=_frames.size()

func debug_status() -> Dictionary:
	return _frames.duplicate(true)

func _box(renderer: Node,label: String,center: Vector3,size: Vector3,material: Material,record: Dictionary) -> void:
	var node: MeshInstance3D=renderer._box(label,center,size,material)
	var vertices: Array=[]
	var bounds:=node.mesh.get_aabb()
	for x in [0.0,1.0]:
		for y in [0.0,1.0]:
			for z in [0.0,1.0]:
				vertices.append(_xyz(node.global_transform*(bounds.position+bounds.size*Vector3(x,y,z))))
	record.meshes.append({"label":label,"center":_xyz(node.global_position),"right":_xyz(node.global_basis.x),"forward":_xyz(node.global_basis.y),"vertices":vertices})

func _build_gate(renderer: Node,gate: Dictionary) -> void:
	var parent: Node3D=renderer._geometry
	var frame:=Node3D.new()
	var id:=str(gate.id)
	var label:=str(gate.label)
	frame.name=id.validate_node_name()
	parent.add_child(frame)
	var right:=_point(gate.right)
	var forward:=_point(gate.forward)
	frame.transform=Transform3D(Basis(Vector3(right.x,right.y,0),Vector3(forward.x,forward.y,0),Vector3(0,0,1)),renderer.map_point(_point(gate.center),float(gate.elevation)*renderer.LEVEL_HEIGHT))
	var record: Dictionary={"center":gate.center,"postCenters":gate.postCenters,"postFootprints":gate.postFootprints,"crossing":gate.crossing,"colliderIds":gate.colliderIds,"roadSurfaceId":gate.roadSurfaceId,"roadSection":gate.roadSection,"halfSpan":gate.halfSpan,"right":gate.right,"forward":gate.forward,"meshes":[],"sideFences":[]}
	_frames[id]=record
	# Boxes and cylinders are authored in one rigid physical frame before static batching.
	renderer._geometry=frame
	var wood: Material=renderer._materials.get_material("wood")
	var bamboo: Material=renderer._materials.get_material("bamboo")
	var thatch: Material=renderer._materials.get_material("thatch")
	var stone: Material=renderer._materials.get_material("stone")
	if renderer._glow_material==null:
		renderer._glow_material=StandardMaterial3D.new()
		renderer._glow_material.albedo_color=Color("f4cc88")
		renderer._glow_material.emission_enabled=true
		renderer._glow_material.emission=Color("ffc773")
		renderer._glow_material.emission_energy_multiplier=.38
	var half_span:=float(gate.halfSpan)
	var a:=Vector3(-half_span,0,0)
	var b:=Vector3(half_span,0,0)
	var base_size:=_point(gate.baseSize)
	for post in [a,b]:
		_box(renderer,label+"_Base",post+Vector3(0,0,10),Vector3(base_size.x,base_size.y,20),stone,record)
		renderer._column(post+Vector3(0,0,16),post+Vector3(0,0,118),6.5,wood)
		renderer._column(post+Vector3(0,0,28),post+Vector3(0,0,112),4.0,bamboo)
	renderer._column(a+Vector3(0,0,98),b+Vector3(0,0,98),5.0,wood)
	renderer._column(a+Vector3(0,0,114),b+Vector3(0,0,114),6.0,bamboo)
	var span:=half_span*2+26
	_box(renderer,label+"_LintelRoof",Vector3(0,0,122),Vector3(span,26,12),thatch,record)
	_box(renderer,label+"_Signboard",Vector3(0,0,105),Vector3(span*.55,8,14),wood,record)
	var lamp_pos:=a.lerp(b,.18)+Vector3(0,0,84)
	_box(renderer,label+"_LanternGlass",lamp_pos,Vector3(9,9,14),renderer._glow_material,record)
	_box(renderer,label+"_LanternCap",lamp_pos+Vector3(0,0,8),Vector3(13,13,4),wood,record)
	_box(renderer,label+"_LanternBase",lamp_pos-Vector3(0,0,8),Vector3(13,13,4),wood,record)
	for obstacle in renderer.map.get("obstacles",[]):
		if gate.colliderIds.has(str(obstacle.id)) and str(obstacle.get("variant",""))!="gateway_post":
			_side_fence(renderer,frame,obstacle,record,bamboo)
	renderer._geometry=parent

func _side_fence(renderer: Node,frame: Node3D,obstacle: Dictionary,record: Dictionary,material: Material) -> void:
	var points: Array[Vector3]=[]
	for point in obstacle.footprint:
		points.append(frame.transform.affine_inverse()*renderer.map_point(_point(point),float(obstacle.get("elevation",0))*renderer.LEVEL_HEIGHT))
	var bounds:=AABB(points[0],Vector3.ZERO)
	for point in points: bounds=bounds.expand(point)
	# Existing Hub colliders are long roadside compounds; both visible edges follow their depth.
	var height:=float(obstacle.get("height3d",80))
	var count:=maxi(3,ceili(bounds.size.y/20))
	var support_count:=0
	for side in [-1.0,1.0]:
		var x:=bounds.get_center().x+side*(bounds.size.x*.5-4)
		for index in range(count):
			var y:=lerpf(bounds.position.y+4,bounds.end.y-4,float(index)/float(count-1))
			renderer._column(Vector3(x,y,0),Vector3(x,y,height),4,material)
			support_count+=1
		for z in [24.0,58.0]:
			_box(renderer,str(obstacle.id)+"_SideFenceRail",Vector3(x,bounds.get_center().y,z),Vector3(8,bounds.size.y-8,7),material,record)
	record.sideFences.append({"id":str(obstacle.id),"footprint":obstacle.footprint,"supportCount":support_count,"depth":bounds.size.y,"width":bounds.size.x})
