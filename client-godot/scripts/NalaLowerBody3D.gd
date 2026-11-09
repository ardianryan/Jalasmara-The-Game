extends Node3D

var renderer:Node
var actor:Node2D
var _visual:Sprite2D
var _outfit:=""
var _data:Dictionary={}
var _atlas:Texture2D
var _parts:Dictionary={}
var _frames:Dictionary={}
var _planner:RefCounted
var _last:Dictionary={}
var _direction:=""
var _facing_frame:=-1
const DIRECTIONS:=["east","south_east","south","south_west","west","north_west","north","north_east"]

func configure(owner_renderer:Node,person:Node2D) -> void:
	renderer=owner_renderer
	actor=person
	_planner=preload("res://scripts/NalaFootPlant.gd").new()
	_planner.configure(renderer)
	for name in ["upper","left_thigh","left_shin","left_foot","right_thigh","right_shin","right_foot"]:
		var sprite:=Sprite3D.new()
		sprite.name=name
		sprite.shaded=false
		sprite.alpha_cut=SpriteBase3D.ALPHA_CUT_DISCARD
		sprite.alpha_scissor_threshold=.5
		sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		sprite.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.pixel_size=1
		add_child(sprite)
		_parts[name]=sprite

func supported(visual:Sprite2D) -> bool:
	return str(visual.get("appearance"))=="male_nusantara" and str(visual.get("outfit")) in ["daily","explorer"] and visual.directional_pilot_active()

func _texture(atlas:Texture2D,rect:Rect2) -> Texture2D:
	var key:=str(atlas.get_instance_id())+str(rect)
	if not _frames.has(key):
		var texture:=AtlasTexture.new()
		texture.atlas=atlas
		texture.region=rect
		texture.filter_clip=true
		_frames[key]=texture
	return _frames[key]

func _vec(pair:Array) -> Vector2:
	return Vector2(float(pair[0]),float(pair[1]))

func _fixed_bone(sprite:Sprite3D,a:Vector3,b:Vector3,camera:Camera3D,tint:Color) -> void:
	var y:=(a-b).normalized()
	var x:=y.cross(camera.global_basis.z).normalized()
	if x.length()<.1: x=camera.global_basis.x
	var z:=x.cross(y).normalized()
	var basis:=Basis(x,y,z)
	# The source segment is vertical and has an immutable calibrated world length.
	sprite.transform=Transform3D(basis*Basis.from_scale(Vector3(1,a.distance_to(b)/sprite.texture.get_height(),1)),(a+b)*.5)
	sprite.modulate=tint

func _knee(a:Vector3,b:Vector3,first:float,second:float,hint:Vector3) -> Vector3:
	var vector:=b-a
	var distance:=clampf(vector.length(),.001,first+second-.0001)
	var along:=vector.normalized()
	var offset:=(first*first-second*second+distance*distance)/(2*distance)
	var bend:=hint-along*along.dot(hint)
	if bend.length()<.001: bend=Vector3.RIGHT-along*along.x
	return a+along*offset+bend.normalized()*sqrt(maxf(0,first*first-offset*offset))

func _anatomy(view:Dictionary,feet:Dictionary,at:Vector2,right:Vector3,vertical:float) -> Dictionary:
	var root_hip:Vector3=renderer.ground_point(at)+Vector3(0,0,28.0/vertical)
	var ankles:Dictionary={}
	var lengths:Dictionary={}
	var drop:=0.0
	var horizontal_invalid:=false
	for side in ["left","right"]:
		var leg:Dictionary=view.legs[side]
		var sole_pixel:=_vec(leg.solePixel)
		var foot:Array=leg.parts.foot
		var ankle_source:=_vec(leg.ankle)-Vector2(float(foot[0]),float(foot[1]))
		var ankle:Vector3=Vector3(feet[side].sole)+right*(ankle_source.x-sole_pixel.x)+Vector3(0,0,(sole_pixel.y-ankle_source.y)/vertical)
		ankles[side]=ankle
		var first:=_vec(leg.hip).distance_to(_vec(leg.knee))/vertical
		var second:=_vec(leg.knee).distance_to(_vec(leg.ankle))/vertical
		lengths[side]=Vector2(first,second)
		var hip:=root_hip+right*(float(leg.hip[0])-64.0)
		var horizontal:=Vector2(hip.x-ankle.x,hip.y-ankle.y).length_squared()
		var reach:=first+second-.1
		if horizontal>=reach*reach: horizontal_invalid=true
		drop=maxf(drop,hip.z-ankle.z-sqrt(maxf(.001,reach*reach-horizontal)))
	return {"ankles":ankles,"lengths":lengths,"drop":drop,"horizontalInvalid":horizontal_invalid}

