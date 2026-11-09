extends Node3D

const FootPlant=preload("res://scripts/UjangFootPlant.gd")
const ART="res://resources/art/resident-rigs-v1/rigs.json"
var actor:Node2D
var renderer:Node
var data:Dictionary={}
var sprites:Dictionary={}
var hands:Dictionary={}
var _hands_local:Dictionary={}
var _links:Dictionary={}
var _state:Dictionary={}
var _plant:RefCounted
var _contacts:Dictionary={}
var _factor:=1.0
var _drop:=0.0
var _held:Node3D
var _tint:=Color.WHITE
var _work_facing:=Vector2.RIGHT
var _atlas:Texture2D
var body_mesh:MultiMeshInstance3D
var _part_transforms:Dictionary={}
var _body_material:ShaderMaterial
var _integration:Dictionary={}
var ready_rig:=false

func configure(owner_renderer:Node,person:Node2D) -> bool:
	if not ("resident_id" in person) or not FileAccess.file_exists(ART): return false
	var all:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ART))
	if not all.people.has(str(person.resident_id)): return false
	actor=person
	renderer=owner_renderer
	data=all.people[str(actor.resident_id)]
	_atlas=load(str(all.atlas))
	_factor=float(preload("res://scripts/CharacterVisual.gd").LAND_SIZE)/112.0*float(actor.body_scale)
	body_mesh=MultiMeshInstance3D.new()
	body_mesh.name="OriginalResidentParts"
	body_mesh.multimesh=MultiMesh.new()
	body_mesh.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	body_mesh.multimesh.use_custom_data=true
	var quad:=QuadMesh.new()
	quad.size=Vector2.ONE
	body_mesh.multimesh.mesh=quad
	body_mesh.multimesh.instance_count=data.parts.size()
	_body_material=ShaderMaterial.new()
	var shader:=Shader.new()
	shader.code="""shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D atlas_tex : source_color, filter_nearest, repeat_disable;
uniform vec4 readable_tint : source_color = vec4(1.0);
varying vec2 part_uv;
void vertex() { part_uv=INSTANCE_CUSTOM.xy+UV*INSTANCE_CUSTOM.zw; }
void fragment() { vec4 texel=texture(atlas_tex,part_uv); if(texel.a<0.5) discard; ALBEDO=texel.rgb*readable_tint.rgb; }
"""
	_body_material.shader=shader
	_body_material.set_shader_parameter("atlas_tex",_atlas)
	body_mesh.material_override=_body_material
	body_mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(body_mesh)
	var index:=0
	for name in data.parts:
		var rect:Array=data.parts[name].rect
		sprites[name]=index
		body_mesh.multimesh.set_instance_custom_data(index,Color(float(rect[0])/_atlas.get_width(),float(rect[1])/_atlas.get_height(),float(rect[2])/_atlas.get_width(),float(rect[3])/_atlas.get_height()))
		index+=1
	var hips:Dictionary={}
	for side in ["left","right"]: hips[side+"Hip"]=[_relative(data.joints[side+"Hip"]).x,0]
	_plant=FootPlant.new()
	var shortest_leg:=minf(_length("upper_leg_left")+_length("lower_leg_left"),_length("upper_leg_right")+_length("lower_leg_right"))
	var step_scale:=minf(float(actor.body_scale),shortest_leg*.85/FootPlant.STRIDE)
	if not _plant.configure(renderer,actor,{"joints":hips,"stepScale":step_scale,"turnCosine":.8}): return false
	_held=Node3D.new()
	_held.name="SeparateHeldProp"
	add_child(_held)
	_build_prop(str(actor.visual_profile.get("prop","")))
	actor.set_meta("body_layered",true)
	ready_rig=true
	return true

