extends Node3D

# New residents have native volume and separate tools; no adult portrait is reused.
class NativeFeet extends "res://scripts/UjangFootPlant.gd":
	func _up() -> Vector3: return Vector3(0,0,1)
	func _update_lateral(at:Vector2) -> void:
		var direction:Vector2=_actor.moved_velocity
		if direction.length()<.1: direction=_direction
		var origin:Vector3=_renderer.map_point(at,0)
		var forward:Vector3=(_renderer.map_point(at+direction.normalized(),0)-origin).normalized()
		var right:=Vector3(-forward.y,forward.x,0)
		var x:Vector3=_renderer.map_point(at+Vector2.RIGHT,0)-origin
		var y:Vector3=_renderer.map_point(at+Vector2.DOWN,0)-origin
		var determinant:=x.x*y.y-y.x*x.y
		if absf(determinant)>.00001: _lateral=Vector2((right.x*y.y-y.x*right.y)/determinant,(x.x*right.y-right.x*x.y)/determinant)

var renderer:Node
var actor:Node2D
var profile:Dictionary={}
var batch:MultiMeshInstance3D
var _feet:RefCounted
var _palette:Dictionary={}
var _scale:=1.0
var _child:=false
var _used:=0
var _forward:=Vector3(0,-1,0)
var _right:=Vector3.RIGHT
var _snapshot:Dictionary={}
var _contact:Dictionary={}
var _hip_z:=36.0
var _thigh:=18.0
var _shin:=18.0
var _foot_height:=2.4
var _tint:=Color.WHITE
var _measure_emissions:=false
var _emissions:Array[Transform3D]=[]

func configure(owner_renderer:Node,person:Node2D) -> bool:
	renderer=owner_renderer
	actor=person
	_measure_emissions=bool(actor.get_meta("native_mesh_diagnostics",false))
	profile=actor.visual_profile.duplicate(true)
	if str(profile.get("kind","")) not in ["child","director"]: return false
	_scale=actor.body_scale
	_child=str(profile.kind)=="child"
	_palette={"skin":Color.from_string(str(profile.get("skinColor","#BD865A")),Color("BD865A")),"shirt":Color.from_string(str(profile.get("shirtColor","#509887")),Color("509887")),"trouser":Color.from_string(str(profile.get("trouserColor","#4D515D")),Color("4D515D")),"hair":Color.from_string(str(profile.get("hairColor","#38302C")),Color("38302C")),"shoe":Color("574237"),"brass":Color("D7AD63"),"cream":Color("F1E1AE"),"ink":Color("282E31")}
	_thigh=(15.0 if _child else 18.0)*_scale
	_shin=(14.0 if _child else 18.0)*_scale
	_foot_height=2.4*_scale
	_hip_z=_thigh+_shin+_foot_height-1.5*_scale
	_feet=NativeFeet.new()
	if not _feet.configure(renderer,actor,{"joints":{"leftHip":[-4.2*_scale,0],"rightHip":[4.2*_scale,0]}}): return false
	var logical:Vector2={"east":Vector2.RIGHT,"west":Vector2.LEFT,"north":Vector2.UP,"south":Vector2.DOWN}.get(str(actor.body_animation_state().direction),Vector2.DOWN)
	_feet.set("_direction",logical)
	_forward=(renderer.map_point(actor.position+logical,0)-renderer.map_point(actor.position,0)).normalized()
	_right=Vector3(-_forward.y,_forward.x,0)
	batch=MultiMeshInstance3D.new()
	var instances:=MultiMesh.new()
	instances.transform_format=MultiMesh.TRANSFORM_3D
	instances.use_colors=true
	var cube:=BoxMesh.new()
	cube.size=Vector3.ONE
	instances.mesh=cube
	instances.instance_count=128
	instances.visible_instance_count=0
	batch.multimesh=instances
	var material:=StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.roughness=1
	batch.material_override=material
	batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(batch)
	actor.set_meta("body_layered",true)
	return true

