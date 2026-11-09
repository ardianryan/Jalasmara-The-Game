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
const Traversal=preload("res://scripts/SurfaceTraversal.gd")

func configure(owner_renderer: Node) -> void:
	renderer=owner_renderer
	for profile in renderer.get("_stair_queries"):
		if str(profile.get("type",""))=="stairs":
			_stairs.append(profile)
			_body_rate=maxf(_body_rate,absf(float(profile.to)-float(profile.from))/float(profile.steps)/STEP_DISTANCE*1.5)
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

func _base(at:Vector2,hip_x:float,right:Vector3) -> Vector2:
	return at+_logical_offset(at,right*hip_x)

func _on_stairs(at:Vector2) -> bool:
	for profile in _stairs:
		if not Traversal.connector_ground(profile,at).is_empty(): return true
		for entry in _feet.values():
			if not Traversal.connector_ground(profile,entry.logical).is_empty(): return true
	return false

func _transfer_body(at:Vector2,distance:float,side:String) -> void:
	if not _on_stairs(at):
		_body_height=_ground(at).z
		return
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
	entry.from=entry.logical
	entry.to=_safe(_base(at,float(hips[side]),right)+_heading*(STEP_DISTANCE+LANDING_LEAD)/maxf(.001,_world_motion(at,_heading).length()),at,side)
	entry.fromWorld=entry.sole
	entry.toWorld=_ground(entry.to)
	entry.grounded=false

func _reset(at:Vector2,hips:Dictionary,right:Vector3) -> void:
	_feet.clear()
	for side in ["left","right"]:
		var point:=_safe(_base(at,float(hips[side]),right),at,side,_ground(at).z)
		var world:=_ground(point)
		_feet[side]={"logical":point,"sole":world,"plant":world,"grounded":true,"from":point,"to":point}
	_swing=""
	_distance=0.0
	_landing_distance=STEP_DISTANCE
	_last_at=at
	_body_height=_ground(at).z
	_ready=true

func update(at:Vector2,moving:bool,paused:bool,hips:Dictionary,right:Vector3,delta:float,support_extents:Dictionary={}) -> Dictionary:
	_support_extents=support_extents
	_right=right
	if not _ready: _reset(at,hips,right)
	if paused: return snapshot()
	var logical_delta:=at-_last_at
	var physical:=_world_motion(_last_at,logical_delta).length()
	if logical_delta.length()>80 or physical>80:
		_discontinuities+=1
		_reset(at,hips,right)
		return snapshot()
	if moving and physical>.00001:
		_accepted_distance+=physical
		var next_heading:=logical_delta.normalized()
		if _swing!="" and _heading.dot(next_heading)<.5:
			# Re-anchor the airborne path at its actual pose before changing heading.
			_feet[_swing].from=_feet[_swing].logical
			_feet[_swing].fromWorld=_feet[_swing].sole
			_distance=0.0
			_landing_distance=STEP_DISTANCE*.5
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
			# Retarget only the free foot; an already planted sole never follows the torso.
			var target:=_safe(_base(sample,float(hips[_swing]),right)+_heading*(_landing_distance-_distance+LANDING_LEAD)/maxf(.001,_world_motion(sample,_heading).length()),sample,_swing)
			entry.to=target
			entry.toWorld=_ground(target)
			_transfer_body(sample,chunk,_swing)
			var u:=clampf(_distance/_landing_distance,0,1)
			var smooth:=u*u*(3.0-2.0*u)
			entry.logical=Vector2(entry.from).lerp(target,smooth)
			var floor_world:=_ground(entry.logical)
			var world:=Vector3(entry.fromWorld).lerp(entry.toWorld,smooth)
			world.z=maxf(world.z+sin(u*PI)*TOE_CLEARANCE,floor_world.z+sin(u*PI)*TOE_CLEARANCE)
			entry.sole=Vector3(floor_world.x,floor_world.y,world.z)
			if u>=1:
				entry.logical=target
				entry.sole=entry.toWorld
				entry.plant=entry.sole
				entry.grounded=true
				_contact_count+=1
				_next_side="left" if _swing=="right" else "right"
				_landing_distance=STEP_DISTANCE
				_swing=""
	elif _swing!="":
		var entry:Dictionary=_feet[_swing]
		var ground:=_ground(entry.logical)
		entry.toWorld=ground
		_transfer_body(at,maxf(0,delta)*24.0,_swing)
		entry.sole=Vector3(entry.sole).move_toward(ground,maxf(0,delta)*24.0)
		if Vector3(entry.sole).distance_to(ground)<.001:
			entry.sole=ground
			entry.plant=ground
			entry.grounded=true
			_contact_count+=1
			_next_side="left" if _swing=="right" else "right"
			_landing_distance=STEP_DISTANCE
			_swing=""
	if _swing=="" and not _on_stairs(at): _body_height=_ground(at).z
	_last_at=at
	return snapshot()

func snapshot() -> Dictionary:
	return {"bodyHeight":_body_height,"bodyTransferRate":_body_rate,"feet":_feet.duplicate(true),"swingSide":_swing,"swingDistance":_distance,"acceptedDistance":_accepted_distance,"stepDistance":STEP_DISTANCE,"landingDistance":_landing_distance,"contacts":_contact_count,"discontinuityResets":_discontinuities,"actorRootMotion":false,"legacyFoleyChanged":false}
