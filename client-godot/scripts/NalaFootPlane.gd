extends RefCounted

const Traversal=preload("res://scripts/SurfaceTraversal.gd")

static func contact_rotation(renderer:Node,logical:Vector2,right:Vector3) -> Quaternion:
	for profile in renderer.get("_stair_queries"):
		if str(profile.type)!="ramp" or Traversal.connector_ground(profile,logical).is_empty(): continue
		var start:Vector2=profile.start
		var end:Vector2=profile.end
		var along:=(end-start).normalized()
		var across:=Vector2(-along.y,along.x)
		var midpoint:Vector2=start.lerp(end,.5)
		var center:Vector3=renderer.ground_point(midpoint)
		var x:Vector3=renderer.ground_point(midpoint+across)-center
		var y:Vector3=renderer.ground_point(midpoint+along)-center
		var normal:=x.cross(y).normalized()
		if normal.z<0: normal=-normal
		var support:=right-normal*right.dot(normal)
		if support.length()<.001: return Quaternion.IDENTITY
		return Quaternion(right.normalized(),support.normalized())
	return Quaternion.IDENTITY

static func radius_about_ankle(leg:Dictionary,vertical:float) -> float:
	var rect:Array=leg.parts.foot
	var ankle:=Vector2(float(leg.ankle[0])-float(rect[0]),float(leg.ankle[1])-float(rect[1]))
	var radius:=0.0
	for point in [Vector2.ZERO,Vector2(float(rect[2]),0),Vector2(0,float(rect[3])),Vector2(float(rect[2]),float(rect[3]))]:
		var offset:Vector2=point-ankle
		radius=maxf(radius,Vector2(offset.x,offset.y/vertical).length())
	return maxf(.001,radius)

static func advance(from:Quaternion,to:Quaternion,distance:float,radius:float) -> Quaternion:
	var angle:=from.angle_to(to)
	if angle<.000001: return to
	# R*angle bounds motion of every original quad corner about its opaque ankle.
	return from.slerp(to,minf(1,maxf(0,distance)/(maxf(.001,radius)*angle))).normalized()