func _box(at:Vector3,size:Vector3,color:Color,basis:=Basis.IDENTITY) -> void:
	assert(_used<128,"Native resident batch capacity")
	var transform:=Transform3D(basis*Basis.from_scale(size),at)
	batch.multimesh.set_instance_transform(_used,transform)
	if _measure_emissions: _emissions.append(transform)
	batch.multimesh.set_instance_color(_used,color*_tint)
	_used+=1

func _point(x:float,y:float,z:float,drop:float) -> Vector3:
	return _right*x*_scale+_forward*y*_scale+Vector3(0,0,z*_scale-drop)

func _part(x:float,y:float,z:float,w:float,d:float,h:float,color:Color,drop:float) -> void:
	var basis:=Basis(_right,-_forward,Vector3(0,0,1))
	_box(_point(x,y,z,drop),Vector3(w,d,h)*_scale,color,basis)

func _bone(a:Vector3,b:Vector3,width:float,color:Color) -> void:
	var span:=b-a
	var basis:=Basis(Quaternion(Vector3(0,0,1),span.normalized()))
	_box((a+b)*.5,Vector3(width,width,span.length()),color,basis)

func _joint(a:Vector3,b:Vector3,first:float,second:float,hint:Vector3) -> Vector3:
	var span:=b-a
	var distance:=clampf(span.length(),.01,first+second-.001)
	var axis:=span.normalized()
	var along:float=(first*first-second*second+distance*distance)/(2*distance)
	var bend:=hint-axis*axis.dot(hint)
	if bend.length()<.001: bend=_right
	return a+axis*along+bend.normalized()*sqrt(maxf(0,first*first-along*along))

