extends RefCounted

const Traversal=preload("res://scripts/SurfaceTraversal.gd")

static func opaque_vertices(image:Image,column:int,rect:Array) -> PackedVector2Array:
	var unique:Dictionary={}
	for y in range(int(rect[3])):
		for x in range(int(rect[2])):
			if image.get_pixel(column*128+int(rect[0])+x,int(rect[1])+y).a<.5: continue
			for point in [Vector2(x,y),Vector2(x+1,y),Vector2(x+1,y+1),Vector2(x,y+1)]: unique[point]=true
	var vertices:=PackedVector2Array()
	for point in unique: vertices.append(point)
	return vertices

static func ground_below(renderer:Node,logical:Vector2,world:Vector3) -> Dictionary:
	var point:=logical
	for iteration in range(8):
		var ground:Vector3=renderer.ground_point(point)
		var error:=Vector2(world.x-ground.x,world.y-ground.y)
		if error.length()<.005: return {"valid":true,"logical":point,"ground":ground}
		var x:Vector3=renderer.ground_point(point+Vector2(.125,0))-ground
		var y:Vector3=renderer.ground_point(point+Vector2(0,.125))-ground
		var determinant:=x.x*y.y-y.x*x.y
		if absf(determinant)<.000001: break
		point+=Vector2((error.x*y.y-y.x*error.y)/determinant,(x.x*error.y-error.x*x.y)/determinant).limit_length(128.0)*.125
	return {"valid":false}

static func valid_contact(renderer:Node,logical:Vector2,geometry:Dictionary,legal:Callable) -> bool:
	var leg:Dictionary=geometry.leg
	var right:Vector3=geometry.right
	var vertical:float=geometry.vertical
	var rotation:=contact_rotation(renderer,logical,right)
	var sole:=Vector2(float(leg.solePixel[0]),float(leg.solePixel[1]))
	var center:Vector3=renderer.ground_point(logical)
	for pixel in geometry.vertices:
		var offset:=right*(float(pixel.x)-sole.x)+Vector3(0,0,(sole.y-float(pixel.y))/vertical)
		var point:Vector3=center+rotation*offset
		var actual:=ground_below(renderer,logical,point)
		if not bool(actual.valid) or not bool(legal.call(actual.logical)): return false
		var gap:float=point.z-Vector3(actual.ground).z
		if gap<-.02 or (absf(float(pixel.y)-sole.y)<.0001 and absf(gap)>.02): return false
	return not geometry.vertices.is_empty()

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
