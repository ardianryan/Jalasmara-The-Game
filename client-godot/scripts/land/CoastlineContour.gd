extends RefCounted

const STEP := 34.0
const MAX_RELIEF := 12.0

static func naturalize(points: PackedVector2Array, outward_only := false, anchors: PackedVector2Array = PackedVector2Array()) -> PackedVector2Array:
	if points.size()<3: return points
	var result:=PackedVector2Array()
	var signed_area:=0.0
	for index in range(points.size()): signed_area+=points[index].cross(points[(index+1)%points.size()])
	for index in range(points.size()):
		var previous:=points[(index+points.size()-1)%points.size()]
		var start:=points[index]
		var end:=points[(index+1)%points.size()]
		var following:=points[(index+2)%points.size()]
		var edge:=end-start
		var count:=maxi(2,ceili(edge.length()/STEP))
		var normal:=Vector2(-edge.y,edge.x).normalized()
		for part in range(count):
			var t:=float(part)/count
			var linear:=start.lerp(end,t)
			var curve:=.5*((2.0*start)+(-previous+end)*t+(2.0*previous-5.0*start+4.0*end-following)*t*t+(-previous+3.0*start-3.0*end+following)*t*t*t)
			var bend: Vector2=(curve-linear)*.28
			if bend.length()>MAX_RELIEF: bend=bend.normalized()*MAX_RELIEF
			var rhythm:=sin(t*PI)*(.64*sin(t*TAU*1.7+index*2.41)+.36*sin(t*TAU*3.1-index*.83))
			var displacement: Vector2=bend+normal*rhythm*MAX_RELIEF*.64
			if outward_only:
				var outward:=normal*(-1.0 if signed_area>0.0 else 1.0)
				var extension:=maxf(0.0,displacement.dot(outward)+sin(t*PI)*4.0)
				for anchor in anchors:
					extension*=smoothstep(80.0,150.0,linear.distance_to(anchor))
				displacement=outward*minf(MAX_RELIEF,extension)
			result.append(linear+displacement)
	return result