func update_pose(tint:Color) -> void:
	if not is_instance_valid(actor): return
	if EnvironmentState.clock_paused and not _snapshot.is_empty(): return
	_tint=tint
	global_position=renderer.ground_point(actor.position)
	var velocity:Vector2=actor.moved_velocity
	if velocity.length()>.1:
		var direction:Vector3=renderer.map_point(actor.position+velocity.normalized(),0)-renderer.map_point(actor.position,0)
		_forward=Vector3(direction.x,direction.y,0).normalized()
		_right=Vector3(-_forward.y,_forward.x,0)
	_contact=_feet.update(actor.position,velocity,float(actor.get("_elapsed")),1.0)
	var drop:float=-1.5*_scale
	var ankles:Dictionary={}
	for side in ["left","right"]:
		var sign_side:float=-1 if side=="left" else 1
		var hip:=_right*sign_side*4.2*_scale+Vector3(0,0,_hip_z)
		var ankle:Vector3=to_local(_contact.feet[side].sole)+Vector3(0,0,_foot_height)
		ankles[side]=ankle
		var horizontal:=Vector2(hip.x-ankle.x,hip.y-ankle.y).length_squared()
		drop=maxf(drop,hip.z-ankle.z-sqrt(maxf(.01,pow(_thigh+_shin-.2*_scale,2)-horizontal)))
	_used=0
	if _measure_emissions: _emissions.clear()
	var max_error:=0.0
	for side in ["left","right"]:
		var sign_side:float=-1 if side=="left" else 1
		var hip:=_right*sign_side*4.2*_scale+Vector3(0,0,_hip_z-drop)
		var ankle:Vector3=ankles[side]
		var knee:=_joint(hip,ankle,_thigh,_shin,_forward)
		_bone(hip,knee,5.8*_scale,_palette.trouser)
		_bone(knee,ankle,3.8*_scale,_palette.skin if _child else _palette.trouser)
		var sole:Vector3=to_local(_contact.feet[side].sole)
		_box(sole+Vector3(0,0,_foot_height*.5),Vector3(4.6,7.0,2.4)*_scale,_palette.shoe,Basis(_right,-_forward,Vector3(0,0,1)))
		max_error=maxf(max_error,maxf(absf(hip.distance_to(knee)-_thigh),absf(knee.distance_to(ankle)-_shin)))
	var hip_height:=_hip_z/_scale
	var torso_height:=24.0 if _child else 26.0
	var head_z:=hip_height+torso_height+(12.0 if _child else 8.5)
	var head_w:=17.0 if _child else 12.0
	var head_h:=22.0 if _child else 15.0
	_part(0,0,hip_height+torso_height*.5,14,8,torso_height,_palette.shirt,drop)
	_part(0,0,hip_height,14.5,8.4,3,_palette.trouser,drop)
	_part(0,0,head_z,head_w,10,head_h-4,_palette.skin,drop)
	_part(0,0,head_z-head_h*.5+1,head_w-3,8,3,_palette.skin.darkened(.06),drop)
	_part(0,0,head_z+head_h*.5-1,head_w-3,9,3,_palette.skin,drop)
	_part(0,0,head_z+head_h*.5,head_w+1,12,3,_palette.hair,drop)
	_part(0,-4.7,head_z+3,head_w+1,2.6,10,_palette.hair,drop)
	for eye in [-3.3,3.3]:
		_part(eye,5.7,head_z+.6,2.1,.8,2.3,_palette.ink,drop)
	_part(0,6.2,head_z-1.5,1.8,1.4,2,_palette.skin.lightened(.12),drop)
	_part(0,5.7,head_z-4,3,.8,1,_palette.ink,drop)
	var prop:=str(profile.get("prop",""))
	_identity(prop,head_z,head_w,hip_height,torso_height,drop)
	var state:Dictionary=actor.body_animation_state()
	var walking:bool=velocity.length()>.1
	var phase:float=float(state.distance)/25.0*TAU
	var work:float=1.0 if str(state.clip)=="work_loop" else clampf(float(state.elapsed)/.8,0,1) if str(state.clip)=="start_work" else 1-clampf(float(state.elapsed)/.65,0,1) if str(state.clip)=="end_work" else 0.0
	var wave:float=0.0 if EnvironmentState.reduced_motion else sin(float(state.elapsed)*2.1)
	var hands:Dictionary={}
	for side in ["left","right"]:
		var sign_side:float=-1 if side=="left" else 1
		var shoulder:=_point(sign_side*8,0,hip_height+torso_height-3,drop)
		var hand:=_point(sign_side*9,2,hip_height+4,drop)
		if walking: hand+=_forward*sin(phase+(PI if side=="right" else 0))*4*_scale
		if side=="right" and prop in ["telescope","snail_jar","ladle","slingshot"]: hand+=_forward*5*_scale+Vector3(0,0,5*_scale)
		if work>0:
			var raise:=22.0 if prop=="telescope" else 6.0 if prop=="snail_jar" else 2.0
			hand+=(_forward*(3.0+wave)+Vector3(0,0,raise+wave))*_scale*work
		hand=shoulder+(hand-shoulder).limit_length(20*_scale-.01)
		var elbow:=_joint(shoulder,hand,10*_scale,10*_scale,_forward)
		_bone(shoulder,elbow,4*_scale,_palette.shirt)
		_bone(elbow,hand,3.5*_scale,_palette.skin)
		_box(hand,Vector3(4,4,4)*_scale,_palette.skin)
		hands[side]=hand
	_prop(prop,hands.right)
	batch.multimesh.visible_instance_count=_used
	var hand_meta:Dictionary={}
	for side in hands:
		var point:Vector3=to_global(hands[side])
		hand_meta[side]=[point.x,point.y,point.z]
	actor.set_meta("body_hands",hand_meta)
	_snapshot={"id":actor.resident_id,"native":true,"clip":state.clip,"direction":state.direction,"bodyScale":_scale,"childProportions":_child,"age":int(profile.get("age",0)),"parts":_used,"drawBatches":1,"footPivot":[0,0],"rootMotion":false,"prop":prop,"contacts":_contact.duplicate(true),"maxLengthError":max_error,"pelvisDrop":drop,"source":"Original native voxel resident; no portrait mirror or adult atlas reuse"}
	for side in ["left","right"]:
		var sole:Vector3=_snapshot.contacts.feet[side].sole
		var plant:Vector3=_snapshot.contacts.feet[side].plant
		_snapshot.contacts.feet[side]["worldSole"]=[sole.x,sole.y,sole.z]
		_snapshot.contacts.feet[side]["worldPlant"]=[plant.x,plant.y,plant.z]

