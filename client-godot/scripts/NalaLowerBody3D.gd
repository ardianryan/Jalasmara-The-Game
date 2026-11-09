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
var _foot_views:Dictionary={}
var _pivot_offsets:Dictionary={}
var _support_extents:Dictionary={}
var _last_distance:=0.0
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

func _ankle_offset(side:String,direction:String,right:Vector3,vertical:float) -> Vector3:
	var leg:Dictionary=_data.views[direction].legs[side]
	var sole:=_vec(leg.solePixel)
	var rect:Array=leg.parts.foot
	var ankle:=_vec(leg.ankle)-Vector2(float(rect[0]),float(rect[1]))
	return right*(ankle.x-sole.x)+Vector3(0,0,(sole.y-ankle.y)/vertical)

func _rotated_shoe_clear(side:String,direction:String,logical:Vector2,world_sole:Vector3,right:Vector3,vertical:float) -> bool:
	if not _planner.airborne_clear(logical,world_sole): return false
	var leg:Dictionary=_data.views[direction].legs[side]
	var sole:=_vec(leg.solePixel)
	for edge in leg.soleEdgePixels:
		var pixel:=_vec(edge)
		var world:=world_sole+right*(pixel.x-sole.x)+Vector3(0,0,(sole.y-pixel.y)/vertical)
		if not _planner.airborne_clear(logical,world): return false
	return true

