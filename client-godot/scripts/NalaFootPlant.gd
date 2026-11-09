extends RefCounted

# This pilot owns visual soles only. Actor coordinates and legacy step audio are untouched.
const STEP_DISTANCE := 24.0
const TOE_CLEARANCE := 2.0
var renderer: Node
var _feet: Dictionary = {}
var _last_at := Vector2.ZERO
var _ready := false
var _swing := ""
var _distance := 0.0
var _heading := Vector2.RIGHT
var _contact_count := 0
var _next_side := "right"
var _floors: Array[PackedVector2Array] = []
var _obstacles: Array[PackedVector2Array] = []
var _discontinuities := 0

func configure(owner_renderer: Node) -> void:
	renderer=owner_renderer
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

func _safe(point:Vector2,origin:Vector2) -> Vector2:
	for step in range(13):
		var candidate:=point.lerp(origin,float(step)/12.0)
		var valid:=true
		for offset in [Vector2.ZERO,Vector2(-3,-2),Vector2(3,-2),Vector2(3,2),Vector2(-3,2)]:
			if not _legal(candidate+offset): valid=false; break
		if valid: return candidate
	return origin

func _ground(at: Vector2) -> Vector3:
	return renderer.ground_point(at)

func _world_motion(at:Vector2,offset:Vector2) -> Vector3:
	return renderer.map_point(at+offset,0)-renderer.map_point(at,0)

func _logical_offset(at:Vector2,world:Vector3) -> Vector2:
	var x:=_world_motion(at,Vector2.RIGHT)
	var y:=_world_motion(at,Vector2.DOWN)
	var determinant:=x.x*y.y-y.x*x.y
	return Vector2((world.x*y.y-y.x*world.y)/determinant,(x.x*world.y-world.x*x.y)/determinant)

func _base(at:Vector2,hip_x:float,right:Vector3) -> Vector2:
	return at+_logical_offset(at,right*hip_x)

func _begin(side:String,at:Vector2,hips:Dictionary,right:Vector3) -> void:
	_swing=side
	_distance=0.0
	var entry:Dictionary=_feet[side]
	entry.from=entry.logical
	entry.to=_safe(_base(at,float(hips[side]),right)+_heading*STEP_DISTANCE/maxf(.001,_world_motion(at,_heading).length()),at)
	entry.fromWorld=entry.sole
	entry.toWorld=_ground(entry.to)
	entry.grounded=false

func _reset(at:Vector2,hips:Dictionary,right:Vector3) -> void:
	_feet.clear()
	for side in ["left","right"]:
		var point:=_base(at,float(hips[side]),right)
		var world:=_ground(point)
		_feet[side]={"logical":point,"sole":world,"plant":world,"grounded":true,"from":point,"to":point}
	_swing=""
	_distance=0.0
	_last_at=at
	_ready=true

func update(at:Vector2,moving:bool,paused:bool,hips:Dictionary,right:Vector3,delta:float) -> Dictionary:
	if not _ready: _reset(at,hips,right)
	if paused: return snapshot()
	var logical_delta:=at-_last_at
	var physical:=_world_motion(_last_at,logical_delta).length()
	if logical_delta.length()>80:
		_discontinuities+=1
		_reset(at,hips,right)
		return snapshot()
	if moving and physical>.00001:
		_heading=logical_delta.normalized()
		var origin:=_last_at
		var consumed:=0.0
		while consumed<physical-.00001:
			if _swing=="": _begin(_next_side,origin.lerp(at,consumed/physical),hips,right)
			var chunk:=minf(2.0,minf(physical-consumed,STEP_DISTANCE-_distance))
			consumed+=chunk
			var sample:=origin.lerp(at,consumed/physical)
			_distance+=chunk
			var entry:Dictionary=_feet[_swing]
			# Retarget only the free foot; an already planted sole never follows the torso.
			var target:=_safe(_base(sample,float(hips[_swing]),right)+_heading*(STEP_DISTANCE-_distance)/maxf(.001,_world_motion(sample,_heading).length()),sample)
			entry.to=target
			entry.toWorld=_ground(target)
			var u:=clampf(_distance/STEP_DISTANCE,0,1)
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
				_swing=""
	elif _swing!="":
		var entry:Dictionary=_feet[_swing]
		var ground:=_ground(entry.logical)
		entry.sole=Vector3(entry.sole).move_toward(ground,maxf(0,delta)*24.0)
		if Vector3(entry.sole).distance_to(ground)<.001:
			entry.sole=ground
			entry.plant=ground
			entry.grounded=true
			_contact_count+=1
			_next_side="left" if _swing=="right" else "right"
			_swing=""
	_last_at=at
	return snapshot()

func snapshot() -> Dictionary:
	return {"feet":_feet.duplicate(true),"swingSide":_swing,"swingDistance":_distance,"stepDistance":STEP_DISTANCE,"contacts":_contact_count,"discontinuityResets":_discontinuities,"actorRootMotion":false,"legacyFoleyChanged":false}
