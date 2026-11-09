extends RefCounted

const PIXEL_BUDGET := 129600

static func viewport_size(logical_size: Vector2, budget := PIXEL_BUDGET) -> Vector2i:
	var target:=Vector2(maxf(2,logical_size.x*.5),maxf(2,logical_size.y*.5))
	var scale_factor:=minf(1,sqrt(float(maxi(4,budget))/maxf(1,target.x*target.y)))
	return Vector2i(maxi(2,floori(target.x*scale_factor)),maxi(2,floori(target.y*scale_factor)))
