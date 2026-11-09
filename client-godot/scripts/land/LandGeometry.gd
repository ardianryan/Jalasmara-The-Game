extends RefCounted

# Scalar port of packages/shared/src/land.ts, including its strict boundary rule.
# Keep manifest coordinates as Arrays: PackedVector2Array rounds them to float32.
static func distance_to_segment(point: Vector2, a: Array, b: Array) -> float:
	var dx:float=float(b[0])-float(a[0])
	var dy:float=float(b[1])-float(a[1])
	var denominator:float=dx*dx+dy*dy
	if denominator==0.0: denominator=1.0
	var t:float=clampf(((float(point.x)-float(a[0]))*dx+(float(point.y)-float(a[1]))*dy)/denominator,0.0,1.0)
	var x:float=float(point.x)-float(a[0])-t*dx
	var y:float=float(point.y)-float(a[1])-t*dy
	return sqrt(x*x+y*y)

static func point_in_polygon(point: Vector2, polygon: Array) -> bool:
	var inside:=false
	var previous:=polygon.size()-1
	for index in range(polygon.size()):
		var a:Array=polygon[previous]
		var b:Array=polygon[index]
		if distance_to_segment(point,a,b)<1e-7: return true
		if (float(a[1])>float(point.y))!=(float(b[1])>float(point.y)):
			if float(point.x)<(float(b[0])-float(a[0]))*(float(point.y)-float(a[1]))/(float(b[1])-float(a[1]))+float(a[0]):
				inside=not inside
		previous=index
	return inside
