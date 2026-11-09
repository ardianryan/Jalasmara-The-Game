extends RefCounted

# This pilot owns visual soles only. Actor coordinates and legacy step audio are untouched.
const STEP_DISTANCE := 18.0
const TOE_CLEARANCE := 3.0
const LANDING_LEAD := 6.0
var renderer: Node
var _feet: Dictionary = {}
var _last_at := Vector2.ZERO
var _ready := false
var _swing := ""
var _distance := 0.0
var _landing_distance := STEP_DISTANCE
var _heading := Vector2.RIGHT
var _contact_count := 0
var _accepted_distance := 0.0
var _next_side := "right"
var _floors: Array[PackedVector2Array] = []
var _obstacles: Array[PackedVector2Array] = []
var _discontinuities := 0
var _support_extents:Dictionary={}
var _landing_geometry:Dictionary={}
var _landing_cache:Dictionary={}
var _right:=Vector3.RIGHT
var _stairs:Array=[]
var _connectors:Array=[]
var _body_height:=0.0
var _body_rate:=1.0
var _continuous_ground_rate:=1.0
var _stair_transfer:=false
var _steady_distance:=STEP_DISTANCE
var _landing_lead:=LANDING_LEAD
var _start_distance:=STEP_DISTANCE
var _turn_distance:=STEP_DISTANCE*.5
var _turn_cosine:=.5
var _physical_contract:=false
var _transition_next:=true
var _body_facing_transitions:=0
var _raw_contact_events:Array=[]
var _trace_epoch:=0
var _trace_discarded:=0
var _trace_overflow:=0
const Traversal=preload("res://scripts/SurfaceTraversal.gd")
const FootPlane=preload("res://scripts/NalaFootPlane.gd")
const RestartBodyBudget=preload("res://scripts/NalaRestartBodyBudget.gd")
const StairSupportCurve=preload("res://scripts/NalaStairSupportCurve.gd")

func configure(owner_renderer: Node,contract:Dictionary={}) -> void:
	renderer=owner_renderer
	_physical_contract=not contract.is_empty()
	_steady_distance=float(contract.get("steadyDistance",STEP_DISTANCE))
	_landing_lead=float(contract.get("landingLead",LANDING_LEAD))
	_start_distance=float(contract.get("startDistance",STEP_DISTANCE))
	_turn_distance=float(contract.get("turnDistance",STEP_DISTANCE*.5))
	_turn_cosine=float(contract.get("turnCosine",.5))
	_landing_distance=_start_distance
	for profile in renderer.get("_stair_queries"):
		_connectors.append(profile)
		if str(profile.get("type",""))=="stairs":
			_stairs.append(profile)
			_body_rate=maxf(_body_rate,absf(float(profile.to)-float(profile.from))/float(profile.steps)/_steady_distance*1.5)
	for surface in renderer.map.get("surfaces",[]):
		if bool(surface.get("walkable",true)): _floors.append(_polygon(surface.polygon))
	for obstacle in renderer.map.get("obstacles",[]): _obstacles.append(_polygon(obstacle.footprint))

func note_body_facing_transition() -> void:
	if _physical_contract:
		_transition_next=true
		_body_facing_transitions+=1

func request_body_facing_handover() -> void:
	if _physical_contract: _transition_next=true

func begin_contact_frame(previous_pose_valid:bool) -> void:
	if not _raw_contact_events.is_empty() or not previous_pose_valid:
		_trace_discarded+=_raw_contact_events.size()
		_trace_epoch+=1
	_raw_contact_events.clear()
	_trace_overflow=0

func publish_contact_trace(final_pose_valid:bool=true) -> Dictionary:
	if not final_pose_valid:
		_trace_discarded+=_raw_contact_events.size()
		_raw_contact_events.clear()
		_trace_epoch+=1
	var result:Dictionary={"producer":str(get_instance_id()),"epoch":_trace_epoch,"events":_raw_contact_events.duplicate(true),"finalPoseValidated":final_pose_valid,"intermediateContactPosesValidated":false,"validationScope":"final runtime-guard-enabled Lower only; transient contact anatomy and external mesh/triangle checks remain independent","overflow":_trace_overflow,"discardedBeforeValidation":_trace_discarded,"audioWired":false}
	_raw_contact_events.clear()
	return result

