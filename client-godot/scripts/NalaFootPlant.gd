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
var _right:=Vector3.RIGHT
var _stairs:Array=[]
var _body_height:=0.0
var _body_rate:=1.0
var _stair_transfer:=false
var _steady_distance:=STEP_DISTANCE
var _landing_lead:=LANDING_LEAD
var _start_distance:=STEP_DISTANCE
var _turn_distance:=STEP_DISTANCE*.5
var _turn_cosine:=.5
var _physical_contract:=false
var _transition_next:=true
const Traversal=preload("res://scripts/SurfaceTraversal.gd")

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
		if str(profile.get("type",""))=="stairs":
			_stairs.append(profile)
			_body_rate=maxf(_body_rate,absf(float(profile.to)-float(profile.from))/float(profile.steps)/_steady_distance*1.5)
	for surface in renderer.map.get("surfaces",[]):
		if bool(surface.get("walkable",true)): _floors.append(_polygon(surface.polygon))
	for obstacle in renderer.map.get("obstacles",[]): _obstacles.append(_polygon(obstacle.footprint))

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
	var extents:Vector2=_support_extents.get(side,Vector2(-5,5))
	for extent in [extents.x,0.0,extents.y]:
		var offset:=_logical_offset(point,_right*float(extent))
		var endpoint:=point+offset
		if not _legal(endpoint): return false
		var actual:=_ground(endpoint)
		# The original opaque heel and toe share the sole's real horizontal tread.
		if absf(actual.z-center.z)>.01 or Vector2(actual.x-center.x,actual.y-center.y).distance_to(Vector2(_right.x,_right.y)*float(extent))>.02: return false
	return true

func _safe(point:Vector2,origin:Vector2,side:String,required_height:float=NAN) -> Vector2:
	var near_connector:=false
	var tangent:=Vector2.ZERO
	for profile in _stairs:
		if not Traversal.connector_ground(profile,point).is_empty() or not Traversal.connector_ground(profile,origin).is_empty():
			if str(profile.get("type",""))=="stairs":
				near_connector=true
				tangent=(Vector2(profile.end)-Vector2(profile.start)).normalized()
				break
	# Preserve the established flat path exactly; only a real stair requires tread-fit search.
	if near_connector:
		if _supported(point,side,required_height): return point
		for step in range(1,41):
			for sign in [1.0,-1.0]:
				var candidate:Vector2=point+tangent*float(step)*.5*float(sign)
				if _supported(candidate,side,required_height): return candidate
	for step in range(13):
		var candidate:=point.lerp(origin,float(step)/12.0)
		var valid:=true
		for offset in [Vector2.ZERO,Vector2(-3,-2),Vector2(3,-2),Vector2(3,2),Vector2(-3,2)]:
			if not _legal(candidate+offset): valid=false; break
		if valid and (not near_connector or _supported(candidate,side,required_height)): return candidate
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
	for profile in _stairs:
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

func _transfer_body(at:Vector2,distance:float,side:String) -> void:
	if not _on_stairs(at):
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

func _begin(side:String,at:Vector2,hips:Dictionary,right:Vector3) -> void:
	_swing=side
	_distance=0.0
	var entry:Dictionary=_feet[side]
	if _physical_contract and _transition_next:
		var heading:=_world_motion(at,_heading).normalized()
		var projection:float=(Vector3(entry.sole)-_ground(at)).dot(heading)
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
	entry.grounded=false

func _reset(at:Vector2,hips:Dictionary,right:Vector3) -> void:
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
	_stair_transfer=_on_stairs(at)
	_ready=true

func update(at:Vector2,moving:bool,paused:bool,hips:Dictionary,right:Vector3,delta:float,support_extents:Dictionary={}) -> Dictionary:
	_support_extents=support_extents
	_right=right
	if not _ready: _reset(at,hips,right)
	if paused: return snapshot()
	var logical_delta:=at-_last_at
	var physical:=_world_motion(_last_at,logical_delta).length()
	var body_advanced:=false
	if logical_delta.length()>80 or physical>80:
		_discontinuities+=1
		_reset(at,hips,right)
		return snapshot()
	if moving and physical>.00001:
		_accepted_distance+=physical
		var next_heading:=logical_delta.normalized()
		if _physical_contract and _swing=="" and _heading.dot(next_heading)<_turn_cosine: _transition_next=true
		if _swing!="" and _heading.dot(next_heading)<_turn_cosine:
			# Re-anchor the airborne path at its actual pose before changing heading.
			_feet[_swing].from=_feet[_swing].logical
			_feet[_swing].fromWorld=_feet[_swing].sole
			_distance=0.0
			_landing_distance=_turn_distance
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
			var target:=_safe(_forward_point(_base(sample,float(entry.lateralOffset),right),_landing_distance-_distance+_landing_lead),sample,_swing,float(entry.landingHeight))
			entry.to=target
			entry.toWorld=_ground(target)
			_transfer_body(sample,chunk,_swing)
			body_advanced=true
			var u:=clampf(_distance/_landing_distance,0,1)
			var advance:=u
			var elevation:=u
			var rise:=Vector3(entry.toWorld).z-Vector3(entry.fromWorld).z
			if absf(rise)>.01:
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
			entry.logical=_stair_path_point(entry.from,target,smooth) if absf(rise)>.01 else Vector2(entry.from).lerp(target,smooth)
			var floor_world:=_ground(entry.logical)
			var world:=Vector3(entry.fromWorld).lerp(entry.toWorld,rise_smooth)
			world.z=maxf(world.z+sin(u*PI)*TOE_CLEARANCE,floor_world.z+.02)
			entry.sole=Vector3(floor_world.x,floor_world.y,world.z)
			if u>=1:
				entry.logical=target
				entry.sole=entry.toWorld
				entry.plant=entry.sole
				entry.grounded=true
				_contact_count+=1
				_next_side="left" if _swing=="right" else "right"
				_landing_distance=_steady_distance
				_swing=""
	elif _swing!="":
		var entry:Dictionary=_feet[_swing]
		var ground:=_ground(entry.logical)
		entry.toWorld=ground
		_transfer_body(at,maxf(0,delta)*24.0,_swing)
		body_advanced=true
		entry.sole=Vector3(entry.sole).move_toward(ground,maxf(0,delta)*24.0)
		if Vector3(entry.sole).distance_to(ground)<.001:
			entry.sole=ground
			entry.plant=ground
			entry.grounded=true
			_contact_count+=1
			_next_side="left" if _swing=="right" else "right"
			_landing_distance=_steady_distance
			_swing=""
	if not moving: _transition_next=true
	if _swing=="" and not _on_stairs(at):
		var ordinary:=_ground(at).z
		if _stair_transfer:
			if not body_advanced and (not moving or physical<.00001): _body_height=move_toward(_body_height,ordinary,maxf(0,delta)*24.0*_body_rate)
			if absf(_body_height-ordinary)<.001: _stair_transfer=false
		else: _body_height=ordinary
	_last_at=at
	return snapshot()

func snapshot() -> Dictionary:
	return {"bodyHeight":_body_height,"bodyTransferRate":_body_rate,"feet":_feet.duplicate(true),"swingSide":_swing,"swingDistance":_distance,"acceptedDistance":_accepted_distance,"stepDistance":_steady_distance,"landingLead":_landing_lead,"physicalContract":_physical_contract,"landingDistance":_landing_distance,"contacts":_contact_count,"discontinuityResets":_discontinuities,"actorRootMotion":false,"legacyFoleyChanged":false}
