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
var _foot_planes:Dictionary={}
var _support_extents:Dictionary={}
var _opaque_vertices:Dictionary={}
var _last_distance:=0.0
const DIRECTIONS:=["east","south_east","south","south_west","west","north_west","north","north_east"]
const FootPlane=preload("res://scripts/NalaFootPlane.gd")

func configure(owner_renderer:Node,person:Node2D) -> void:
	renderer=owner_renderer
	actor=person
	_planner=preload("res://scripts/NalaFootPlant.gd").new()
	var contract:Dictionary=preload("res://scripts/NalaPhysicalMotion.gd").gait_contract() if bool(person.get_meta("nala_physical_walk_pilot",false)) else {}
	_planner.configure(renderer,contract)
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

func _ankle_offset(side:String,direction:String,right:Vector3,vertical:float,rotation:Quaternion=Quaternion.IDENTITY) -> Vector3:
	var leg:Dictionary=_data.views[direction].legs[side]
	var sole:=_vec(leg.solePixel)
	var rect:Array=leg.parts.foot
	var ankle:=_vec(leg.ankle)-Vector2(float(rect[0]),float(rect[1]))
	return rotation*(right*(ankle.x-sole.x)+Vector3(0,0,(sole.y-ankle.y)/vertical))

func _plane(side:String) -> Quaternion:
	return _foot_planes.get(side,Quaternion.IDENTITY)