func _record_contact(side:String,purpose:String,prior_plant:Vector3,body_at:Vector2,accepted_at:float) -> void:
	if not _physical_contract: return
	if _raw_contact_events.size()>=64:
		_trace_overflow+=1
		return
	var entry:Dictionary=_feet[side]
	var support:Dictionary={"type":"outside_connector","id":"","ordinal":-1}
	for profile in _connectors:
		var actual:=Traversal.connector_ground(profile,entry.logical)
		if not actual.is_empty():
			support={"type":str(profile.type),"id":str(profile.id),"ordinal":int(actual.stepIndex)+1 if str(profile.type)=="stairs" else -1,"height":actual.groundHeight,"progress":actual.progress}
			break
	_raw_contact_events.append({"stage":"raw_planner_transition","producer":str(get_instance_id()),"epoch":_trace_epoch,"sequence":_contact_count,"side":side,"purpose":purpose,"stepInitiation":str(entry.get("stepInitiation","unknown")),"previousPlant":prior_plant,"newPlant":Vector3(entry.plant),"plantDisplacement":prior_plant.distance_to(entry.plant),"logicalPlant":Vector2(entry.logical),"bodyLogical":body_at,"bodyHeight":_body_height,"acceptedDistance":accepted_at,"observedPhysicsFrame":Engine.get_physics_frames(),"observedProcessFrame":Engine.get_process_frames(),"exactContactPhysicsFrameKnown":false,"actualSupport":support,"plannedOrdinal":int(entry.get("treadPlan",{}).get("landingOrdinal",-1)),"sourceFootId":str(_landing_geometry.get(side,{}).get("id","unknown")),"supportedLandingAtTransition":bool(entry.get("landingGeometryValid",false)),"landingValidationScope":"original mask" if _landing_geometry.has(side) else "legacy support extents","contactPoseRendered":false})

func legal_support(point:Vector2) -> bool:
	return _legal(point)

func commit_current_body_support(previous_height:float,target_height:float,distance:float,delta:float) -> Dictionary:
	var allowance:float=(maxf(0,distance) if distance>.00001 else maxf(0,delta)*24.0)*maxf(_body_rate,_continuous_ground_rate)
	_body_height=move_toward(previous_height,target_height,allowance)
	_stair_transfer=true
	return {"previousHeight":previous_height,"targetHeight":target_height,"bodyHeight":_body_height,"allowedDelta":allowance,"distance":distance,"zeroXYSettlement":distance<=.00001}

