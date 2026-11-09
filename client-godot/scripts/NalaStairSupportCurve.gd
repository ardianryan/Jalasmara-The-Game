extends RefCounted

const FootPlane=preload("res://scripts/NalaFootPlane.gd")

static func build(renderer:Node,profile:Dictionary,from:Vector2,to:Vector2,from_world:Vector3,to_world:Vector3,geometry:Dictionary,minimum:float) -> Dictionary:
	var unsupported:Dictionary={"supported":false,"reason":"requires fresh ascending original foot on a flat sole plane"}
	var plane:Quaternion=geometry.plane
	var right:Vector3=geometry.right
	if not is_finite(float(geometry.vertical)) or not right.is_finite() or not Vector3(geometry.pivot).is_finite() or absf(right.length()-1.0)>.001 or not plane.is_finite(): return {"supported":false,"reason":"invalid source basis"}
	if not is_finite(float(profile.from)) or not is_finite(float(profile.to)) or float(profile.to)<=float(profile.from): return {"supported":false,"reason":"requires canonical ascending profile"}
	if plane.angle_to(Quaternion.IDENTITY)>.0001 or Vector3(geometry.pivot).length()>.0001 or absf(right.z)>.0001: return unsupported
	if not from_world.is_finite() or not to_world.is_finite() or float(geometry.vertical)<=0 or to_world.z<=from_world.z+.01: return unsupported
	var start:Vector2=profile.start
	var end:Vector2=profile.end
	var world_start:Vector3=renderer.ground_point(start)
	var world_end:Vector3=renderer.ground_point(end)
	var across:=Vector2(-(end-start).y,(end-start).x).normalized()
	var middle:=start.lerp(end,.5)
	var center:Vector3=renderer.ground_point(middle)
	var cross_world:Vector3=renderer.ground_point(middle+across)-center
	var normal:=Vector2(-cross_world.y,cross_world.x).normalized()
	if normal.dot(Vector2(world_end.x-world_start.x,world_end.y-world_start.y))<0: normal=-normal
	var delta:=Vector2(to_world.x-from_world.x,to_world.y-from_world.y)
	var span:=delta.length()
	if span<.00001 or not is_finite(span) or normal.length_squared()<.99: return {"supported":false,"reason":"degenerate physical riser plane"}
	var tangent:=delta/span
	var along:=normal.dot(tangent)
	if along<=.00001: return {"supported":false,"reason":"descending or transverse riser path"}
	var leg:Dictionary=geometry.leg
	var sole:=Vector2(float(leg.solePixel[0]),float(leg.solePixel[1]))
	var points:PackedVector2Array=geometry.vertices.duplicate()
	for edge in leg.soleEdgePixels: points.append(Vector2(float(edge[0]),float(edge[1])))
	var leading:float=-INF
	for pixel in points:
		var offset:Vector3=right*(pixel.x-sole.x)+Vector3(0,0,(sole.y-pixel.y)/float(geometry.vertical))
		if offset.z<0: return {"supported":false,"reason":"original opaque pixels extend below the authored sole"}
		leading=maxf(leading,normal.dot(Vector2(offset.x,offset.y)))
	if not is_finite(leading): return {"supported":false,"reason":"empty original foot geometry"}
	var knots:Array[Vector3]=[from_world]
	var count:=int(profile.steps)
	if count<=0: return {"supported":false,"reason":"invalid tread count"}
	for index in range(count):
		var height:=lerpf(float(profile.from),float(profile.to),float(index+1)/count)
		if height<=from_world.z or height>to_world.z: continue
		var edge_world:Vector3=renderer.ground_point(start.lerp(end,float(index)/count))
		# Put the whole original footprint above the riser before its leading corner crosses.
		var distance:float=(normal.dot(Vector2(edge_world.x-from_world.x,edge_world.y-from_world.y))-leading-.02)/along
		if distance<=0: return {"supported":false,"reason":"riser already overlaps an unraised original foot"}
		if distance>=span: continue
		var point:=from_world+Vector3(tangent.x,tangent.y,0)*distance
		point.z=height
		knots.append(point)
	knots.append(to_world)
	var lengths:=PackedFloat64Array()
	var arc:=0.0
	for index in range(knots.size()-1):
		var length:=knots[index].distance_to(knots[index+1])
		if not is_finite(length) or length<.00001: return {"supported":false,"reason":"degenerate swept-support span"}
		lengths.append(length)
		arc+=length
	var numerator:=1.5*arc+PI*3.0
	var duration:=maxf(minimum,ceilf(numerator/4.9*4.0)*.25)
	return {"supported":true,"valid":is_finite(duration),"curveType":"stair_swept_support","distance":duration,"curveOnly":true,"curveSpeedBound":numerator/duration,"knots":knots,"lengths":lengths,"arcXYZ":arc,"fromWorld":from_world,"toWorld":to_world,"fromLogical":from,"toLogical":to,"originalFootId":str(geometry.id),"originalPoints":points.size(),"leadingOriginalCorner":leading,"physicalRiserNormal":normal,"actorPhaseUnits":"accepted continuous world XY","intermediateWaypointsAreContacts":false,"planeScope":"ascending identity foot plane/current original mask; other modes use labelled legacy curve","baseCertificateIncludesSupportCorrection":false}

static func sample(renderer:Node,plan:Dictionary,u:float) -> Dictionary:
	if not is_finite(u) or u<0 or u>1 or not is_finite(float(plan.arcXYZ)) or float(plan.arcXYZ)<=0: return {"valid":false}
	var remaining:=float(plan.arcXYZ)*u*u*(3.0-2.0*u)
	var knots:Array=plan.knots
	var lengths:PackedFloat64Array=plan.lengths
	if knots.size()<2 or lengths.size()!=knots.size()-1: return {"valid":false}
	var world:=Vector3.ZERO
	for index in range(lengths.size()):
		if not is_finite(lengths[index]) or lengths[index]<=0: return {"valid":false}
		if remaining<=lengths[index] or index==lengths.size()-1:
			world=Vector3(knots[index]).lerp(knots[index+1],clampf(remaining/lengths[index],0,1))
			break
		remaining-=lengths[index]
	if not world.is_finite(): return {"valid":false}
	var seed:=Vector2(plan.fromLogical).lerp(plan.toLogical,u)
	var actual:=FootPlane.ground_below(renderer,seed,world)
	if not bool(actual.valid): return {"valid":false}
	return {"valid":true,"world":world,"logical":actual.logical}
