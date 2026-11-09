extends RefCounted

var roofs: Dictionary = {}
var support_count := 0
var _cutaway_shader: Shader
var _panels: Dictionary = {}

func _panel_material(renderer: Node, kind: String) -> ShaderMaterial:
	if _cutaway_shader==null:
		_cutaway_shader=Shader.new()
		var source: String=renderer.Materials.SHADER_SOURCE
		source=source.replace("varying vec3 at;", "uniform float roof_reveal = 0.0;\nuniform vec3 reveal_center;\nuniform vec3 reveal_right;\nuniform vec3 reveal_up;\nvarying vec3 at;")
		source=source.replace("ALBEDO=color;", """
	if (roof_reveal > 0.001) {
		vec3 offset = at - reveal_center;
		vec2 projected = vec2(dot(offset, reveal_right) / 24.0, dot(offset, reveal_up) / 52.0);
		float hole = 1.0 - smoothstep(0.82, 1.0, length(projected));
		if (hash(vec3(floor(at.xy / 3.0), 71.0)) < hole * roof_reveal) discard;
	}
	ALBEDO=color;""")
		_cutaway_shader.code=source
	var material: ShaderMaterial=renderer._materials.get_material(kind).duplicate()
	material.shader=_cutaway_shader
	return material

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func build(renderer: Node) -> void:
	roofs.clear()
	_panels.clear()
	support_count=0
	for shelter in renderer.map.get("shelters",[]):
		if bool(shelter.get("existing",false)): continue
		_awning(renderer,shelter)
	if renderer.area=="hub": _sasmita_understructure(renderer)
	renderer._components["AttachedShelterRoofs"]=roofs.size()
	renderer._components["ShelterCollisionPosts"]=support_count

func update(renderer: Node,delta: float) -> void:
	if not is_instance_valid(renderer.actor) or not is_instance_valid(renderer.camera_3d): return
	var position: Vector2=renderer.actor.position
	var center: Vector3=renderer.map_point(position,renderer.ground_height(position))+renderer.camera_3d.global_basis.y*40
	for id in _panels:
		var entry: Dictionary=_panels[id]
		var covered:=Geometry2D.is_point_in_polygon(position,entry.polygon)
		entry.amount=move_toward(float(entry.amount),1.0 if covered else 0.0,delta/(.14 if covered else .24))
		for material in entry.materials:
			material.set_shader_parameter("roof_reveal",entry.amount)
			if float(entry.amount)>.001:
				material.set_shader_parameter("reveal_center",center)
				material.set_shader_parameter("reveal_right",renderer.camera_3d.global_basis.x)
				material.set_shader_parameter("reveal_up",renderer.camera_3d.global_basis.y)

func _awning(renderer: Node, shelter: Dictionary) -> void:
	var wood: Material=renderer._materials.get_material("wood")
	var bamboo: Material=renderer._materials.get_material("bamboo")
	var roof_kind:=str(shelter.get("material","thatch"))
	var roof_material:=_panel_material(renderer,roof_kind)
	var soffit_material:=_panel_material(renderer,"bamboo")
	var elevation: float=float(shelter.elevation)*renderer.LEVEL_HEIGHT
	var corners: Array[Vector3]=[]
	for index in range(4):
		var height:=float(shelter.attachmentHeight if index<2 else shelter.outerHeight)
		corners.append(renderer.map_point(_point(shelter.roof[index]),elevation)+Vector3(0,0,height))
	var id:=str(shelter.id)
	var polygon:=PackedVector2Array()
	for point in shelter.roof: polygon.append(_point(point))
	_panels[id]={"materials":[roof_material,soffit_material],"polygon":polygon,"amount":0.0}
	roofs[id]=corners.duplicate()
	renderer._face(id+"_Roof",corners,roof_material)
	var bottom: Array[Vector3]=[]
	for point in corners: bottom.append(point-Vector3(0,0,5))
	var soffit: Array[Vector3]=[bottom[3],bottom[2],bottom[1],bottom[0]]
	renderer._face(id+"_Soffit",soffit,soffit_material)
	for index in range(4):
		var next:=(index+1)%4
		var fascia: Array[Vector3]=[corners[index],corners[next],bottom[next],bottom[index]]
		renderer._face(id+"_Fascia",fascia,renderer._materials.get_material(roof_kind))
	for index in range(6):
		var fraction:=float(index)/5
		renderer._column(bottom[0].lerp(bottom[1],fraction),bottom[3].lerp(bottom[2],fraction),2.4,wood)
	for pair in [[0,1],[3,2]]:
		renderer._column(bottom[pair[0]],bottom[pair[1]],4.5,wood)
	for value in shelter.posts:
		var at: Vector3=renderer.map_point(_point(value),elevation)
		# The same ten-unit square is present in the authoritative obstacle map.
		renderer._box(id+"_Post",at+Vector3(0,0,float(shelter.outerHeight)*.5),Vector3(10,10/cos(renderer.TILT),float(shelter.outerHeight)),wood)
		var top:=at+Vector3(0,0,float(shelter.outerHeight)-6)
		var toward_wall: Vector3=(bottom[0]-bottom[3]).normalized()
		renderer._column(top-Vector3(0,0,24),top+toward_wall*25,2.8,bamboo)
		support_count+=1

func _sasmita_understructure(renderer: Node) -> void:
	var wood: Material=renderer._materials.get_material("wood")
	var bamboo: Material=renderer._materials.get_material("bamboo")
	var stone: Material=renderer._materials.get_material("stone")
	var floor_height: float=2.0*renderer.LEVEL_HEIGHT
	var corners: Array[Vector3]=[]
	for point in [Vector2(48,395),Vector2(272,395),Vector2(272,725),Vector2(48,725)]:
		corners.append(renderer.map_point(point,floor_height))
	var bed: Array[Vector3]=[]
	for point in corners: bed.append(Vector3(point.x,point.y,-110))
	var bed_face: Array[Vector3]=[bed[3],bed[2],bed[1],bed[0]]
	renderer._face("SasmitaSubmergedFoundationBed",bed_face,renderer._materials.get_material("sand"))
	for index in range(4):
		var next:=(index+1)%4
		var top:=corners[index]-Vector3(0,0,12)
		var base:=Vector3(top.x,top.y,-100)
		renderer._box("SasmitaPileFooting",base-Vector3(0,0,5),Vector3(22,22,10),stone)
		renderer._column(base,top,7.0,wood)
		renderer._column(top,corners[next]-Vector3(0,0,12),6.0,wood)
		# Braces remain below the existing floor and never cross a walking route.
		var upper:=corners[index].lerp(corners[next],.35)-Vector3(0,0,17)
		renderer._column(base+Vector3(0,0,25),upper,3.6,bamboo)
	for fraction in [.22,.48,.74]:
		var left:=corners[0].lerp(corners[3],fraction)-Vector3(0,0,16)
		var right:=corners[1].lerp(corners[2],fraction)-Vector3(0,0,16)
		renderer._column(left,right,5.0,wood)
	renderer._components["SasmitaPileFrame"]=1