func _polygon(points:Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point in points: result.append(Vector2(float(point[0]),float(point[1])))
	return result

func _legal(point:Vector2) -> bool:
	var found:=false
	for polygon in _floors:
		if Geometry2D.is_point_in_polygon(point,polygon): found=true; break
	if not found: return false
	for polygon in _obstacles:
		if Geometry2D.is_point_in_polygon(point,polygon): return false
	return true

func _supported(point:Vector2,side:String,required_height:float=NAN) -> bool:
	var center:=_ground(point)
	if not is_nan(required_height) and absf(center.z-required_height)>.01: return false
	if _physical_contract and _landing_geometry.has(side):
		return landing_geometry_supported(point,_landing_geometry[side])
	var extents:Vector2=_support_extents.get(side,Vector2(-5,5))
	for extent in [extents.x,0.0,extents.y]:
		var offset:=_logical_offset(point,_right*float(extent))
		var endpoint:=point+offset
		if not _legal(endpoint): return false
		var actual:=_ground(endpoint)
		# The original opaque heel and toe share the sole's real horizontal tread.
		if absf(actual.z-center.z)>.01 or Vector2(actual.x-center.x,actual.y-center.y).distance_to(Vector2(_right.x,_right.y)*float(extent))>.02: return false
	return true

func landing_geometry_supported(point:Vector2,geometry:Dictionary) -> bool:
	var key:Array=[geometry.id,geometry.right,geometry.vertical,point]
	if not _landing_cache.has(key):
		if _landing_cache.size()>512: _landing_cache.clear()
		_landing_cache[key]=_legal(point) and FootPlane.valid_contact(renderer,point,geometry,Callable(self,"_legal"))
	return bool(_landing_cache[key])

func _safe(point:Vector2,origin:Vector2,side:String,required_height:float=NAN) -> Vector2:
	var near_connector:=false
	var tangent:=Vector2.ZERO
	var height:=required_height
	for profile in (_connectors if _physical_contract else _stairs):
		if not Traversal.connector_ground(profile,point).is_empty() or not Traversal.connector_ground(profile,origin).is_empty():
			if str(profile.get("type",""))=="stairs" or _physical_contract:
				near_connector=true
				if str(profile.type)=="ramp": height=NAN
				tangent=(Vector2(profile.end)-Vector2(profile.start)).normalized()
				break
	# Preserve the established flat path exactly; only a real stair requires tread-fit search.
	if near_connector:
		if _supported(point,side,height): return point
		for step in range(1,41):
			for sign in [1.0,-1.0]:
				var candidate:Vector2=point+tangent*float(step)*.5*float(sign)
				if _supported(candidate,side,height): return candidate
	for step in range(13):
		var candidate:=point.lerp(origin,float(step)/12.0)
		var valid:=true
		for offset in [Vector2.ZERO,Vector2(-3,-2),Vector2(3,-2),Vector2(3,2),Vector2(-3,2)]:
			if not _legal(candidate+offset): valid=false; break
		if valid and (not near_connector or _supported(candidate,side,height)) and (not _physical_contract or not _landing_geometry.has(side) or _supported(candidate,side,height)): return candidate
	return origin

func _ground(at: Vector2) -> Vector3:
	return renderer.ground_point(at)

func _world_motion(at:Vector2,offset:Vector2) -> Vector3:
	var movement:Vector3=_ground(at+offset)-_ground(at)
	movement.z=0
	return movement

func _logical_offset(at:Vector2,world:Vector3) -> Vector2:
	var x:=_world_motion(at,Vector2.RIGHT)
	var y:=_world_motion(at,Vector2.DOWN)
	var determinant:=x.x*y.y-y.x*x.y
	return Vector2((world.x*y.y-y.x*world.y)/determinant,(x.x*world.y-world.x*x.y)/determinant)

func _path_metrics(from:Vector2,to:Vector2) -> Dictionary:
	var delta:=to-from
	var fractions:Array[float]=[0.0,1.0]
	for profile in (_connectors if _physical_contract else _stairs):
		if delta.length_squared()<.000001: break
		var start:Vector2=profile.start
		var end:Vector2=profile.end
		var tangent:=(end-start).normalized()
		var side:=Vector2(-tangent.y,tangent.x)*float(profile.width)
		var corners:Array[Vector2]=[start-side,start+side,end+side,end-side]
		for index in range(4):
			var crossing:Variant=Geometry2D.segment_intersects_segment(from,to,corners[index],corners[(index+1)%4])
			if crossing==null: continue
			var fraction:float=(Vector2(crossing)-from).dot(delta)/delta.length_squared()
			if fraction>.00001 and fraction<.99999: fractions.append(fraction)
	fractions.sort()
	var lengths:Array[float]=[]
	var total:=0.0
	for index in range(fractions.size()-1):
		var first:=_ground(from.lerp(to,fractions[index]))
		var second:=_ground(from.lerp(to,fractions[index+1]))
		var span:=Vector2(second.x-first.x,second.y-first.y).length()
		lengths.append(span)
		total+=span
	return {"fractions":fractions,"lengths":lengths,"total":total}

func _path_distance_point(from:Vector2,to:Vector2,metrics:Dictionary,distance:float) -> Vector2:
	var fractions:Array=metrics.fractions
	var lengths:Array=metrics.lengths
	# The connector and its adjoining floor have different XY scales. Interpolate
	# accepted world arc length so leaving a tread does not accelerate the shoe.
	var remaining:=clampf(distance,0,float(metrics.total))
	for index in range(lengths.size()):
		if remaining<=float(lengths[index]) or index==lengths.size()-1:
			var fraction:=lerpf(float(fractions[index]),float(fractions[index+1]),remaining/maxf(.00001,float(lengths[index])))
			return from.lerp(to,fraction)
		remaining-=float(lengths[index])
	return to

func _stair_path_point(from:Vector2,to:Vector2,progress:float) -> Vector2:
	var metrics:=_path_metrics(from,to)
	return _path_distance_point(from,to,metrics,clampf(progress,0,1)*float(metrics.total))

func _forward_point(at:Vector2,distance:float) -> Vector2:
	var offset:=_heading*distance/maxf(.001,_world_motion(at,_heading).length())
	var target:=at+offset
	var metrics:=_path_metrics(at,target)
	if absf(float(metrics.total)-distance)<.001: return target
	for attempt in range(8):
		if float(metrics.total)>=distance: break
		offset*=2.0
		target=at+offset
		metrics=_path_metrics(at,target)
	return _path_distance_point(at,target,metrics,distance)

func _base(at:Vector2,hip_x:float,right:Vector3) -> Vector2:
	return at+_logical_offset(at,right*hip_x)

func airborne_clear(logical:Vector2,world:Vector3) -> bool:
	var sample:=logical
	for iteration in range(3):
		var ground:=_ground(sample)
		var offset:=world-ground
		offset.z=0
		if offset.length_squared()<.000001: break
		sample+=_logical_offset(sample,offset)
	return world.z>=_ground(sample).z+.02

func _on_stairs(at:Vector2) -> bool:
	for profile in _stairs:
		if not Traversal.connector_ground(profile,at).is_empty(): return true
		for entry in _feet.values():
			if not Traversal.connector_ground(profile,entry.logical).is_empty(): return true
	return false

func _support_transfer_active(at:Vector2) -> bool:
	if _on_stairs(at): return true
	if not _physical_contract: return false
	for profile in _connectors:
		if str(profile.get("type",""))!="ramp": continue
		if not Traversal.connector_ground(profile,at).is_empty(): return true
		for entry in _feet.values():
			if not Traversal.connector_ground(profile,entry.logical).is_empty(): return true
	return false

func _ramp_body_rate(from:Vector2,to:Vector2) -> float:
	if not _physical_contract: return 1.0
	var rate:=1.0
	for profile in _connectors:
		if str(profile.get("type",""))!="ramp": continue
		var start:Vector2=profile.start
		var end:Vector2=profile.end
		var active:=not Traversal.connector_ground(profile,from).is_empty() or not Traversal.connector_ground(profile,to).is_empty()
		var tangent:=(end-start).normalized()
		var side:=Vector2(-tangent.y,tangent.x)*float(profile.width)
		var corners:Array[Vector2]=[start-side,start+side,end+side,end-side]
		if not active:
			for index in range(4):
				if Geometry2D.segment_intersects_segment(from,to,corners[index],corners[(index+1)%4])!=null:
					active=true
					break
		if not active: continue
		var first:=_ground(start)
		var last:=_ground(end)
		var span:=Vector2(last.x-first.x,last.y-first.y).length()
		rate=maxf(rate,absf(last.z-first.z)/maxf(.001,span))
	return rate

func _ramp_landing(from:Vector2,to:Vector2) -> bool:
	for profile in _connectors:
		if str(profile.type)!="ramp": continue
		if not Traversal.connector_ground(profile,from).is_empty() or not Traversal.connector_ground(profile,to).is_empty(): return true
		var start:Vector2=profile.start
		var end:Vector2=profile.end
		var tangent:=(end-start).normalized()
		var side:=Vector2(-tangent.y,tangent.x)*float(profile.width)
		var corners:Array[Vector2]=[start-side,start+side,end+side,end-side]
		for index in range(4):
			if Geometry2D.segment_intersects_segment(from,to,corners[index],corners[(index+1)%4])!=null: return true
	return false

func _transfer_body(at:Vector2,distance:float,side:String) -> void:
	if not _support_transfer_active(at):
		var ordinary:=_ground(at).z
		_body_height=move_toward(_body_height,ordinary,maxf(0,distance)*_body_rate) if _stair_transfer else ordinary
		if absf(_body_height-ordinary)<.001: _stair_transfer=false
		return
	_stair_transfer=true
	var support:String="left" if side=="right" else "right"
	# Rise after the trailing foot releases; descend toward the real lower landing.
	# Toe clearance never raises the body baseline, and a riser never moves actor coordinates.
	var target:=minf(float(_feet[support].plant.z),float(_feet[side].toWorld.z))
	_body_height=move_toward(_body_height,target,maxf(0,distance)*_body_rate)

func _trailing_side(at:Vector2) -> String:
	var world_heading:=_world_motion(at,_heading).normalized()
	var origin:=_ground(at)
	var left:float=(Vector3(_feet.left.sole)-origin).dot(world_heading)
	var right:float=(Vector3(_feet.right.sole)-origin).dot(world_heading)
	if absf(left-right)<.5: return _next_side
	return "left" if left<right else "right"

func _next_tread(side:String,at:Vector2,provisional:Vector2) -> Dictionary:
	if not _physical_contract: return {}
	var support:String="left" if side=="right" else "right"
	for profile in _stairs:
		var start:Vector2=profile.start
		var end:Vector2=profile.end
		var tangent:Vector2=(end-start).normalized()
		var along:=_heading.dot(tangent)
		if absf(along)<.5: continue
		var progress:float=(provisional-start).dot(end-start)/float(profile.lengthSquared)
		var support_progress:float=(Vector2(_feet[support].logical)-start).dot(end-start)/float(profile.lengthSquared)
		if along>0 and (progress<0 or support_progress>1): continue
		if along<0 and (progress>1 or support_progress<0): continue
		var base:=_base(at,float(_feet[side].lateralOffset),_right)
		var across:=Vector2(-tangent.y,tangent.x)
		var lane:float=(base-start).dot(across)
		if absf(lane)>float(profile.width): continue
		var count:=int(profile.steps)
		var riser:float=(float(profile.to)-float(profile.from))/count
		if absf(riser)<.001: continue
		var support_ordinal:=roundi((Vector3(_feet[support].plant).z-float(profile.from))/riser)
		var support_ground:=Traversal.connector_ground(profile,_feet[support].logical)
		var actor_ground:=Traversal.connector_ground(profile,at)
		var support_class:="outside_height_legacy"
		if not support_ground.is_empty():
			support_ordinal=int(support_ground.stepIndex)+1
			support_class="actual_tread"
		var upper_approach:bool=along<0 and actor_ground.is_empty() and support_ground.is_empty() and support_progress>1.0 and bool(_feet[support].grounded) and absf(Vector3(_feet[support].plant).z-float(profile.to))<.003 and absf(_ground(_feet[support].logical).z-Vector3(_feet[support].plant).z)<.003
		if upper_approach:
			support_ordinal=count+1
			support_class="upper_flat_approach"
		var ordinal:=clampi(support_ordinal+(1 if along>0 else -1),0,count+1)
		# The next new contact follows the opposite support, not this foot's old tread.
		var center:Vector2=(end if upper_approach else start.lerp(end,(float(ordinal)-.5)/count))+across*lane
		var height:=lerpf(float(profile.from),float(profile.to),float(clampi(ordinal,0,count))/count)
		var target:=_safe(center,at,side,height)
		if not _supported(target,side,height):
			return {"valid":false,"connectorId":profile.id,"landingOrdinal":ordinal,"landingHeight":height}
		var quarter:Vector2=(end-start)/float(count)*.25
		var midpoint:Vector2=start.lerp(end,.5)+across*lane
		var first:=_ground(midpoint-quarter)
		var second:=_ground(midpoint+quarter)
		var depth:=Vector2(second.x-first.x,second.y-first.y).length()*2.0
		return {"valid":true,"target":target,"connectorId":profile.id,"landingOrdinal":ordinal,"landingHeight":height,"supportOrdinal":support_ordinal,"supportClassification":support_class,"actorOnConnector":not actor_ground.is_empty(),"supportOnConnector":not support_ground.is_empty(),"treadDistance":depth}
	return {}

func _terrain_duration(from:Vector3,to:Vector3,minimum:float,span:float) -> Dictionary:
	var rise:=to.z-from.z
	var duration:=maxf(_start_distance,minimum)
	var bound:=INF
	for attempt in range(257):
		var window:=clampf(absf(rise)/(duration*3.0),.25,.65)
		var delay:=window*.5
		var peak:=0.0
		for index in range(1025):
			var u:=float(index)/1024.0
			var advance:=clampf((u-delay)/(1.0-delay) if rise>0 else u/(1.0-delay),0,1)
			var elevation:=clampf(u/window if rise>0 else (u-(1.0-window))/window,0,1)
			var horizontal:=span*6.0*advance*(1.0-advance)/(1.0-delay)
			var vertical:=rise*6.0*elevation*(1.0-elevation)/window+PI*TOE_CLEARANCE*cos(u*PI)
			peak=maxf(peak,Vector2(horizontal,vertical).length())
		# A global second-derivative bound covers between the sampled derivatives.
		var curvature:=Vector2(6.0*span/pow(1.0-delay,2),6.0*absf(rise)/pow(window,2)+PI*PI*TOE_CLEARANCE).length()
		bound=(peak+curvature/2048.0)/duration
		if bound<=4.9: break
		duration+=.25
	return {"distance":duration,"curveSpeedBound":bound,"curveOnly":true,"valid":bound<=4.9,"fromWorld":from,"toWorld":to,"fixedPathWorldXY":span,"curveType":"stair_clearance"}

func _ramp_duration(from:Vector2,to:Vector2,from_world:Vector3,minimum:float,side:String) -> Dictionary:
	var path:=_path_metrics(from,to)
	var span:float=path.total
	var offset:=from_world.z-_ground(from).z
	var vertical_span:=absf(offset)
	var valid:=true
	var knots:Array=[]
	for fraction in path.fractions:
		var logical:=from.lerp(to,float(fraction))
		knots.append({"logical":logical,"world":_ground(logical)})
	for index in range(knots.size()-1):
		var first:Vector3=knots[index].world
		var second:Vector3=knots[index+1].world
		var length:float=path.lengths[index]
		if length<.00001:
			if absf(second.z-first.z)>.00001: valid=false
			continue
		vertical_span=maxf(vertical_span,absf((second.z-first.z)/length*span-offset))
	# Piecewise ground-height slopes include the real crest, not its endpoint chord.
	var numerator:=1.5*Vector2(span,vertical_span).length()+PI*TOE_CLEARANCE
	var distance:=maxf(maxf(_start_distance,minimum),ceilf(numerator/4.9*4.0)*.25)
	var bound:=numerator/distance
	var support_offset:=0.0
	if not _landing_geometry.has(side): valid=false
	else:
		var geometry:Dictionary=_landing_geometry[side]
		var plane:Quaternion=geometry.plane
		var actual_ankle:=from_world+Vector3(geometry.pivot)+FootPlane.ankle_offset(geometry,plane)
		var support:=FootPlane.ankle_support(renderer,from,geometry,actual_ankle,plane)
		if bool(support.valid): support_offset=actual_ankle.z-float(support.height)
		else: valid=false
	return {"distance":distance,"curveSpeedBound":bound,"curveOnly":true,"valid":valid and bound<=4.9,"fromWorld":from_world,"toWorld":_ground(to),"fixedPathWorldXY":span,"curveType":"ramp_support_profile","fromGroundOffset":offset,"groundKnots":knots,"effectiveVerticalSpan":vertical_span,"fromSupportOffset":support_offset,"originalFootSupportEnvelope":true,"envelopeIncludedInBaseCurveBound":false}

func commit_raw_support(side:String,world:Vector3,support_offset:float=NAN) -> void:
	if _physical_contract and _feet.has(side) and not bool(_feet[side].grounded) and bool(_feet[side].get("fixedRampTarget",false)):
		_feet[side].sole=world
		if not is_nan(support_offset): _feet[side].rampCurvePlan.fromSupportOffset=support_offset

func _begin(side:String,at:Vector2,hips:Dictionary,right:Vector3,resuming:bool=false) -> void:
	_swing=side
	_distance=0.0
	var entry:Dictionary=_feet[side]
	entry["stepInitiation"]="resume_unfinished_settlement" if resuming else ("requested_short_handover" if _physical_contract and _transition_next else "steady_walk")
	if _physical_contract and _transition_next:
		var heading:=_world_motion(at,_heading).normalized()
		var target_base:=_base(at,float(hips[side]),right)
		var projection:float=(Vector3(entry.sole)-_ground(target_base)).dot(heading)
		# A cubic trajectory peaks at 1.5 times average speed. Reserve one of the
		# existing five-world continuity units for changing the lateral foot lane.
		_landing_distance=maxf(_start_distance,ceilf(1.5*(_landing_lead-projection)/2.5))
	_transition_next=false
	entry.from=entry.logical
	entry.lateralOffset=float(hips[side])
	entry.to=_safe(_forward_point(_base(at,float(hips[side]),right),_landing_distance+_landing_lead),at,side)
	entry.fromWorld=entry.sole
	entry.toWorld=_ground(entry.to)
	entry.landingHeight=Vector3(entry.toWorld).z
	entry.fixedTreadTarget=false
	entry.fixedRampTarget=false
	entry.erase("treadPlan")
	entry.erase("rampCurvePlan")
	var tread:=_next_tread(side,at,entry.to)
	if not tread.is_empty():
		entry.treadPlan=tread.duplicate(true)
		if bool(tread.valid):
			entry.to=tread.target
			entry.toWorld=_ground(entry.to)
			entry.landingHeight=float(tread.landingHeight)
			entry.fixedTreadTarget=true
			var path:=_path_metrics(entry.from,entry.to)
			var minimum:=_start_distance if resuming else float(tread.treadDistance)
			var swept:Dictionary={"supported":false,"reason":"unfinished resume retains its actual remaining legacy curve"}
			if not resuming and _landing_geometry.has(side):
				for profile in _stairs:
					if str(profile.id)==str(tread.connectorId): swept=StairSupportCurve.build(renderer,profile,entry.from,entry.to,entry.fromWorld,entry.toWorld,_landing_geometry[side],_start_distance)
			var budget:Dictionary=swept if bool(swept.supported) else _terrain_duration(entry.fromWorld,entry.toWorld,minimum,float(path.total))
			budget["sweptSupportMode"]={"supported":swept.supported,"reason":str(swept.get("reason","original per-riser path"))}
			budget["fixedPathWorldXY"]=float(path.total)
			_landing_distance=float(budget.distance)
			entry.treadPlan.merge(budget,true)
	elif _physical_contract and _ramp_landing(entry.from,entry.to):
		var budget:=_ramp_duration(entry.from,entry.to,entry.fromWorld,_landing_distance,side)
		if resuming and bool(budget.valid) and Vector3(budget.groundKnots[0].world).z>Vector3(entry.toWorld).z+.01:
			var direction:=_world_motion(at,_heading).normalized()
			var preview:=RestartBodyBudget.propose(renderer,budget,side,_feet,_landing_geometry,at,direction,_body_height,maxf(_body_rate,_continuous_ground_rate))
			budget["bodyDurationPreview"]=preview
			if bool(preview.valid):
				budget.curveSpeedBound=float(budget.curveSpeedBound)*float(budget.distance)/float(preview.distance)
				budget.distance=preview.distance
			else: budget.valid=false
		_landing_distance=float(budget.distance)
		entry.fixedRampTarget=true
		entry["rampCurvePlan"]=budget
	entry["landingGeometryValid"]=not _physical_contract or not _landing_geometry.has(side) or _supported(entry.to,side)
	entry.erase("settlingTarget")
	entry.grounded=false

func _reset(at:Vector2,hips:Dictionary,right:Vector3) -> void:
	_trace_discarded+=_raw_contact_events.size()
	_raw_contact_events.clear()
	_trace_epoch+=1
	_feet.clear()
	for side in ["left","right"]:
		var point:=_safe(_base(at,float(hips[side]),right),at,side,_ground(at).z)
		var world:=_ground(point)
		_feet[side]={"logical":point,"sole":world,"plant":world,"grounded":true,"from":point,"to":point}
	_swing=""
	_distance=0.0
	_landing_distance=_start_distance
	_transition_next=true
	_last_at=at
	_body_height=_ground(at).z
	_stair_transfer=_support_transfer_active(at)
	_ready=true

func update(at:Vector2,moving:bool,paused:bool,hips:Dictionary,right:Vector3,delta:float,support_extents:Dictionary={},landing_geometry:Dictionary={},settlement_ready:bool=true) -> Dictionary:
	_support_extents=support_extents
	_landing_geometry=landing_geometry
	_right=right
	if not _ready: _reset(at,hips,right)
	if paused: return snapshot()
	_continuous_ground_rate=_ramp_body_rate(_last_at,at)
	var logical_delta:=at-_last_at
	var physical:=_world_motion(_last_at,logical_delta).length()
	var body_advanced:=false
	if logical_delta.length()>80 or physical>80:
		_discontinuities+=1
		_reset(at,hips,right)
		return snapshot()
	var accepted_moving:=moving or (_physical_contract and physical>.00001)
	if accepted_moving and physical>.00001:
		_accepted_distance+=physical
		var next_heading:=logical_delta.normalized()
		var resuming:bool=_physical_contract and _swing!="" and _feet[_swing].has("settlingTarget")
		if resuming:
			var entry:Dictionary=_feet[_swing]
			var actual:=FootPlane.ground_below(renderer,entry.logical,entry.sole)
			if bool(actual.valid): entry.logical=actual.logical
			_heading=next_heading
			_transition_next=true
			_begin(_swing,_last_at,hips,right,true)
		elif _physical_contract and _swing=="" and _heading.dot(next_heading)<_turn_cosine: _transition_next=true
		if not resuming and _swing!="" and _heading.dot(next_heading)<_turn_cosine:
			# Re-anchor the airborne path at its actual pose before changing heading.
			_feet[_swing].from=_feet[_swing].logical
			_feet[_swing].fromWorld=_feet[_swing].sole
			_distance=0.0
			_landing_distance=_turn_distance
			var entry:Dictionary=_feet[_swing]
			entry["stepInitiation"]="heading_turn_reanchor"
			if _physical_contract and (bool(entry.get("fixedTreadTarget",false)) or bool(entry.get("fixedRampTarget",false))):
				var path:=_path_metrics(entry.from,entry.to)
				var budget:Dictionary=_ramp_duration(entry.from,entry.to,entry.fromWorld,_turn_distance,_swing) if bool(entry.get("fixedRampTarget",false)) else _terrain_duration(entry.fromWorld,entry.toWorld,_turn_distance,float(path.total))
				_landing_distance=float(budget.distance)
				if bool(entry.get("fixedTreadTarget",false)):
					entry.treadPlan.merge(budget,true)
					entry.treadPlan["sweptSupportMode"]={"supported":false,"reason":"sharp turn reanchors to labelled legacy terrain curve"}
				else: entry.rampCurvePlan=budget
		elif not resuming and _physical_contract and _swing!="":
			var old_world:=_world_motion(at,_heading)
			var requested_world:=_world_motion(at,next_heading)
			var prior:=Vector2(old_world.x,old_world.y).normalized()
			var requested:=Vector2(requested_world.x,requested_world.y).normalized()
			var lever:=maxf(1.0,_landing_distance-_distance+_landing_lead)
			# Tiny accepted float deltas must not swing a distant landing target.
			var angle:=clampf(prior.angle_to(requested),-physical/lever,physical/lever)
			var limited:=prior.rotated(angle)
			next_heading=_logical_offset(at,Vector3(limited.x,limited.y,0.0)).normalized()
		_heading=next_heading
		var origin:=_last_at
		var consumed:=0.0
		while consumed<physical-.00001:
			if _swing=="":
				var begin_at:=origin.lerp(at,consumed/physical)
				_begin(_trailing_side(begin_at),begin_at,hips,right)
			var chunk:=minf(2.0,minf(physical-consumed,_landing_distance-_distance))
			consumed+=chunk
			var sample:=origin.lerp(at,consumed/physical)
			_distance+=chunk
			var entry:Dictionary=_feet[_swing]
			entry.lateralOffset=move_toward(float(entry.lateralOffset),float(hips[_swing]),chunk)
			# Retarget only the free foot; an already planted sole never follows the torso.
			var target:Vector2=entry.to if bool(entry.get("fixedTreadTarget",false)) or bool(entry.get("fixedRampTarget",false)) else _safe(_forward_point(_base(sample,float(entry.lateralOffset),right),_landing_distance-_distance+_landing_lead),sample,_swing,float(entry.landingHeight))
			entry.to=target
			entry.toWorld=_ground(target)
			entry["landingGeometryValid"]=not _physical_contract or not _landing_geometry.has(_swing) or _supported(target,_swing)
			_transfer_body(sample,chunk,_swing)
			body_advanced=true
			var u:=clampf(_distance/_landing_distance,0,1)
			if bool(entry.get("fixedTreadTarget",false)) and str(entry.treadPlan.get("curveType",""))=="stair_swept_support":
				var swept:=StairSupportCurve.sample(renderer,entry.treadPlan,u)
				if not bool(swept.valid):
					entry.treadPlan.valid=false
					entry.landingGeometryValid=false
					return snapshot()
				entry.logical=swept.logical
				var point:Vector3=swept.world
				point.z=maxf(point.z+sin(u*PI)*TOE_CLEARANCE,_ground(entry.logical).z+.02)
				entry.sole=point
			else:
				var advance:=u
				var elevation:=u
				var rise:=Vector3(entry.toWorld).z-Vector3(entry.fromWorld).z
				if absf(rise)>.01 and not bool(entry.get("fixedRampTarget",false)):
					var window:=clampf(absf(rise)/(_landing_distance*3.0),.25,.65)
					var delay:=window*.5
					if rise>0:
						advance=clampf((u-delay)/(1.0-delay),0,1)
						elevation=clampf(u/window,0,1)
					else:
						advance=clampf(u/(1.0-delay),0,1)
						elevation=clampf((u-(1.0-window))/window,0,1)
				var smooth:=advance*advance*(3.0-2.0*advance)
				var rise_smooth:=elevation*elevation*(3.0-2.0*elevation)
				entry.logical=_stair_path_point(entry.from,target,smooth) if absf(rise)>.01 or bool(entry.get("fixedRampTarget",false)) else Vector2(entry.from).lerp(target,smooth)
				var floor_world:=_ground(entry.logical)
				var world:=Vector3(entry.fromWorld).lerp(entry.toWorld,rise_smooth)
				if bool(entry.get("fixedRampTarget",false)):
					world.z=floor_world.z+float(entry.rampCurvePlan.fromGroundOffset)*(1.0-smooth)+sin(u*PI)*TOE_CLEARANCE
				else: world.z=maxf(world.z+sin(u*PI)*TOE_CLEARANCE,floor_world.z+.02)
				entry.sole=Vector3(floor_world.x,floor_world.y,world.z)
			if u>=1:
				var prior_plant:Vector3=entry.plant
				entry.logical=target
				entry.sole=entry.toWorld
				entry.plant=entry.sole
				entry.grounded=true
				_contact_count+=1
				_record_contact(_swing,"walking",prior_plant,sample,_accepted_distance-physical+consumed)
				_next_side="left" if _swing=="right" else "right"
				_landing_distance=_steady_distance
				_swing=""
	elif _swing!="":
		var entry:Dictionary=_feet[_swing]
		if _physical_contract and not entry.has("settlingTarget"):
			entry["settlingTarget"]=_safe(entry.logical,at,_swing)
			entry.to=entry.settlingTarget
			entry["landingGeometryValid"]=not _landing_geometry.has(_swing) or _supported(entry.to,_swing)
		var ground:=_ground(entry.get("settlingTarget",entry.logical))
		entry.toWorld=ground
		_transfer_body(at,maxf(0,delta)*24.0,_swing)
		body_advanced=true
		entry.sole=Vector3(entry.sole).move_toward(ground,maxf(0,delta)*24.0)
		if Vector3(entry.sole).distance_to(ground)<.001 and settlement_ready:
			var prior_plant:Vector3=entry.plant
			entry.logical=entry.get("settlingTarget",entry.logical)
			entry.sole=ground
			entry.plant=ground
			entry.grounded=true
			_contact_count+=1
			_record_contact(_swing,"settling",prior_plant,at,_accepted_distance)
			_next_side="left" if _swing=="right" else "right"
			_landing_distance=_steady_distance
			_swing=""
	if not accepted_moving: _transition_next=true
	if _swing=="" and not _support_transfer_active(at):
		var ordinary:=_ground(at).z
		if _stair_transfer:
			if not body_advanced and (not moving or physical<.00001): _body_height=move_toward(_body_height,ordinary,maxf(0,delta)*24.0*_body_rate)
			if absf(_body_height-ordinary)<.001: _stair_transfer=false
		else: _body_height=ordinary
	_last_at=at
	return snapshot()

func snapshot() -> Dictionary:
	return {"actorLogical":_last_at,"bodyHeight":_body_height,"bodyTransferRate":maxf(_body_rate,_continuous_ground_rate),"continuousGroundRate":_continuous_ground_rate,"feet":_feet.duplicate(true),"swingSide":_swing,"swingDistance":_distance,"acceptedDistance":_accepted_distance,"stepDistance":_steady_distance,"landingLead":_landing_lead,"physicalContract":_physical_contract,"bodyFacingTransitions":_body_facing_transitions,"shortHandoverPending":_transition_next,"landingDistance":_landing_distance,"contacts":_contact_count,"discontinuityResets":_discontinuities,"rawContactEvents":_raw_contact_events.duplicate(true),"rawTraceEpoch":_trace_epoch,"rawTraceOverflow":_trace_overflow,"actorRootMotion":false,"legacyFoleyChanged":false}