func _anatomy(view:Dictionary,feet:Dictionary,at:Vector2,right:Vector3,vertical:float,body_height:float=NAN) -> Dictionary:
	var ground:Vector3=renderer.ground_point(at)
	var root_hip:Vector3=ground+Vector3(0,0,28.0/vertical+(body_height-ground.z if not is_nan(body_height) else 0.0))
	var ankles:Dictionary={}
	var lengths:Dictionary={}
	var drop:=0.0
	var horizontal_invalid:=false
	for side in ["left","right"]:
		var leg:Dictionary=view.legs[side]
		var sole_pixel:=_vec(leg.solePixel)
		var foot_leg:Dictionary=_data.views[str(_foot_views.get(side,_direction))].legs[side]
		sole_pixel=_vec(foot_leg.solePixel)
		var foot:Array=foot_leg.parts.foot
		var ankle_source:=_vec(foot_leg.ankle)-Vector2(float(foot[0]),float(foot[1]))
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
		_support_extents.clear()
		for side in ["left","right"]:
			var extent:=Vector2.ZERO
			for source_view in _data.views.values():
				var source_leg:Dictionary=source_view.legs[side]
				for endpoint in source_leg.soleEdgePixels:
					var x:=float(endpoint[0])-float(source_leg.solePixel[0])
					extent.x=minf(extent.x,x)
					extent.y=maxf(extent.y,x)
			_support_extents[side]=extent
	var camera:Camera3D=renderer.camera_3d
	var basis:=camera.global_basis.orthonormalized()
	var up:=basis.y
	var right:=basis.x
	var vertical:=maxf(.1,up.dot(Vector3(0,0,1)))
	var state:Dictionary=visual.locomotion_state()
	var desired:=str(state.artworkDirection)
	if _direction=="": _direction=desired
	if _foot_views.is_empty(): _foot_views={"left":_direction,"right":_direction}
	var stored:Dictionary=_planner.snapshot()
	if not bool(state.poseFrozen) and _direction!=desired and not stored.feet.is_empty() and _facing_frame!=Engine.get_process_frames():
		var index:=DIRECTIONS.find(_direction)
		var target:=DIRECTIONS.find(desired)
		var forward:=posmod(target-index,8)
		var adjacent:String=DIRECTIONS[posmod(index+(1 if forward<=4 else -1),8)]
		var trial:=_anatomy(_data.views[adjacent],stored.feet,actor.position,right,vertical,float(stored.bodyHeight))
		var look_ahead:=actor.position
		var accepted:Vector2=actor.get("velocity") if "velocity" in actor else Vector2.ZERO
		if accepted.length()>.1:
			var world_delta:Vector3=renderer.ground_point(actor.position+accepted.normalized())-renderer.ground_point(actor.position)
			world_delta.z=0
			look_ahead+=accepted.normalized()*4.0/maxf(.001,world_delta.length())
		var future:=_anatomy(_data.views[adjacent],stored.feet,look_ahead,right,vertical,float(stored.bodyHeight))
		if not bool(trial.horizontalInvalid) and not bool(future.horizontalInvalid) and maxf(float(trial.drop),float(future.drop))*vertical<=6.0:
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
	var pose:Dictionary=_planner.update(actor.position,moved,frozen,sole_offsets,right,delta,_support_extents)
	if frozen and not _last.is_empty():
		proxy.visible=false
		return _last.duplicate(true)
	var accepted_distance:float=pose.acceptedDistance
	var moved_distance:=maxf(0,accepted_distance-_last_distance)
	_last_distance=accepted_distance
	for side in ["left","right"]:
		var entry:Dictionary=pose.feet[side]
		var correction:Vector3=_pivot_offsets.get(side,Vector3.ZERO)
		if bool(entry.grounded): correction=Vector3.ZERO
		else:
			var remaining:=maxf(0,float(pose.landingDistance)-float(pose.swingDistance))
			if moved_distance>0: correction*=remaining/maxf(.001,remaining+moved_distance)
			var previous_direction:String=_foot_views[side]
			var index:=DIRECTIONS.find(previous_direction)
			var forward:=posmod(DIRECTIONS.find(direction)-index,8)
			var candidate:String=DIRECTIONS[posmod(index+(1 if forward<=4 else -1),8)] if direction!=previous_direction else previous_direction
			if candidate!=previous_direction and float(pose.swingDistance)<float(pose.landingDistance)*.85:
				var rotated:=correction+_ankle_offset(side,previous_direction,right,vertical)-_ankle_offset(side,candidate,right,vertical)
				if _rotated_shoe_clear(side,candidate,entry.logical,Vector3(entry.sole)+rotated,right,vertical):
					var pivot:Vector3=Vector3(entry.sole)+correction+_ankle_offset(side,previous_direction,right,vertical)
					entry["rotationAnchorWorld"]=[pivot.x,pivot.y,pivot.z]
					correction=rotated
					_foot_views[side]=candidate
		_pivot_offsets[side]=correction
		entry.sole=Vector3(entry.sole)+correction
		entry["pivotCorrectionWorld"]=[correction.x,correction.y,correction.z]
		entry["footDirection"]=str(_foot_views[side])
	var ground:Vector3=renderer.ground_point(actor.position)
	var support_body_offset:=float(pose.bodyHeight)-ground.z
	var root_hip:=ground+Vector3(0,0,28.0/vertical+support_body_offset)
	var anatomy:=_anatomy(view,pose.feet,actor.position,right,vertical,float(pose.bodyHeight))
	var ankles:Dictionary=anatomy.ankles
	var lengths:Dictionary=anatomy.lengths
	var drop:float=anatomy.drop
	var max_length_error:=0.0
	var unreachable:bool=anatomy.horizontalInvalid
	# Eight source pixels is an explicit rejection bound, never an IK stretch allowance.
	var drop_limit:=8.0/vertical
	if drop>drop_limit: unreachable=true
	var requested_drop:=drop
	if unreachable:
		visible=false
		proxy.visible=true
		_last={"enabled":false,"rejected":true,"reason":"fixed-length reach","direction":direction,"desiredDirection":desired,"contacts":pose,"reachValid":false,"requestedDropPixels":requested_drop*vertical,"supportBodyOffsetPixels":support_body_offset*vertical,"rootMotion":false}
		return _last.duplicate(true)
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
		for name in ["thigh","shin"]:
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
		var foot_view:Dictionary=_data.views[str(_foot_views[side])]
		var foot_leg:Dictionary=foot_view.legs[side]
		var foot_rect:Array=foot_leg.parts.foot
		sprite.texture=_texture(_atlas,Rect2(Vector2(float(foot_view.sourceColumn)*128+float(foot_rect[0]),float(foot_rect[1])),Vector2(float(foot_rect[2]),float(foot_rect[3]))))
		var sole:=_vec(foot_leg.solePixel)
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
	_last={"enabled":true,"identity":"male_nusantara","outfit":outfit,"direction":direction,"desiredDirection":desired,"heldFacing":direction!=desired,"contacts":pose,"calibration":1.0/vertical,"supportBodyOffsetPixels":support_body_offset*vertical,"pelvisDropPixels":drop*vertical,"requestedDropPixels":requested_drop*vertical,"reachValid":not unreachable,"maxLengthError":max_length_error,"attachmentOffset":root_hip-ground-up*28-basis.z*8,"rootMotion":false,"status":"opt-in lower-body pilot, full natural gait unaccepted"}
	return _last.duplicate(true)