func _identity(prop:String,head_z:float,head_w:float,hip:float,torso:float,drop:float) -> void:
	if not _child:
		_part(0,4.6,hip+torso*.7,2.8,1.2,14,Color("29766F"),drop)
		_part(-4.5,4.6,hip+torso-6,3.2,1,3.2,_palette.brass,drop)
	elif prop=="telescope":
		for x in [-3.3,3.3]:
			_part(x,6.5,head_z+.6,5.4,.6,4.7,_palette.ink,drop)
			_part(x,6.9,head_z+.6,3.4,.4,2.7,Color("A8D3C3"),drop)
		for z in [hip+4,hip+10,hip+16]: _part(0,4.5,z,14.2,1,2.5,_palette.ink,drop)
	elif prop=="snail_jar":
		for x in [-8.5,8.5]:
			_part(x,-2,head_z-6,3,4,17,_palette.hair,drop)
			_part(x,-2,head_z+4,3.4,4.4,3,Color("B39AC1"),drop)
		_part(0,0,hip+4,16,10,10,_palette.shirt,drop)
	elif prop=="bucket":
		for size in [Vector3(24,21,1.6),Vector3(18,16,2),Vector3(11,10,2.6)]:
			_part(0,0,head_z+7+(24-size.x)*.24,size.x,size.y,size.z,_palette.brass,drop)
	elif prop=="slingshot":
		_part(0,0,head_z+9,8,6,5,_palette.hair,drop)
		_part(0,6,head_z+3,5,1,1.8,_palette.cream,drop)
		for x in [-5,5]: _part(x,4.7,hip+12,4,2.5,18,Color("D98042"),drop)
	elif prop=="ladle":
		_part(0,0,head_z+6,head_w+2,12.8,3,Color("B64641"),drop)
		_part(0,5,hip+9,12,1.4,16,_palette.cream,drop)

func _prop(prop:String,hand:Vector3) -> void:
	var size:=_scale
	if prop=="telescope":
		_box(hand+_forward*6*size,Vector3(4,15,4)*size,_palette.brass,Basis(_right,-_forward,Vector3(0,0,1)))
		_box(hand+_forward*14*size,Vector3(5,2,5)*size,Color("5FACA4"),Basis(_right,-_forward,Vector3(0,0,1)))
	elif prop=="snail_jar":
		_box(hand+Vector3(0,0,-3*size),Vector3(7,6,8)*size,Color("8AC7BC"))
		_box(hand+Vector3(0,0,-3*size)+_forward*3.2*size,Vector3(3,1,3)*size,Color("5A75A0"))
	elif prop in ["bucket","briefcase"]:
		var dimensions:=Vector3(8,7,9) if prop=="bucket" else Vector3(12,4,9)
		_box(hand-Vector3(0,0,7*size),dimensions*size,_palette.shoe)
		_box(hand-Vector3(0,0,1.5*size),Vector3(5,2,3)*size,_palette.brass)
	elif prop=="slingshot":
		_box(hand+Vector3(0,0,3*size),Vector3(1.5,1.5,8)*size,_palette.shoe)
		_box(hand+Vector3(0,0,7*size),Vector3(6,1.5,1.5)*size,_palette.brass)
	elif prop=="ladle":
		_box(hand+Vector3(0,0,3*size),Vector3(1.5,1.5,12)*size,_palette.shoe)
		_box(hand+Vector3(0,0,10*size),Vector3(5,4,2)*size,_palette.brass)

func pose_snapshot() -> Dictionary: return _snapshot.duplicate(true)

func emitted_transform(index:int) -> Transform3D: return _emissions[index]
