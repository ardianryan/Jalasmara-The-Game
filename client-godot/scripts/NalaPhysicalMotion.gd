extends RefCounted

const WORLD_XY_SPEED:=100.0
const LOGICAL_CAP:=100.0

static func _bounded(input:Vector2) -> Vector2:
	return input.limit_length()

static func screen_scale(renderer:Node,input:Vector2,at:Vector2) -> float:
	var bounded:=_bounded(input)
	if bounded.is_zero_approx(): return 0.0
	var gradient:Vector2=renderer.ground_gradient(at)
	var logical:Vector2=renderer.view_projection.input_motion(bounded,gradient)
	var tilt:float=renderer.TILT
	# Continuous connector tangent only; discrete riser Z never advances cadence.
	var world_xy:=Vector2(logical.x,-logical.y/cos(tilt)-tan(tilt)*gradient.dot(logical))
	var desired:=bounded.length()*WORLD_XY_SPEED/float(LOGICAL_CAP)
	return minf(1.0,desired/maxf(.000001,world_xy.length()))

static func screen_input(renderer:Node,input:Vector2,at:Vector2) -> Vector2:
	return _bounded(input)*screen_scale(renderer,input,at)

static func logical_input(renderer:Node,input:Vector2,at:Vector2) -> Vector2:
	var logical:Vector2=renderer.view_projection.input_motion(_bounded(input),renderer.ground_gradient(at))
	return logical*screen_scale(renderer,input,at)

static func _segment_cuts(renderer:Node,from:Vector2,to:Vector2) -> Array[float]:
	var cuts:Array[float]=[0.0,1.0]
	var motion:=to-from
	for profile in renderer.get("_stair_queries"):
		var start:Vector2=profile.start
		var along:Vector2=Vector2(profile.end)-start
		var length:=along.length()
		var axis:=along/maxf(.000001,length)
		var normal:=Vector2(-axis.y,axis.x)
		var relative:=from-start
		var coordinates:=Vector2(relative.dot(axis),relative.dot(normal))
		var change:=Vector2(motion.dot(axis),motion.dot(normal))
		var low:=Vector2(0.0,-float(profile.width))
		var high:=Vector2(length,float(profile.width))
		var enter:=0.0
		var leave:=1.0
		var intersects:=true
		for dimension in range(2):
			if absf(change[dimension])<.0000001:
				if coordinates[dimension]<low[dimension] or coordinates[dimension]>high[dimension]: intersects=false
			else:
				var a:float=(low[dimension]-coordinates[dimension])/change[dimension]
				var b:float=(high[dimension]-coordinates[dimension])/change[dimension]
				enter=maxf(enter,minf(a,b))
				leave=minf(leave,maxf(a,b))
		if intersects and enter<=leave:
			if enter>0.0 and enter<1.0: cuts.append(enter)
			if leave>0.0 and leave<1.0: cuts.append(leave)
	cuts.sort()
	return cuts

static func limit_velocity(renderer:Node,at:Vector2,velocity:Vector2,delta:float) -> Vector2:
	var bounded:=velocity.limit_length(LOGICAL_CAP)
	if delta<=0.0 or bounded.is_zero_approx(): return Vector2.ZERO
	var target:=at+bounded*delta
	var cuts:=_segment_cuts(renderer,at,target)
	var remaining:=WORLD_XY_SPEED*delta
	var motion:=target-at
	for index in range(1,cuts.size()):
		var start_fraction:=cuts[index-1]
		var end_fraction:=cuts[index]
		var span:=end_fraction-start_fraction
		if span<.00000001: continue
		var probe:=minf(.001/maxf(.001,motion.length()),span*.25)
		var before:Vector3=renderer.ground_point(at.lerp(target,start_fraction))
		var after:Vector3=renderer.ground_point(at.lerp(target,end_fraction))
		var inside_before:Vector3=renderer.ground_point(at.lerp(target,start_fraction+probe))
		var inside_after:Vector3=renderer.ground_point(at.lerp(target,end_fraction-probe))
		var interior:=Vector2(inside_after.x-inside_before.x,inside_after.y-inside_before.y)
		var extension:=interior*(probe/maxf(.000000001,span-2.0*probe))
		var expected_before:=Vector2(inside_before.x,inside_before.y)-extension
		var expected_after:=Vector2(inside_after.x,inside_after.y)+extension
		# Inclusive connector sides can switch to a different XY embedding.
		# Never interpolate a fraction of that physical jump into an outside point.
		if expected_before.distance_to(Vector2(before.x,before.y))>.003:
			return bounded*start_fraction
		var discontinuous_end:=expected_after.distance_to(Vector2(after.x,after.y))>.003
		if discontinuous_end:
			end_fraction-=probe
			after=inside_after
		# Continuous tread XY only; discrete riser Z never consumes cadence.
		var length:=Vector2(after.x-before.x,after.y-before.y).length()
		if length>remaining and length>.0000001:
			var fraction:=lerpf(start_fraction,end_fraction,remaining/length)
			return bounded*clampf(fraction,0.0,1.0)
		remaining=maxf(0.0,remaining-length)
		if discontinuous_end: return bounded*end_fraction

	return bounded

static func limit_position(renderer:Node,from:Vector2,to:Vector2,delta:float) -> Vector2:
	if delta<=0.0: return from
	return from+limit_velocity(renderer,from,(to-from)/delta,delta)*delta

static func gait_contract() -> Dictionary:
	return {"steadyDistance":32.0,"landingLead":16.0,"startDistance":10.0,"turnDistance":20.0,"turnCosine":.8}