func _v(value:Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _relative(value:Array) -> Vector2:
	return (_v(value)-_v(data.pivot))*_factor

func _center(name:String) -> Vector2:
	var bounds:Array=data.parts[name].sourceBounds
	return Vector2((float(bounds[0])+float(bounds[2]))*.5,(float(bounds[1])+float(bounds[3]))*.5)

func _put(name:String,at:Vector2,angle:float,depth:float) -> void:
	var part:Dictionary=data.parts[name]
	var rect:Array=part.rect
	var rotation:=Basis(Vector3(0,0,1),-angle)
	var width:float=float(rect[2])*_factor
	var height:float=float(rect[3])*_factor
	if bool(part.hiddenByAuthoredClothing): width=0; height=0
	var transform:=Transform3D(Basis(rotation.x*width,rotation.y*height,rotation.z),Vector3(at.x,-at.y,depth))
	body_mesh.multimesh.set_instance_transform(int(sprites[name]),transform)
	_part_transforms[name]=transform

func _bone(name:String,start:Vector2,end:Vector2,depth:float) -> void:
	var original:Array=data.parts[name].bone
	var original_start:=_v(original[0])
	var original_axis:=_v(original[1])-original_start
	var turn:float=(end-start).angle()-original_axis.angle()
	var center:=start+((_center(name)-original_start)*_factor).rotated(turn)
	_put(name,center,turn,depth)

func _bone3(name:String,start:Vector3,end:Vector3) -> void:
	var original:Array=data.parts[name].bone
	var axis2:=_v(original[1])-_v(original[0])
	var source_axis:=Vector3(axis2.x,-axis2.y,0).normalized()
	var source_right:=source_axis.cross(Vector3.BACK).normalized()
	var source_basis:=Basis(source_right,source_axis,source_right.cross(source_axis))
	var target_axis:Vector3=(end-start).normalized()
	var target_right:=target_axis.cross(Vector3.BACK).normalized()
	if target_right.length()<.01: target_right=Vector3.RIGHT
	var target_basis:=Basis(target_right,target_axis,target_right.cross(target_axis))
	var rotation:=target_basis*source_basis.transposed()
	var center2:=(_center(name)-_v(original[0]))*_factor
	var rect:Array=data.parts[name].rect
	var width:float=float(rect[2])*_factor
	var height:float=float(rect[3])*_factor
	if bool(data.parts[name].hiddenByAuthoredClothing): width=0; height=0
	var transform:=Transform3D(Basis(rotation.x*width,rotation.y*height,rotation.z),start+rotation*Vector3(center2.x,-center2.y,0))
	body_mesh.multimesh.set_instance_transform(int(sprites[name]),transform)
	_part_transforms[name]=transform

func _ik3(start:Vector3,end:Vector3,first:float,second:float,bend:float) -> Vector3:
	var vector:=end-start
	var distance:=clampf(vector.length(),.001,first+second-.001)
	var along:=vector.normalized()
	var offset:float=(first*first-second*second+distance*distance)/(2*distance)
	var hint:=Vector3(-along.y,along.x,0)*-bend
	if hint.length()<.01: hint=Vector3.RIGHT
	hint=(hint-along*hint.dot(along)).normalized()
	return start+along*offset+hint*sqrt(maxf(0,first*first-offset*offset))

func _length(name:String) -> float:
	var bone:Array=data.parts[name].bone
	return _v(bone[0]).distance_to(_v(bone[1]))*_factor

func _bend(first:String,second:String) -> float:
	var a:Array=data.parts[first].bone
	var b:Array=data.parts[second].bone
	return 1.0 if (_v(b[1])-_v(a[0])).cross(_v(a[1])-_v(a[0]))>=0 else -1.0

func _ik(a:Vector2,b:Vector2,first:float,second:float,bend:float) -> Vector2:
	var vector:=b-a
	var distance:=clampf(vector.length(),.001,first+second-.001)
	var along:=vector.normalized()
	var offset:float=(first*first-second*second+distance*distance)/(2*distance)
	return a+along*offset+Vector2(-along.y,along.x)*sqrt(maxf(0,first*first-offset*offset))*bend

func _screen(world:Vector3) -> Vector2:
	var local:=global_transform.affine_inverse()*world
	return Vector2(local.x,-local.y)

func _advance_contacts(at:Vector2,ground:Vector3,time:float) -> Dictionary:
	var previous:Vector2=_plant._last_at
	var start_time:float=_plant._last_time
	var logical:=at.distance_to(previous)
	var physical:=ground.distance_to(_plant._last_ground)
	# Keep real discontinuities visible to the original support solver.
	var discontinuity:bool=logical>50 or physical>FootPlant.STRIDE*.5
	var slices:=1
	if bool(_plant._ready) and not discontinuity:
		slices=maxi(1,ceili(maxf(logical,physical)/maxf(.001,float(_plant.stride_length)/8.0)))
	var travelled:=0.0
	var largest:=0.0
	var from:Vector3=_plant._last_ground
	var contacts:Dictionary={}
	for index in range(1,slices+1):
		var fraction:=float(index)/slices
		var point:=previous.lerp(at,fraction)
		var next:Vector3=renderer.ground_point(point)
		var distance:=from.distance_to(next)
		travelled+=distance
		largest=maxf(largest,distance)
		contacts=_plant.update(point,actor.moved_velocity,lerpf(start_time,time,fraction),1.0)
		from=next
	_integration={"slices":slices,"logicalDistance":logical,"physicalDistance":physical,"integratedPhysicalDistance":travelled,"largestSlice":largest,"discontinuity":discontinuity,"initial":_contacts.is_empty()}
	return contacts

func update_pose(tint:Color) -> void:
	if not ready_rig or not is_instance_valid(actor): return
	var camera:Camera3D=renderer.camera_3d
	if camera==null: return
	_tint=tint
	_body_material.set_shader_parameter("readable_tint",tint)
	var state:Dictionary=actor.body_animation_state()
	_state=state.duplicate(true)
	var paused:bool=EnvironmentState.clock_paused
	var reduced:bool=EnvironmentState.reduced_motion
	var ground:Vector3=renderer.ground_point(actor.position)
	global_transform=Transform3D(camera.global_basis.orthonormalized(),ground)
	if _contacts.is_empty() or not paused:
		_contacts=_advance_contacts(actor.position,ground,float(actor.get("_elapsed")))
	var ankles:Dictionary={}
	_drop=0
	for side in ["left","right"]:
		var foot:Dictionary=data.parts["foot_"+side]
		var source_ankle:Array=data.legs[side][2]
		var sole:Vector3=to_local(_contacts.feet[side].sole)
		var offset:=(_v(source_ankle)-_v(foot.sole))*_factor
		ankles[side]=sole+Vector3(offset.x,-offset.y,0)
		var hip2:=_relative(data.joints[side+"Hip"])
		var hip:=Vector3(hip2.x,-hip2.y,-.2)
		var reach:float=_length("upper_leg_"+side)+_length("lower_leg_"+side)-.001
		var horizontal:=Vector2(hip.x-Vector3(ankles[side]).x,hip.z-Vector3(ankles[side]).z).length_squared()
		var vertical:=sqrt(maxf(0,reach*reach-horizontal))
		_drop=maxf(_drop,hip.y-Vector3(ankles[side]).y-vertical)
	_links.clear()
	for side in ["left","right"]:
		var hip2:=_relative(data.joints[side+"Hip"])
		var hip:=Vector3(hip2.x,-hip2.y-_drop,-.2)
		var ankle:Vector3=ankles[side]
		var knee:=_ik3(hip,ankle,_length("upper_leg_"+side),_length("lower_leg_"+side),_bend("upper_leg_"+side,"lower_leg_"+side))
		_links["leg_"+side]={"start":hip,"joint":knee,"end":ankle,"first":_length("upper_leg_"+side),"second":_length("lower_leg_"+side)}
		_bone3("upper_leg_"+side,hip,knee)
		_bone3("lower_leg_"+side,knee,ankle)
		var foot:Dictionary=data.parts["foot_"+side]
		var foot_local:Vector3=to_local(_contacts.feet[side].sole)
		_put("foot_"+side,_screen(_contacts.feet[side].sole)+(_center("foot_"+side)-_v(foot.sole))*_factor,0,foot_local.z)
	for name in ["torso","head"]: _put(name,(_center(name)-_v(data.pivot))*_factor+Vector2(0,_drop),0,.02 if name=="torso" else .05)
	var walking:bool=str(state.clip)=="walk" and (actor.moved_velocity.length()>.1 or paused)
	var work:float=1.0 if str(state.clip)=="work_loop" else clampf(float(state.elapsed)/.8,0,1) if str(state.clip)=="start_work" else 1-clampf(float(state.elapsed)/.65,0,1) if str(state.clip)=="end_work" else 0.0
	if state.has("workFacing"):
		var target:Dictionary=state.workFacing
		var delta:Vector3=renderer.map_point(_v(target.point),float(target.height))-ground
		_work_facing=Vector2(delta.dot(camera.global_basis.x),-delta.dot(camera.global_basis.y)).normalized()
	hands.clear()
	_hands_local.clear()
	for index in range(2):
		var side:="left" if index==0 else "right"
		var shoulder:=_relative(data.joints[side+"Shoulder"])+Vector2(0,_drop)
		var lower:Array=data.parts["lower_arm_"+side].bone
		var hand:=_relative(lower[1])+Vector2(0,_drop)
		if walking and not reduced: hand+=Vector2(sin(float(_contacts.phaseDistance)/float(_contacts.stride)*TAU+index*PI)*1.5,0)*float(actor.body_scale)
		if index==1: hand=hand.lerp(shoulder+Vector2(4,(_length("upper_arm_"+side)+_length("lower_arm_"+side))*.55),work)
		var reach:float=_length("upper_arm_"+side)+_length("lower_arm_"+side)-.001
		hand=shoulder+(hand-shoulder).limit_length(reach)
		var elbow:=_ik(shoulder,hand,_length("upper_arm_"+side),_length("lower_arm_"+side),_bend("upper_arm_"+side,"lower_arm_"+side))
		_links["arm_"+side]={"start":shoulder,"joint":elbow,"end":hand,"first":_length("upper_arm_"+side),"second":_length("lower_arm_"+side)}
		_bone("upper_arm_"+side,shoulder,elbow,.1)
		_bone("lower_arm_"+side,elbow,hand,.11)
		var hand_turn:float=(hand-elbow).angle()-(_v(lower[1])-_v(lower[0])).angle()
		_put("hand_"+side,hand+((_center("hand_"+side)-_v(lower[1]))*_factor).rotated(hand_turn),hand_turn,.12)
		var grip:=hand+((_v(data.parts["hand_"+side].grip)-_v(lower[1]))*_factor).rotated(hand_turn)
		_hands_local[side]=grip
		hands[side]=to_global(Vector3(grip.x,-grip.y,.12))
	_held.position=Vector3(_hands_local.right.x,-_hands_local.right.y,.12)
	_held.scale=Vector3.ONE*float(actor.body_scale)
	var snapshots:Dictionary={}
	for side in hands:
		var point:Vector3=hands[side]
		snapshots[side]=[point.x,point.y,point.z]
	actor.set_meta("body_hands",snapshots)

func _material(color:String) -> StandardMaterial3D:
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(color)
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.roughness=1
	return material

func _box(at:Vector3,size:Vector3,color:String) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.position=at
	node.material_override=_material(color)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_held.add_child(node)

func _rod(a:Vector3,b:Vector3,radius:float,color:String) -> void:
	var node:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=radius
	mesh.bottom_radius=radius
	mesh.height=a.distance_to(b)
	mesh.radial_segments=6
	node.mesh=mesh
	node.position=(a+b)*.5
	node.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
	node.material_override=_material(color)
	node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_held.add_child(node)

func _build_prop(kind:String) -> void:
	if kind=="briefcase":
		_box(Vector3(3,-7,0),Vector3(15,10,3),"705137")
		for x in [-2,4]: _box(Vector3(x,-.5,0),Vector3(1,4,1),"c7a266")
		_box(Vector3(1,1.5,0),Vector3(7,1,1),"c7a266")
	elif kind=="telescope":
		_rod(Vector3(-4,1,0),Vector3(13,3,0),3,"926b3a")
		_rod(Vector3(11.5,2.8,0),Vector3(14,3.1,0),3.7,"d6ae61")
	elif kind=="snail_jar":
		_box(Vector3(2,-5,0),Vector3(9,10,3),"5eaaa1")
		_box(Vector3(2,1,0),Vector3(10,2,4),"bfa065")
		_box(Vector3(2,-6,2),Vector3(4,3,1),"e4b36c")
	elif kind=="bucket":
		_box(Vector3(3,-7,0),Vector3(11,10,4),"92724d")
		for x in [-2,8]: _rod(Vector3(x,-2,0),Vector3(x,2,0),.7,"c8ac76")
		_rod(Vector3(-2,2,0),Vector3(8,2,0),.7,"c8ac76")
	elif kind=="slingshot":
		_rod(Vector3(0,-4,0),Vector3(0,5,0),1.2,"8c613a")
		for side in [-1,1]: _rod(Vector3(0,3,0),Vector3(side*4,8,0),1.1,"8c613a")
		_rod(Vector3(-4,8,0),Vector3(4,8,0),.4,"b99a60")
	elif kind=="ladle":
		_rod(Vector3(0,5,0),Vector3(0,-10,0),1,"ac7f47")
		_box(Vector3(0,-11,0),Vector3(7,3,2),"bb8a51")

func debug_status() -> Dictionary:
	return {"id":str(actor.resident_id),"authoredViews":1,"view":"front_three_quarter","mirrored":false,"bodyScale":float(actor.body_scale),"pelvisDrop":_drop,"contacts":_contacts.duplicate(true),"integration":_integration.duplicate(true),"workFacing":[_work_facing.x,_work_facing.y],"separateProp":_held.get_child_count()>0,"hands":hands.duplicate(),"links":_links.duplicate(true),"clip":str(_state.get("clip","idle")),"parts":sprites.size(),"bodyDrawCalls":1,"rootMotion":false,"logicalDirection":str(_state.get("direction","south")),"source":"original reviewed resident pixel partitions"}

func pose_snapshot() -> Dictionary:
	return debug_status()
