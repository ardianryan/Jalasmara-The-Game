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
var _foot_plant:RefCounted
var _contact_pose:Dictionary={}
var _sole_pixels:Dictionary={}
var _pelvis_drop:=0.0
var _rod_pose:Dictionary={}

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
	if id=="ujang":
		var candidate:=preload("res://scripts/UjangFootPlant.gd").new()
		if candidate.configure(renderer,actor,data):
			_foot_plant=candidate
			for side in ["left","right"]:
				var image:Image=sprites["foot_"+side].texture.get_image()
				if image.is_compressed(): image.decompress()
				var bottom:=image.get_used_rect().end.y-1
				var sum:=0.0
				var count:=0
				for x in range(image.get_width()):
					if image.get_pixel(x,bottom).a>=.5: sum+=x+.5; count+=1
				_sole_pixels[side]=Vector2(sum/maxi(1,count),bottom+1)
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
	var length:=joint.distance_to(end)
	var center:=(joint+end)*.5
	sprites[name].scale.y=length/maxf(1,float(part.size[1]))
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
	return hip+(point-hip).rotated(lean)+Vector2(0,_pelvis_drop)

func update_pose(tint: Color) -> void:
	if not ready_rig or not is_instance_valid(actor): return
	_tint=tint
	var state: Dictionary=actor.body_animation_state()
	var camera:=get_viewport().get_camera_3d()
	if camera==null: return
	var foot: Vector3=renderer.map_point(actor.position,renderer.ground_height(actor.position))
	if _foot_plant==null: foot-=renderer.camera_forward()*8
	global_transform=Transform3D(camera.global_basis.orthonormalized(),foot)
	var facing:=str(state.direction)
	scale=Vector3(-1 if facing=="west" else 1,1,1)
	if facing in ["east","west"] and _foot_plant==null: scale.x*=.93
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
	_pelvis_drop=0.0
	if _foot_plant!=null:
		_contact_pose=_foot_plant.update(actor.position,actor.moved_velocity,float(actor.get("_elapsed")),-1.0 if facing=="west" else 1.0)
		_contact_legs(_contact_pose)
	else:
		for index in range(2):
			var side:="left" if index==0 else "right"
			var hip:=_v(data.joints[side+"Hip"])
			var foot_part: Dictionary=data.parts["foot_"+side]
			var phase:=stride+index*PI
			var lift:=maxf(0,sin(phase))*3.4 if walking else 0.0
			var sole:=float(foot_part.size[1])
			var ankle:=Vector2(hip.x+sin(phase)*3.5 if walking else hip.x,-sole-lift)
			var knee:=hip.lerp(ankle,.52)+Vector2(1.0+lift*.35,0)
			var depth: float=-.2 if index==0 else -.05
			_bone("upper_leg_"+side,hip,knee,depth)
			_bone("lower_leg_"+side,knee,ankle,depth+.01)
			_place_part("foot_"+side,ankle+Vector2(0,sole*.5),0,depth+.02)
	var torso_name:="torso_back" if back else "torso"
	_place_part(torso_name,_body_transform(_center(torso_name) if data.parts[torso_name].has("center") else _center("torso"),lean),lean,.03)
	var head_angle:=0.0 if reduced else sin(t*2.4)*.035 if clip=="interact" else wave*.008
	var head_name:="head_back" if back else "head"
	_place_part(head_name,_body_transform(_center(head_name) if data.parts[head_name].has("center") else _center("head"),lean),lean+head_angle,.08)
	_local_hands.clear()
	hands.clear()
	_rod_pose.clear()
	actor.set_meta("body_rod",{})
	actor.set_meta("body_grip",{})
	var rod_hand:bool=_foot_plant!=null and facing=="west" and clip in ["start_work","work_loop","end_work"] and data.parts.has("hand_rod_west")
	if rod_hand:
		# The tool frame belongs to the body pose, independently of either IK socket.
		var mount:=Vector2(13,-54).lerp(Vector2(13,-53),work)
		var angle:=-PI*.25
		if str(state.workPhase)=="cast": angle-=sin(clampf((fposmod(t,9)-1)/.8,0,1)*PI)*.16
		elif str(state.workPhase)=="pull": angle-=.12
		mount=_body_transform(mount,lean)
		_rod_pose={"mount":mount,"angle":angle+lean,"depth":.155}
	for index in range(2):
		var side:="left" if index==0 else "right"
		var shoulder:=_body_transform(_v(data.joints[side+"Shoulder"]),lean)
		var first:=_length("upper_arm_"+side)
		var second:=_length("lower_arm_"+side)
		var hand:=shoulder+Vector2(-2 if index==0 else 2,(first+second)*.93)
		if walking: hand+=Vector2(sin(stride+index*PI)*4,-absf(sin(stride+index*PI))*2)
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
		var grip_part:Dictionary=data.parts.get("hand_rod_west",{})
		var palm_angle:=0.0
		if rod_hand and side=="right":
			var authored_axis:=(_v(grip_part.rodAxis[1])-_v(grip_part.rodAxis[0])).angle()
			palm_angle=float(_rod_pose.angle)-authored_axis
			hand=_rod_pose.mount+(_v(grip_part.wristPixel)-_v(grip_part.gripPixel)).rotated(palm_angle)
		if clip=="interact" and index==1: hand=shoulder+Vector2(6,-1+wave*2)+Vector2(0,first+second)*.5
		var reach:=(hand-shoulder).limit_length(first+second-.01)
		hand=shoulder+reach
		var elbow:=_ik(shoulder,hand,first,second,1 if index==0 else -1)
		var depth:=.14 if not back else -.12
		_bone("upper_arm_"+side,shoulder,elbow,depth)
		_bone("lower_arm_"+side,elbow,hand,depth+.01)
		if rod_hand and side=="right":
			var size:=_v(grip_part.size)
			_place_part("hand_rod_west",hand+(size*.5-_v(grip_part.wristPixel)).rotated(palm_angle),palm_angle,depth+.03)
			var palm:Sprite3D=sprites.hand_rod_west
			var grip_pixel:=_v(grip_part.gripPixel)
			var actual_grip:=palm.to_global(Vector3(grip_pixel.x-size.x*.5,size.y*.5-grip_pixel.y,0))
			var axis_a:=_v(grip_part.rodAxis[0])
			var axis_b:=_v(grip_part.rodAxis[1])
			var world_axis:Vector3=palm.global_basis*Vector3(axis_b.x-axis_a.x,axis_a.y-axis_b.y,0)
			actor.set_meta("body_grip",{"point":actual_grip,"axis":world_axis.normalized(),"part":"hand_rod_west","gripPixel":grip_part.gripPixel})
		else:
			_place_part("hand_"+side,hand+Vector2(0,1.5),0,depth+.03)
		_local_hands[side]=[hand.x,hand.y]
		var point:=to_global(Vector3(hand.x,-hand.y,depth+.06))
		hands[side]=point
	var snapshot_hands: Dictionary={}
	for side in hands:
		var p: Vector3=hands[side]
		snapshot_hands[side]=[p.x,p.y,p.z]
	actor.set_meta("body_hands",snapshot_hands)
	if rod_hand:
		var mount:Vector2=_rod_pose.mount
		var axis:=Vector2.RIGHT.rotated(float(_rod_pose.angle))
		var a:=mount-axis*9
		var b:=mount+axis*47
		actor.set_meta("body_rod",{"base":to_global(Vector3(a.x,-a.y,float(_rod_pose.depth))),"tip":to_global(Vector3(b.x,-b.y,float(_rod_pose.depth))),"source":"independent body-local tool pose"})
	_last_pose={"clip":clip,"direction":facing,"frame":state.frame,"phase":state.workPhase,"parts":sprites.size(),"handsLocal":_local_hands.duplicate(true),"toolFront":not back,"footPivot":[0,0],"rootMotion":false,"source":"original portrait cutout rig"}
	if _foot_plant!=null:
		_last_pose["contacts"]=_contact_pose.duplicate(true)
		for side in ["left","right"]:
			var entry:Dictionary=_last_pose.contacts.feet[side]
			var sole:Vector3=entry.sole
			var plant:Vector3=entry.plant
			entry["worldSole"]=[sole.x,sole.y,sole.z]
			entry["worldPlant"]=[plant.x,plant.y,plant.z]
		_last_pose["gripMeasurement"]={"status":"authored" if rod_hand else "inactive","part":"hand_rod_west" if rod_hand else "","scope":"West fishing fist only; other directions remain unmeasured"}

