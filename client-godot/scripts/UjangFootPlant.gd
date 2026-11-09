extends RefCounted

const STRIDE := 25.0
const LIFT := 3.4
const SOLE_RADIUS := 6.0
var _renderer:Node
var _actor:Node2D
var _floors:Array[PackedVector2Array]=[]
var _obstacles:Array[PackedVector2Array]=[]
var _feet:Dictionary={}
var _last_at:=Vector2.ZERO
var _last_ground:=Vector3.ZERO
var _last_time:=0.0
var _phase_distance:=0.0
var _walking:=false
var _direction:=Vector2.RIGHT
var _ratio:=1.0
var _ready:=false
var _hips:Dictionary={}
var _resets:=0
var _lateral:=Vector2.RIGHT
var _turn:Dictionary={}
var _turn_steps:=0
const TURN_DISTANCE:=6.0

func configure(renderer:Node,actor:Node2D,data:Dictionary) -> bool:
	if not ("map" in renderer) or renderer.map.is_empty(): return false
	_renderer=renderer
	_actor=actor
	for surface in renderer.map.get("surfaces",[]):
		if surface.get("walkable",true): _floors.append(_polygon(surface.polygon))
	for obstacle in renderer.map.get("obstacles",[]): _obstacles.append(_polygon(obstacle.footprint))
	for side in ["left","right"]: _hips[side]=float(data.joints[side+"Hip"][0])
	return true