func update_pose(proxy:Sprite3D,visual:Sprite2D,delta:float) -> Dictionary:
	if not supported(visual): visible=false; return {}
	var outfit:=str(visual.get("outfit"))
	if _outfit!=outfit:
		_outfit=outfit
		_data=JSON.parse_string(FileAccess.get_file_as_string("res://resources/art/player-lower-body/male-nusantara-"+outfit+"-v1.json"))
		_atlas=load(str(_data.source))
	var camera:Camera3D=renderer.camera_3d
	var basis:=camera.global_basis.orthonormalized()
	var up:=basis.y
	var right:=basis.x
	var vertical:=maxf(.1,up.dot(Vector3(0,0,1)))
	var state:Dictionary=visual.locomotion_state()
	var desired:=str(state.artworkDirection)
	if _direction=="": _direction=desired
	var stored:Dictionary=_planner.snapshot()
	if not bool(state.poseFrozen) and _direction!=desired and not stored.feet.is_empty() and _facing_frame!=Engine.get_process_frames():
		var index:=DIRECTIONS.find(_direction)
		var target:=DIRECTIONS.find(desired)
		var forward:=posmod(target-index,8)
		var adjacent:String=DIRECTIONS[posmod(index+(1 if forward<=4 else -1),8)]
		var trial:=_anatomy(_data.views[adjacent],stored.feet,actor.position,right,vertical)
		if not bool(trial.horizontalInvalid) and float(trial.drop)*vertical<=6.0:
			_direction=adjacent
			_facing_frame=Engine.get_process_frames()
	var direction:=_direction
	var view:Dictionary=_data.views[direction]
	var hips:Dictionary={}
	var sole_offsets:Dictionary={}
	for side in ["left","right"]:
		hips[side]=float(view.legs[side].hip[0])-64.0
		sole_offsets[side]=float(view.legs[side].parts.foot[0])+float(view.legs[side].solePixel[0])-64.0
	var frozen:=bool(state.poseFrozen)
	var moved:=bool(state.poseWalking) and float(state.speed)>.1
	var pose:Dictionary=_planner.update(actor.position,moved,frozen,sole_offsets,right,delta)
	if frozen and not _last.is_empty():
		proxy.visible=false
		return _last.duplicate(true)
	var ground:Vector3=renderer.ground_point(actor.position)
	var root_hip:=ground+Vector3(0,0,28.0/vertical)
	var anatomy:=_anatomy(view,pose.feet,actor.position,right,vertical)
	var ankles:Dictionary=anatomy.ankles
	var lengths:Dictionary=anatomy.lengths
	var drop:float=anatomy.drop
	var max_length_error:=0.0
	var unreachable:bool=anatomy.horizontalInvalid
	# Eight source pixels is an explicit rejection bound, never an IK stretch allowance.
	var drop_limit:=8.0/vertical
	if drop>drop_limit: unreachable=true
	var requested_drop:=drop
	drop=clampf(drop,0,drop_limit)
	root_hip.z-=drop
	var heading:Vector3=renderer.map_point(actor.position+{"east":Vector2.RIGHT,"west":Vector2.LEFT,"north":Vector2.UP,"south":Vector2.DOWN,"north_east":Vector2(1,-1),"north_west":Vector2(-1,-1),"south_east":Vector2(1,1),"south_west":Vector2(-1,1)}[direction],0)-renderer.map_point(actor.position,0)
	if actor.has_meta("nala_last_world_heading"): heading=actor.get_meta("nala_last_world_heading")
	var raw_velocity:Vector2=actor.get("velocity") if "velocity" in actor else Vector2.ZERO
	if raw_velocity.length()>.1:
		heading=renderer.map_point(actor.position+raw_velocity.normalized(),0)-renderer.map_point(actor.position,0)
		actor.set_meta("nala_last_world_heading",heading)
	for side in ["left","right"]:
		var leg:Dictionary=view.legs[side]
		for name in ["thigh","shin","foot"]:
			var rect:Array=leg.parts[name]
			_parts[side+"_"+name].texture=_texture(_atlas,Rect2(Vector2(float(view.sourceColumn)*128+float(rect[0]),float(rect[1])),Vector2(float(rect[2]),float(rect[3]))))
		var hip:=root_hip+right*float(hips[side])
		var ankle:Vector3=ankles[side]
		var size:Vector2=lengths[side]
		var knee:=_knee(hip,ankle,size.x,size.y,heading.normalized())
		_fixed_bone(_parts[side+"_thigh"],hip,knee,camera,proxy.modulate)
		_fixed_bone(_parts[side+"_shin"],knee,ankle,camera,proxy.modulate)
		max_length_error=maxf(max_length_error,maxf(absf(hip.distance_to(knee)-size.x),absf(knee.distance_to(ankle)-size.y)))
		var sprite:Sprite3D=_parts[side+"_foot"]
		var sole:=_vec(leg.solePixel)
		var foot_basis:=Basis(right,Vector3(0,0,1)/vertical,right.cross(Vector3(0,0,1)).normalized())
		var pixel_offset:=foot_basis*Vector3(sole.x-sprite.texture.get_width()*.5,sprite.texture.get_height()*.5-sole.y,0)
		sprite.transform=Transform3D(foot_basis,Vector3(pose.feet[side].sole)-pixel_offset)
		sprite.modulate=proxy.modulate
		pose.feet[side]["hipWorld"]=[hip.x,hip.y,hip.z]
		pose.feet[side]["kneeWorld"]=[knee.x,knee.y,knee.z]
		pose.feet[side]["ankleWorld"]=[ankle.x,ankle.y,ankle.z]
		pose.feet[side]["lengths"]=[size.x,size.y]
	var cell:=visual.texture.get_size()/Vector2(visual.hframes,visual.vframes)
	var origin:=Vector2(int(state.frame)*128,DIRECTIONS.find(direction)*128) if bool(state.poseWalking) else Vector2(DIRECTIONS.find(direction)*128,0)
	var upper:Sprite3D=_parts.upper
	upper.texture=_texture(visual.texture,Rect2(origin,Vector2(128,76)))
	upper.transform=Transform3D(basis,root_hip+up*38)
	upper.modulate=proxy.modulate
	visible=true
	proxy.visible=false
	_last={"enabled":true,"identity":"male_nusantara","outfit":outfit,"direction":direction,"desiredDirection":desired,"heldFacing":direction!=desired,"contacts":pose,"calibration":1.0/vertical,"pelvisDropPixels":drop*vertical,"requestedDropPixels":requested_drop*vertical,"reachValid":not unreachable,"maxLengthError":max_length_error,"attachmentOffset":root_hip-ground-up*28-basis.z*8,"rootMotion":false,"status":"opt-in lower-body pilot, full natural gait unaccepted"}
	return _last.duplicate(true)