func _rotated_shoe_clear(side:String,direction:String,logical:Vector2,world_sole:Vector3,right:Vector3,vertical:float) -> bool:
	if not _planner.airborne_clear(logical,world_sole): return false
	var leg:Dictionary=_data.views[direction].legs[side]
	var sole:=_vec(leg.solePixel)
	if bool(actor.get_meta("nala_physical_walk_pilot",false)):
		var geometry:Dictionary={"leg":leg,"vertices":_opaque_vertices[direction+"/"+side],"right":right,"vertical":vertical}
		return FootPlane.airborne_clear(renderer,logical,geometry,world_sole,_plane(side))
	for edge in leg.soleEdgePixels:
		var pixel:=_vec(edge)
		var world:=world_sole+_plane(side)*(right*(pixel.x-sole.x)+Vector3(0,0,(sole.y-pixel.y)/vertical))
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
		var ankle:Vector3=Vector3(feet[side].sole)+_plane(side)*(right*(ankle_source.x-sole_pixel.x)+Vector3(0,0,(sole_pixel.y-ankle_source.y)/vertical))
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
	if not supported(visual):
		_planner.begin_contact_frame(false)
		visible=false
		return {}
	_planner.begin_contact_frame(bool(_last.get("enabled",true)))
	var outfit:=str(visual.get("outfit"))
	if _outfit!=outfit:
		_outfit=outfit
		_data=JSON.parse_string(FileAccess.get_file_as_string("res://resources/art/player-lower-body/male-nusantara-"+outfit+"-v1.json"))
		_atlas=load(str(_data.source))
		_support_extents.clear()
		_opaque_vertices.clear()
		if bool(actor.get_meta("nala_physical_walk_pilot",false)):
			var source_image:Image=_atlas.get_image()
			if source_image.is_compressed(): source_image.decompress()
			for source_direction in _data.views:
				var source_view:Dictionary=_data.views[source_direction]
				for side in ["left","right"]:
					_opaque_vertices[str(source_direction)+"/"+side]=FootPlane.opaque_vertices(source_image,int(source_view.sourceColumn),source_view.legs[side].parts.foot)
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
			_planner.note_body_facing_transition()
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
	var physical_plane:=bool(actor.get_meta("nala_physical_walk_pilot",false))
	if physical_plane and direction!=desired: _planner.request_body_facing_handover()
	var geometry:Dictionary={}
	if physical_plane:
		for side in ["left","right"]:
			var foot_direction:=str(_foot_views[side])
			var current_leg:Dictionary=_data.views[foot_direction].legs[side]
			var body_leg:Dictionary=view.legs[side]
			var pivot:Vector3=_pivot_offsets.get(side,Vector3.ZERO)
			geometry[side]={"id":outfit+"/"+foot_direction+"/"+side,"leg":current_leg,"bodyLeg":body_leg,"vertices":_opaque_vertices[foot_direction+"/"+side],"right":right,"vertical":vertical,"plane":_plane(side),"pivot":pivot}
			var view_steps:=posmod(DIRECTIONS.find(direction)-DIRECTIONS.find(foot_direction),8)
			geometry[side]["bodyFootViewSteps"]=mini(view_steps,8-view_steps)
			var current_ankle_z:float=float(current_leg.solePixel[1])-float(current_leg.ankle[1])+float(current_leg.parts.foot[1])
			var body_ankle_z:float=float(body_leg.solePixel[1])-float(body_leg.ankle[1])+float(body_leg.parts.foot[1])
			if foot_direction!=direction and pivot.is_finite() and _plane(side).angle_to(Quaternion.IDENTITY)<.0001 and absf(current_ankle_z-body_ankle_z)<.0001:
				geometry[side]["heldMaskCertified"]=true
	var planner_delta:=delta
	var settlement_budget:=0.0
	var settlement_ready:=true
	var settling:=false
	if physical_plane and not frozen and not stored.feet.is_empty() and str(stored.swingSide)!="":
		var motion:Vector3=renderer.ground_point(actor.position)-renderer.ground_point(Vector2(stored.actorLogical))
		motion.z=0
		if motion.length()<=.00001:
			settling=true
			var side:=str(stored.swingSide)
			var entry:Dictionary=stored.feet[side]
			var target:Vector3=entry.toWorld if entry.has("settlingTarget") else renderer.ground_point(entry.logical)
			var raw_distance:float=Vector3(entry.sole).distance_to(target)
			var pivot_distance:float=Vector3(_pivot_offsets.get(side,Vector3.ZERO)).length()
			var total:=raw_distance+pivot_distance
			if total>.000001:
				planner_delta=delta*raw_distance/total
				settlement_budget=maxf(0,delta)*24.0*pivot_distance/total
			var target_plane:Quaternion=FootPlane.contact_rotation(renderer,entry.get("settlingTarget",entry.logical),right)
			settlement_ready=pivot_distance<=settlement_budget+.001 and _plane(side).angle_to(target_plane)<=.001
	var pose:Dictionary=_planner.update(actor.position,moved,frozen,sole_offsets,right,planner_delta,_support_extents,geometry,settlement_ready)
	pose["visualSettlement"]={"active":settling,"rawSeconds":planner_delta,"pivotDistanceBudget":settlement_budget,"contactReady":settlement_ready}
	for entry in pose.feet.values():
		if (entry.has("treadPlan") and not bool(entry.treadPlan.valid)) or (entry.has("rampCurvePlan") and not bool(entry.rampCurvePlan.valid)) or not bool(entry.get("landingGeometryValid",true)):
			visible=false
			proxy.visible=true
			_last={"enabled":false,"rejected":true,"reason":"no supported opaque landing or terrain-curve budget","contacts":pose,"reachValid":false,"rootMotion":false}
			return _last.duplicate(true)
	if frozen and not _last.is_empty():
		proxy.visible=false
		var frozen_pose:Dictionary=_last.duplicate(true)
		if physical_plane:
			frozen_pose.contacts.rawContactEvents=[]
			frozen_pose.contacts.rawTraceEpoch=pose.rawTraceEpoch
			frozen_pose.contacts.rawTraceOverflow=0
			frozen_pose["contactTrace"]=_planner.publish_contact_trace(bool(frozen_pose.get("enabled",false)) and bool(frozen_pose.get("reachValid",false)))
			frozen_pose.contacts.rawTraceEpoch=frozen_pose.contactTrace.epoch
		return frozen_pose
	var accepted_distance:float=pose.acceptedDistance
	var moved_distance:=maxf(0,accepted_distance-_last_distance)
	_last_distance=accepted_distance
	for side in ["left","right"]:
		var entry:Dictionary=pose.feet[side]
		if not _foot_planes.has(side):
			_foot_planes[side]=FootPlane.contact_rotation(renderer,entry.logical,right) if physical_plane and bool(entry.grounded) else Quaternion.IDENTITY
		var correction:Vector3=_pivot_offsets.get(side,Vector3.ZERO)
		if settling: correction=correction.move_toward(Vector3.ZERO,settlement_budget)
		if bool(entry.grounded): correction=Vector3.ZERO
		else:
			var remaining:=maxf(0,float(pose.landingDistance)-float(pose.swingDistance))
			if moved_distance>0: correction*=remaining/maxf(.001,remaining+moved_distance)
			var previous_direction:String=_foot_views[side]
			var index:=DIRECTIONS.find(previous_direction)
			var forward:=posmod(DIRECTIONS.find(direction)-index,8)
			var candidate:String=DIRECTIONS[posmod(index+(1 if forward<=4 else -1),8)] if direction!=previous_direction else previous_direction
			if candidate!=previous_direction and float(pose.swingDistance)<float(pose.landingDistance)*.85:
				var rotated:=correction+_ankle_offset(side,previous_direction,right,vertical,_plane(side))-_ankle_offset(side,candidate,right,vertical,_plane(side))
				var landing_fits:=true
				if physical_plane:
					var next_geometry:Dictionary={"id":outfit+"/"+candidate+"/"+side,"leg":_data.views[candidate].legs[side],"vertices":_opaque_vertices[candidate+"/"+side],"right":right,"vertical":vertical}
					landing_fits=_planner.landing_geometry_supported(entry.to,next_geometry)
					entry["viewLandingFit"]={"candidate":candidate,"supported":landing_fits,"target":entry.to}
					if str(entry.get("treadPlan",{}).get("curveType",""))=="stair_swept_support":
						var path_fit:=preload("res://scripts/NalaStairSupportCurve.gd").view_envelope(entry.treadPlan,next_geometry,rotated,_plane(side))
						entry["viewPathFit"]={"candidate":candidate,"result":path_fit}
						landing_fits=landing_fits and bool(path_fit.supported)
				if landing_fits and _rotated_shoe_clear(side,candidate,entry.logical,Vector3(entry.sole)+rotated,right,vertical):
					var pivot:Vector3=Vector3(entry.sole)+correction+_ankle_offset(side,previous_direction,right,vertical,_plane(side))
					var after:=Vector3(entry.sole)+rotated+_ankle_offset(side,candidate,right,vertical,_plane(side))
					entry["viewRotationPivot"]={"before":[pivot.x,pivot.y,pivot.z],"after":[after.x,after.y,after.z],"previousDirection":previous_direction,"nextDirection":candidate}
					entry["rotationAnchorWorld"]=[pivot.x,pivot.y,pivot.z]
					correction=rotated
					_foot_views[side]=candidate
		if physical_plane:
			var current:=_plane(side)
			var target:Quaternion=FootPlane.contact_rotation(renderer,entry.logical if bool(entry.grounded) else entry.to,right)
			var current_terrain:Quaternion=FootPlane.contact_rotation(renderer,entry.logical,right)
			var envelope_active:=not bool(entry.grounded) and bool(entry.get("fixedRampTarget",false))
			if not bool(entry.grounded) and not envelope_active and current_terrain.angle_to(Quaternion.IDENTITY)>.001: target=current_terrain
			entry["orientationFollowsCurrentRamp"]=not bool(entry.grounded) and not envelope_active and current_terrain.angle_to(Quaternion.IDENTITY)>.001
			if bool(entry.grounded):
				if current.angle_to(target)>.001:
					visible=false
					proxy.visible=true
					entry["unfinishedPlaneAngle"]=current.angle_to(target)
					_last={"enabled":false,"rejected":true,"reason":"foot-plane rotation unfinished at contact","contacts":pose,"reachValid":false,"rootMotion":false}
					return _last.duplicate(true)
			else:
				var foot_leg:Dictionary=_data.views[str(_foot_views[side])].legs[side]
				var allowance:=moved_distance if moved_distance>.00001 else maxf(0,delta)*24.0
				var next:Quaternion=FootPlane.advance(current,target,allowance,FootPlane.radius_about_ankle(foot_leg,vertical))
				var foot_direction:=str(_foot_views[side])
				var mask:Dictionary={"leg":foot_leg,"vertices":_opaque_vertices[foot_direction+"/"+side],"right":right,"vertical":vertical}
				var ankle:=Vector3(entry.sole)+correction+_ankle_offset(side,foot_direction,right,vertical,current)
				if envelope_active:
					var support:=FootPlane.ankle_support(renderer,entry.logical,mask,ankle,next)
					if not bool(support.valid):
						visible=false
						proxy.visible=true
						_last={"enabled":false,"rejected":true,"reason":"original foot support envelope has no ground inverse","contacts":pose,"reachValid":false,"rootMotion":false}
						return _last.duplicate(true)
					var lift:=0.0
					var carried:=0.0
					if not entry.has("settlingTarget"):
						var phase:=clampf(float(pose.swingDistance)/float(pose.landingDistance),0,1)
						var progress:=phase*phase*(3.0-2.0*phase)
						if entry.has("viewRotationPivot"):
							var old_direction:=str(entry.viewRotationPivot.previousDirection)
							var old_mask:Dictionary={"leg":_data.views[old_direction].legs[side],"vertices":_opaque_vertices[old_direction+"/"+side],"right":right,"vertical":vertical}
							var old_support:=FootPlane.ankle_support(renderer,entry.logical,old_mask,ankle,next)
							if not bool(old_support.valid):
								visible=false
								proxy.visible=true
								_last={"enabled":false,"rejected":true,"reason":"previous shoe support envelope has no ground inverse","contacts":pose,"reachValid":false,"rootMotion":false}
								return _last.duplicate(true)
							var before:float=entry.rampCurvePlan.fromSupportOffset
							var remaining:=maxf(.000001,1.0-progress)
							entry.rampCurvePlan.fromSupportOffset=before+(float(old_support.height)-float(support.height))/remaining
							entry["viewSupportContinuity"]={"previousDirection":old_direction,"nextDirection":foot_direction,"previousSupport":old_support.height,"nextSupport":support.height,"offsetBefore":before,"offsetAfter":entry.rampCurvePlan.fromSupportOffset,"remainingProgress":remaining}
						lift=sin(phase*PI)*3.0
						carried=float(entry.rampCurvePlan.fromSupportOffset)*(1.0-progress)
					var planned_z:float=maxf(ankle.z,float(support.height)+.02) if entry.has("settlingTarget") else float(support.height)+maxf(.02,lift+carried)
					var adjustment:=planned_z-ankle.z
					var before_plan:=ankle
					entry.sole=Vector3(entry.sole)+Vector3(0,0,adjustment)
					ankle.z=planned_z
					if entry.has("rotationAnchorWorld"):
						var source_anchor:Array=entry.rotationAnchorWorld
						entry["rotationAnchorWorld"]=[float(source_anchor[0]),float(source_anchor[1]),float(source_anchor[2])+adjustment]
					entry["supportPlanTranslation"]={"before":[before_plan.x,before_plan.y,before_plan.z],"after":[ankle.x,ankle.y,ankle.z],"deltaZ":adjustment}
					_planner.commit_raw_support(side,entry.sole,float(entry.rampCurvePlan.fromSupportOffset))
					entry["supportEnvelope"]={"ankleSupportHeight":support.height,"sineLift":lift,"carriedStartOffset":carried,"rawHeightAdjustment":adjustment,"originalPoints":support.points,"baseCurveBoundIncludesEnvelope":false,"minimumAirborneClearance":.02}
				var current_clear:=FootPlane.airborne_clear(renderer,entry.logical,mask,ankle-_ankle_offset(side,foot_direction,right,vertical,current),current)
				var backtracks:=0
				var next_clear:=FootPlane.airborne_clear(renderer,entry.logical,mask,ankle-_ankle_offset(side,foot_direction,right,vertical,next),next)
				while backtracks<10 and not next_clear:
					next=current.slerp(next,.5).normalized()
					backtracks+=1
					next_clear=FootPlane.airborne_clear(renderer,entry.logical,mask,ankle-_ankle_offset(side,foot_direction,right,vertical,next),next)
				if not next_clear: next=current
				entry["rotationClearance"]={"currentClear":current_clear,"selectedClear":next_clear or current_clear,"backtracks":backtracks,"originalOpaqueVertices":mask.vertices.size()}
				if current.angle_to(next)>.000001:
					var offset:=_ankle_offset(side,str(_foot_views[side]),right,vertical,current)
					var pivot:Vector3=Vector3(entry.sole)+correction+offset
					entry["rotationAnchorWorld"]=[pivot.x,pivot.y,pivot.z]
					correction+=offset-_ankle_offset(side,str(_foot_views[side]),right,vertical,next)
					var after:=Vector3(entry.sole)+correction+_ankle_offset(side,str(_foot_views[side]),right,vertical,next)
					entry["planeRotationPivot"]={"before":[pivot.x,pivot.y,pivot.z],"after":[after.x,after.y,after.z]}
					_foot_planes[side]=next
			var support:Vector3=_plane(side)*right
			entry["footPlane"]={"rotation":[_plane(side).x,_plane(side).y,_plane(side).z,_plane(side).w],"supportAxis":[support.x,support.y,support.z],"angleRemaining":_plane(side).angle_to(target),"rigidOriginalPixels":true}
		_pivot_offsets[side]=correction
		entry.sole=Vector3(entry.sole)+correction
		entry["pivotCorrectionWorld"]=[correction.x,correction.y,correction.z]
		entry["footDirection"]=str(_foot_views[side])
		entry["desiredFootDirection"]=direction
		var prior_foot:Dictionary=_last.get("contacts",{}).get("feet",{}).get(side,{})
		var view_held:=str(_foot_views[side])!=direction
		entry["heldFootViewSeconds"]=float(prior_foot.get("heldFootViewSeconds",0.0))+maxf(0,delta) if view_held else 0.0
		entry["heldFootViewDistance"]=float(prior_foot.get("heldFootViewDistance",0.0))+moved_distance if view_held else 0.0
	var ramp_plan:=false
	for entry in pose.feet.values(): ramp_plan=ramp_plan or bool(entry.get("fixedRampTarget",false))
	if physical_plane and ramp_plan and (moved_distance>.00001 or settling) and not stored.feet.is_empty() and int(pose.discontinuityResets)==int(stored.get("discontinuityResets",0)):
		var footprint_height:=INF
		var current_ramp:=false
		var footprints:Dictionary={}
		for side in ["left","right"]:
			var entry:Dictionary=pose.feet[side]
			var foot_direction:=str(_foot_views[side])
			var mask:Dictionary={"leg":_data.views[foot_direction].legs[side],"vertices":_opaque_vertices[foot_direction+"/"+side],"right":right,"vertical":vertical}
			var support:=FootPlane.footprint_support(renderer,entry.logical,mask,entry.sole,_plane(side),Callable(_planner,"legal_support"))
			if not bool(support.valid):
				visible=false
				proxy.visible=true
				_last={"enabled":false,"rejected":true,"reason":"current original-foot body support has no legal ground inverse","contacts":pose,"reachValid":false,"rootMotion":false}
				return _last.duplicate(true)
			footprints[side]=support
			footprint_height=minf(footprint_height,float(support.height))
			current_ramp=current_ramp or not support.ramps.is_empty()
		if current_ramp:
			var transfer:Dictionary=_planner.commit_current_body_support(float(stored.get("bodyHeight",pose.bodyHeight)),footprint_height,moved_distance,delta)
			pose.bodyHeight=transfer.bodyHeight
			transfer["footprints"]=footprints
			transfer["futureLandingUsed"]=false
			pose["currentFootprintBodyTransfer"]=transfer
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
	for side in ["left","right"]:
		var hip:=root_hip+right*float(hips[side])
		var limb:Vector2=lengths[side]
		var distance:float=hip.distance_to(ankles[side])
		if distance<absf(limb.x-limb.y):
			visible=false
			proxy.visible=true
			_last={"enabled":false,"rejected":true,"reason":"fixed-length inner reach","direction":direction,"desiredDirection":desired,"contacts":pose,"reachValid":false,"innerReachViolation":{"side":side,"distance":distance,"minimum":absf(limb.x-limb.y),"hipWorld":[hip.x,hip.y,hip.z],"ankleWorld":[ankles[side].x,ankles[side].y,ankles[side].z]},"rootMotion":false}
			return _last.duplicate(true)
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
		var foot_basis:=Basis(_plane(side))*Basis(right,Vector3(0,0,1)/vertical,right.cross(Vector3(0,0,1)).normalized())
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
	_last={"enabled":true,"identity":"male_nusantara","outfit":outfit,"direction":direction,"desiredDirection":desired,"heldFacing":direction!=desired,"contacts":pose,"calibration":1.0/vertical,"supportBodyOffsetPixels":support_body_offset*vertical,"pelvisDropPixels":drop*vertical,"requestedDropPixels":requested_drop*vertical,"reachValid":not unreachable,"maxLengthError":max_length_error,"attachmentOffset":root_hip+up*12-proxy.position,"rootMotion":false,"status":"opt-in lower-body pilot, full natural gait unaccepted"}
	if physical_plane: _last["contactTrace"]=_planner.publish_contact_trace()
	return _last.duplicate(true)
