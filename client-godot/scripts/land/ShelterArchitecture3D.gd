extends RefCounted

var roofs: Dictionary = {}
var support_count := 0
var _cutaway_shader: Shader
var _panels: Dictionary = {}

func _panel_material(renderer: Node, kind: String, soffit_kind: String) -> ShaderMaterial:
	if _cutaway_shader==null:
		_cutaway_shader=Shader.new()
		var source: String=renderer.Materials.SHADER_SOURCE
		source=source.replace("varying vec3 at;", """
	uniform vec4 soffit_base_color : source_color;
	uniform int soffit_kind = 0;
	uniform bool soffit_has_atlas = false;
	uniform int soffit_atlas_cell = 0;
	uniform sampler2D soffit_material_atlas : source_color, filter_nearest, repeat_enable;
	uniform bool soffit_has_micro = false;
	uniform sampler2D soffit_micro_texture : source_color, filter_nearest, repeat_enable;
	varying vec3 at;""")
		source=source.replace("vec2 planar=", """
	bool is_soffit = COLOR.r < 0.5;
	int surface_kind = is_soffit ? soffit_kind : kind;
	vec4 surface_base = is_soffit ? soffit_base_color : base_color;
	bool surface_has_micro = is_soffit ? soffit_has_micro : has_micro;
	bool surface_has_atlas = is_soffit ? soffit_has_atlas : has_atlas;
	int surface_atlas_cell = is_soffit ? soffit_atlas_cell : atlas_cell;
	vec2 planar=""")
		source=source.replace("base_color.rgb", "surface_base.rgb").replace("kind==", "surface_kind==")
		source=source.replace("if(has_micro)", "if(surface_has_micro)").replace("if(has_atlas)", "if(surface_has_atlas)")
		source=source.replace("texture(micro_texture,fract(planar/128.0)).rgb", "(is_soffit ? texture(soffit_micro_texture,fract(planar/128.0)).rgb : texture(micro_texture,fract(planar/128.0)).rgb)")
		source=source.replace("float(atlas_cell%3)", "float(surface_atlas_cell%3)").replace("float(atlas_cell/3)", "float(surface_atlas_cell/3)")
		source=source.replace("texture(material_atlas,origin+tile*vec2(1.0/3.0,.5)).rgb", "(is_soffit ? texture(soffit_material_atlas,origin+tile*vec2(1.0/3.0,.5)).rgb : texture(material_atlas,origin+tile*vec2(1.0/3.0,.5)).rgb)")
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
	var soffit:ShaderMaterial=renderer._materials.get_material(soffit_kind)
	for parameter in ["base_color","kind","has_atlas","atlas_cell","material_atlas","has_micro","micro_texture"]:
		var value:Variant=soffit.get_shader_parameter(parameter)
		if value!=null: material.set_shader_parameter("soffit_"+parameter,value)
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
	var roof_material:=_panel_material(renderer,roof_kind,"bamboo")
	var elevation: float=float(shelter.elevation)*renderer.LEVEL_HEIGHT
	var corners: Array[Vector3]=[]
	for index in range(4):
		var height:=float(shelter.attachmentHeight if index<2 else shelter.outerHeight)
		corners.append(renderer.map_point(_point(shelter.roof[index]),elevation)+Vector3(0,0,height))
	var id:=str(shelter.id)
	var polygon:=PackedVector2Array()
	for point in shelter.roof: polygon.append(_point(point))
	_panels[id]={"materials":[roof_material],"polygon":polygon,"amount":0.0}
	roofs[id]=corners.duplicate()
	renderer._mesh(id+"_Roof",PackedVector3Array(corners),PackedInt32Array([0,1,2,0,2,3]),roof_material,null,PackedColorArray([Color.WHITE,Color.WHITE,Color.WHITE,Color.WHITE]))
	var bottom: Array[Vector3]=[]
	for point in corners: bottom.append(point-Vector3(0,0,5))
	var soffit: Array[Vector3]=[bottom[3],bottom[2],bottom[1],bottom[0]]
	renderer._mesh(id+"_Soffit",PackedVector3Array(soffit),PackedInt32Array([0,1,2,0,2,3]),roof_material,null,PackedColorArray([Color(0,0,0,1),Color(0,0,0,1),Color(0,0,0,1),Color(0,0,0,1)]))
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
