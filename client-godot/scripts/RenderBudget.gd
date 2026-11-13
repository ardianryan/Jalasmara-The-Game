extends RefCounted

const PIXEL_BUDGET := 129600
const BALANCED_PIXEL_BUDGET := 230400

static func viewport_size(logical_size: Vector2, budget := PIXEL_BUDGET) -> Vector2i:
	var ratio:=2.0/3.0 if budget>PIXEL_BUDGET else .5
	var target:=Vector2(maxf(2,logical_size.x*ratio),maxf(2,logical_size.y*ratio))
	var scale_factor:=minf(1,sqrt(float(maxi(4,budget))/maxf(1,target.x*target.y)))
	return Vector2i(maxi(2,floori(target.x*scale_factor)),maxi(2,floori(target.y*scale_factor)))

static func quality_budget(quality: String) -> int:
	return BALANCED_PIXEL_BUDGET if quality=="balanced" else PIXEL_BUDGET
