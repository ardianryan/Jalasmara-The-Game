extends Node3D

const IDS := {"Mang Ujang":"ujang","Bu Darmi":"darmi","Yu Sari":"sari"}
var renderer: Node
var actor: Node2D
var data: Dictionary = {}
var sprites: Dictionary = {}
var hands: Dictionary = {}
var _local_hands: Dictionary = {}
var _last_pose: Dictionary = {}
var ready_rig := false
var _atlas: Texture2D
var _tint := Color.WHITE

func configure(owner_renderer: Node,person: Node2D) -> bool:
	renderer=owner_renderer
	actor=person
	var id: String=IDS.get(str(actor.actor_name),"")
	var metadata:="res://resources/art/npc-rigs/"+id+".json"
	if id=="" or not FileAccess.file_exists(metadata): return false
	data=JSON.parse_string(FileAccess.get_file_as_string(metadata))
	_atlas=load(str(data.atlas))
	for name in data.parts:
		var part: Dictionary=data.parts[name]
		var texture:=AtlasTexture.new()
		texture.atlas=_atlas
		texture.region=Rect2(Vector2(int(part.cell)%5,int(part.cell)/5)*64+Vector2(float(part.origin[0]),float(part.origin[1])),Vector2(float(part.size[0]),float(part.size[1])))
		texture.filter_clip=true
		var sprite:=Sprite3D.new()
		sprite.name=str(name)
		sprite.texture=texture
		sprite.pixel_size=1
		sprite.shaded=false
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold=.5
		sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(sprite)
		sprites[name]=sprite
	ready_rig=true
	actor.set_meta("body_layered",true)
	return true