func _fixed_bone(name:String,a:Vector3,b:Vector3) -> void:
	var up:Vector3=(a-b).normalized()
	var right:=up.cross(Vector3(0,0,1)).normalized()
	if right.length()<.01: right=Vector3.RIGHT
	var normal:=right.cross(up).normalized()
	var sprite:Sprite3D=sprites[name]
	sprite.transform=Transform3D(Basis(right,up,normal),(a+b)*.5)
	sprite.modulate=_tint
	sprite.visible=true

func _contact_legs(pose:Dictionary) -> void:
	_pelvis_drop=-3.0
	var ankles:Dictionary={}
	for side in ["left","right"]:
		var entry:Dictionary=pose.feet[side]
		var part:Dictionary=data.parts["foot_"+side]
		var sole_pixel:Vector2=_sole_pixels[side]
		var sole:Vector3=to_local(entry.sole)
		var ankle:=sole+Vector3(float(part.size[0])*.5-sole_pixel.x,sole_pixel.y,0)
		ankles[side]=ankle
		var hip2:=_v(data.joints[side+"Hip"])
		var hip:=Vector3(hip2.x,-hip2.y,-.2 if side=="left" else -.05)
		var reach:=_length("upper_leg_"+side)+_length("lower_leg_"+side)-.25
		var horizontal:=Vector2(hip.x-ankle.x,hip.z-ankle.z).length_squared()
		var drop:=hip.y-ankle.y-sqrt(maxf(.01,reach*reach-horizontal))
		_pelvis_drop=maxf(_pelvis_drop,drop)
	_contact_pose["requestedPelvisDrop"]=_pelvis_drop
	_pelvis_drop=clampf(_pelvis_drop,-3.0,8.0)
	_contact_pose["pelvisDrop"]=_pelvis_drop
	_contact_pose["reachValid"]=float(_contact_pose.requestedPelvisDrop)<=8.0
	_contact_pose["maxLengthError"]=0.0
	for side in ["left","right"]:
		var entry:Dictionary=pose.feet[side]
		var part:Dictionary=data.parts["foot_"+side]
		var sole_pixel:Vector2=_sole_pixels[side]
		var sole:Vector3=to_local(entry.sole)
		var ankle:Vector3=ankles[side]
		var hip2:=_v(data.joints[side+"Hip"])
		var hip:=Vector3(hip2.x,-hip2.y-_pelvis_drop,-.2 if side=="left" else -.05)
		var first:=_length("upper_leg_"+side)
		var second:=_length("lower_leg_"+side)
		var vector:=ankle-hip
		var length:=clampf(vector.length(),.01,first+second-.001)
		var along:=vector.normalized()
		var offset:=(first*first-second*second+length*length)/(2.0*length)
		var facing:String=actor.body_animation_state().direction
		var hint:=Vector3.RIGHT if facing in ["east","west"] else Vector3(0,0,-1 if facing=="north" else 1)
		var bend:=hint-along*along.dot(hint)
		if bend.length()<.01: bend=Vector3.RIGHT
		bend=bend.normalized()
		var knee:=hip+along*offset+bend*sqrt(maxf(0,first*first-offset*offset))
		_fixed_bone("upper_leg_"+side,hip,knee)
		_fixed_bone("lower_leg_"+side,knee,ankle)
		var foot_sprite:Sprite3D=sprites["foot_"+side]
		var pixel_offset:=Vector3(sole_pixel.x-float(part.size[0])*.5,float(part.size[1])*.5-sole_pixel.y,0)
		foot_sprite.transform=Transform3D(Basis.IDENTITY,sole-pixel_offset)
		foot_sprite.modulate=_tint
		foot_sprite.visible=true
		var error:=maxf(absf(hip.distance_to(knee)-first),absf(knee.distance_to(ankle)-second))
		_contact_pose.maxLengthError=maxf(float(_contact_pose.maxLengthError),error)
		_contact_pose.feet[side]["solePixel"]=[sole_pixel.x,sole_pixel.y]
		_contact_pose.feet[side]["kneeLocal"]=[knee.x,knee.y,knee.z]


func pose_snapshot() -> Dictionary:
	return _last_pose.duplicate(true)