func _polygon(points:Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point in points: result.append(Vector2(float(point[0]),float(point[1])))
	return result

func _on_land(point:Vector2) -> bool:
	var found:=false
	for polygon in _floors:
		if Geometry2D.is_point_in_polygon(point,polygon): found=true; break
	if not found: return false
	for polygon in _obstacles:
		if Geometry2D.is_point_in_polygon(point,polygon): return false
	return true

func valid_sole(point:Vector2) -> bool:
	for index in range(8):
		if not _on_land(point+Vector2.from_angle(index*TAU/8.0)*SOLE_RADIUS): return false
	return _on_land(point)

func _safe(point:Vector2,origin:Vector2) -> Vector2:
	for step in range(13):
		var candidate:=point.lerp(origin,float(step)/12.0)
		if valid_sole(candidate): return candidate
	return origin

func _height(point:Vector2) -> float:
	var height:float=_renderer.ground_height(point)
	for stair in _renderer.map.get("stairs",[]):
		if str(stair.get("type","stairs"))!="stairs": continue
		var a:=Vector2(float(stair.path[0][0]),float(stair.path[0][1]))
		var b:=Vector2(float(stair.path[1][0]),float(stair.path[1][1]))
		var t:float=(point-a).dot(b-a)/maxf(.001,a.distance_squared_to(b))
		if t<0 or t>=1 or point.distance_to(a.lerp(b,t))>float(stair.width)*.5: continue
		var lower:=0.0
		var upper:=0.0
		for terrace in _renderer.map.get("terraces",[]):
			if terrace.id==stair.from: lower=float(terrace.elevation)*48.0
			if terrace.id==stair.to: upper=float(terrace.elevation)*48.0
		var count:=maxi(1,int(stair.steps))
		height=lerpf(lower,upper,float(mini(count,floori(t*count)+1))/count)
	return height

func _ground(point:Vector2) -> Vector3:
	return _renderer.map_point(point,_height(point))

func _update_lateral(at:Vector2) -> void:
	var camera:Camera3D=_renderer.get("camera_3d")
	if camera==null: return
	var origin:Vector3=_renderer.map_point(at,0)
	var x:Vector3=_renderer.map_point(at+Vector2.RIGHT,0)-origin
	var y:Vector3=_renderer.map_point(at+Vector2.DOWN,0)-origin
	var right:=camera.global_basis.x
	var determinant:=x.x*y.y-y.x*x.y
	if absf(determinant)<.00001: return
	_lateral=Vector2((right.x*y.y-y.x*right.y)/determinant,(x.x*right.y-right.x*x.y)/determinant)

func _base(side:String,at:Vector2) -> Vector2:
	return _safe(at+_lateral*float(_hips[side]),at)

func _up() -> Vector3:
	var camera:Camera3D=_renderer.get("camera_3d")
	return camera.global_basis.y if camera!=null else _renderer.camera_up()

func _begin_swing(entry:Dictionary,phase:float,at:Vector2,side:String,from_stance_boundary:=false) -> void:
	entry.swingFrom=entry.logical
	var remaining:float=(1.0-phase)*STRIDE
	entry.swingTo=_safe(_base(side,at)+_direction*(remaining+STRIDE*.25)/_ratio,at)
	# A regular stance crossing already consumed part of this swing during the
	# accepted movement. Startup and turn handover instead start at this pose.
	entry.startProgress=0.0 if from_stance_boundary else (phase-.5)*2.0
	entry.grounded=false

func _begin_turn(at:Vector2) -> void:
	var side:="right"
	for name in ["left","right"]:
		if not bool(_feet[name].grounded): side=name; break
	var entry:Dictionary=_feet[side]
	var target:=_safe(_base(side,at)+_direction*TURN_DISTANCE/_ratio,at)
	_turn={"side":side,"from":entry.logical,"target":target,"distance":0.0,"lift":maxf(0,(Vector3(entry.sole)-_ground(entry.logical)).dot(_up()))}
	entry.grounded=false
	_turn_steps+=1

func _advance_turn(physical:float,at:Vector2) -> void:
	_turn.distance=float(_turn.distance)+physical
	var u:=clampf(float(_turn.distance)/TURN_DISTANCE,0,1)
	var smooth:=u*u*(3.0-2.0*u)
	var side:String=_turn.side
	var entry:Dictionary=_feet[side]
	entry.logical=_safe(Vector2(_turn.from).lerp(_turn.target,smooth),at)
	entry.sole=_ground(entry.logical)+_up()*(lerpf(float(_turn.lift),0,u)+sin(u*PI)*LIFT)
	if u>=1:
		entry.plant=_ground(entry.logical)
		entry.sole=entry.plant
		entry.grounded=true
		# The arriving foot supports the body before the old support begins its swing.
		_phase_distance=0.0 if side=="left" else STRIDE*.5
		for name in ["left","right"]:
			_feet[name].phase=fposmod(_phase_distance/STRIDE+(.25 if name=="left" else .75),1.0)
		var released:="right" if side=="left" else "left"
		_begin_swing(_feet[released],.75,at,released)
		_turn.clear()

func update(at:Vector2,velocity:Vector2,time:float,_flip:float) -> Dictionary:
	_update_lateral(at)
	var body_ground:Vector3=_renderer.map_point(at,_renderer.ground_height(at))
	var moved:=at.distance_to(_last_at) if _ready else 0.0
	var physical:=body_ground.distance_to(_last_ground) if _ready else 0.0
	var delta:=clampf(time-_last_time,0,.15) if _ready else 0.0
	var walking:=velocity.length()>.1 and moved>.00001
	if moved>50 or physical>STRIDE*.5:
		_resets+=1
		_ready=false
		walking=false
	if not _ready:
		_turn.clear()
		for side in ["left","right"]:
			var point:=_base(side,at)
			_feet[side]={"logical":point,"sole":_ground(point),"plant":_ground(point),"phase":.25 if side=="left" else .75,"grounded":true,"swingFrom":point,"swingTo":point,"startProgress":0.0}
		_phase_distance=0
		_ready=true
	if walking:
		var next_direction:=velocity.normalized()
		var turned:=_walking and _direction.dot(next_direction)<.5
		_direction=next_direction
		_ratio=clampf(physical/maxf(.001,moved),1.0,8.0)
		if turned: _begin_turn(at)
		if not _turn.is_empty():
			_advance_turn(physical,at)
		else:
			if not _walking:
				_phase_distance=0
				_begin_swing(_feet.right,.75,at,"right")
			else: _phase_distance+=physical
			for side in ["left","right"]:
				var entry:Dictionary=_feet[side]
				var phase:=fposmod(_phase_distance/STRIDE+(.25 if side=="left" else .75),1.0)
				if phase<.5:
					if not bool(entry.grounded):
						entry.logical=entry.swingTo
						entry.plant=_ground(entry.logical)
						entry.grounded=true
					entry.sole=entry.plant
				else:
					if bool(entry.grounded): _begin_swing(entry,phase,at,side,true)
					var u:=clampf(((phase-.5)*2.0-float(entry.startProgress))/maxf(.001,1.0-float(entry.startProgress)),0,1)
					var smooth:=u*u*(3.0-2.0*u)
					entry.logical=Vector2(entry.swingFrom).lerp(entry.swingTo,smooth)
					entry.logical=_safe(entry.logical,at)
					entry.sole=_ground(entry.logical)+_up()*sin(u*PI)*LIFT
				entry.phase=phase
	else:
		_turn.clear()
		for entry in _feet.values():
			if not bool(entry.grounded):
				var target:=_ground(entry.logical)
				entry.sole=Vector3(entry.sole).move_toward(target,delta*32.0)
				if Vector3(entry.sole).distance_to(target)<.001:
					entry.plant=target
					entry.grounded=true
	_walking=walking
	_last_at=at
	_last_ground=body_ground
	_last_time=time
	return {"feet":_feet.duplicate(true),"walking":walking,"phaseDistance":_phase_distance,"physicalRatio":_ratio,"stride":STRIDE,"essentialMotion":true,"discontinuityResets":_resets,"anatomicalSidesStable":true,"lateralLogical":[_lateral.x,_lateral.y],"turnStep":not _turn.is_empty(),"turnSteps":_turn_steps}
