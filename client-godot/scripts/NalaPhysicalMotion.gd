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

static func gait_contract() -> Dictionary:
	return {"steadyDistance":32.0,"landingLead":16.0,"startDistance":10.0,"turnDistance":20.0,"turnCosine":.8}