func _v(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

func _center(name: String) -> Vector2:
	return _v(data.parts[name].get("center",[0,0]))

func _place_part(name: String,center: Vector2,rotation: float,depth: float) -> void:
	var sprite: Sprite3D=sprites[name]
	sprite.position=Vector3(center.x,-center.y,depth)
	sprite.rotation.z=-rotation
	sprite.modulate=_tint
	sprite.visible=true

func _bone(name: String,joint: Vector2,end: Vector2,depth: float) -> void:
	var part: Dictionary=data.parts[name]
	var delta:=(end-joint).angle()-PI*.5
	var center:=joint+Vector2(0,float(part.size[1])*.5).rotated(delta)
	_place_part(name,center,delta,depth)

func _ik(a: Vector2,b: Vector2,first: float,second: float,bend: float) -> Vector2:
	var vector:=b-a
	var distance:=clampf(vector.length(),.1,first+second-.01)
	var along:=vector.normalized()
	var offset:=(first*first-second*second+distance*distance)/(2*distance)
	var height:=sqrt(maxf(0,first*first-offset*offset))
	return a+along*offset+Vector2(-along.y,along.x)*height*bend

func _length(name: String) -> float:
	return float(data.parts[name].size[1])

func _body_transform(point: Vector2,lean: float) -> Vector2:
	var hip:=Vector2(0,-36)
	return hip+(point-hip).rotated(lean)

func update_pose(tint: Color) -> void:
	if not ready_rig or not is_instance_valid(actor): return
	_tint=tint
	var state: Dictionary=actor.body_animation_state()
	var camera:=get_viewport().get_camera_3d()
	if camera==null: return
	var foot: Vector3=renderer.map_point(actor.position,renderer.ground_height(actor.position))-renderer.camera_forward()*8
	global_transform=Transform3D(camera.global_basis.orthonormalized(),foot)
	var facing:=str(state.direction)
	scale=Vector3(-1 if facing=="west" else 1,1,1)
	if facing in ["east","west"]: scale.x*=.93
	var back:=facing=="north"
	var clip:=str(state.clip)
	var reduced:=EnvironmentState.reduced_motion
	var t:=0.8 if reduced else float(state.elapsed)
	var wave:=0.0 if reduced else sin(t*2.1)
	var walking: bool=clip=="walk" and actor.moved_velocity.length()>.1
	var stride:=float(state.distance)/25.0*TAU
	var work:=1.0 if clip=="work_loop" else clampf(t/.8,0,1) if clip=="start_work" else 1-clampf(t/.65,0,1) if clip=="end_work" else 0.0
	var lean:=work*(.025+wave*.012) if not reduced else 0.0
	for sprite in sprites.values(): sprite.visible=false
	for index in range(2):
		var side:="left" if index==0 else "right"
		var hip:=_v(data.joints[side+"Hip"])
		var first:=_length("upper_leg_"+side)
		var second:=_length("lower_leg_"+side)
		var foot_part: Dictionary=data.parts["foot_"+side]
		var phase:=stride+index*PI
		var lift:=maxf(0,sin(phase))*3.4 if walking and not reduced else 0.0
		var sole:=float(foot_part.size[1])
		var ankle:=Vector2(hip.x+sin(phase)*3.5 if walking and not reduced else hip.x,-sole-lift)
		var knee:=_ik(hip,ankle,first,second,1 if index==0 else -1)
		var depth: float=-.2 if index==0 else -.05
		_bone("upper_leg_"+side,hip,knee,depth)
		_bone("lower_leg_"+side,knee,ankle,depth+.01)
		_place_part("foot_"+side,ankle+Vector2(0,sole*.5),0,depth+.02)
	var torso_name:="torso_back" if back else "torso"
	_place_part(torso_name,_body_transform(_center("torso"),lean),lean,.03)
	var head_angle:=0.0 if reduced else sin(t*2.4)*.035 if clip=="interact" else wave*.008
	var head_name:="head_back" if back else "head"
	_place_part(head_name,_body_transform(_center("head"),lean),lean+head_angle,.08)
	_local_hands.clear()
	hands.clear()
	for index in range(2):
		var side:="left" if index==0 else "right"
		var shoulder:=_body_transform(_v(data.joints[side+"Shoulder"]),lean)
		var first:=_length("upper_arm_"+side)
		var second:=_length("lower_arm_"+side)
		var hand:=shoulder+Vector2(-2 if index==0 else 2,(first+second)*.93)
		if walking and not reduced: hand+=Vector2(sin(stride+index*PI)*4,-absf(sin(stride+index*PI))*2)
		var work_hand:=Vector2(5 if index==0 else 13,-49 if index==0 else -48)
		var phase:=str(state.workPhase)
		if reduced: phase="wait" if str(actor.activity_kind)=="fishing" else "aim" if str(actor.activity_kind)=="gardening" else "weave"
		if str(actor.activity_kind)=="fishing":
			work_hand=Vector2(5 if index==0 else 13,-53+sin(t*1.1)*.5)
			if phase=="cast": work_hand+=Vector2(sin(clampf((fposmod(t,9)-1)/.8,0,1)*PI)*7,-4)
			elif phase=="pull": work_hand+=Vector2(-4,-3+wave*2)
		elif str(actor.activity_kind)=="gardening":
			work_hand=Vector2(5 if index==0 else 14,-45 if index==0 else -47)
			if phase=="pour": work_hand+=Vector2(2,-2+wave*.6)
		elif str(actor.activity_kind)=="weaving": work_hand=Vector2(0 if index==0 else 13,-49+wave*(2 if index==0 else -2))
		hand=hand.lerp(work_hand,work)
		if clip=="interact" and index==1: hand=shoulder+Vector2(6,-1+wave*2)+Vector2(0,first+second)*.5
		var reach:=(hand-shoulder).limit_length(first+second-.01)
		hand=shoulder+reach
		var elbow:=_ik(shoulder,hand,first,second,1 if index==0 else -1)
		var depth:=.14 if not back else -.12
		_bone("upper_arm_"+side,shoulder,elbow,depth)
		_bone("lower_arm_"+side,elbow,hand,depth+.01)
		_place_part("hand_"+side,hand+Vector2(0,1.5),0,depth+.03)
		_local_hands[side]=[hand.x,hand.y]
		var point:=to_global(Vector3(hand.x,-hand.y,depth+.06))
		hands[side]=point
	var snapshot_hands: Dictionary={}
	for side in hands:
		var p: Vector3=hands[side]
		snapshot_hands[side]=[p.x,p.y,p.z]
	actor.set_meta("body_hands",snapshot_hands)
	_last_pose={"clip":clip,"direction":facing,"frame":state.frame,"phase":state.workPhase,"parts":sprites.size(),"handsLocal":_local_hands.duplicate(true),"toolFront":not back,"footPivot":[0,0],"rootMotion":false,"source":"original portrait cutout rig"}

func pose_snapshot() -> Dictionary:
	return _last_pose.duplicate(true)
