extends RefCounted

const FootPlane=preload("res://scripts/NalaFootPlane.gd")
const Traversal=preload("res://scripts/SurfaceTraversal.gd")
const STITCH_HEIGHT:=.02

static func build(renderer:Node,profile:Dictionary,from:Vector2,to:Vector2,from_world:Vector3,to_world:Vector3,geometry:Dictionary,minimum:float,carried_resume:bool=false) -> Dictionary:
	var unsupported:Dictionary={"supported":false,"reason":"requires ascending identity sole plane; fresh paths also require zero pivot"}
	if str(profile.get("type",""))!="stairs": return {"supported":false,"reason":"requires an authored stair connector"}
	var plane:Quaternion=geometry.plane
	var right:Vector3=geometry.right
	if not is_finite(float(geometry.vertical)) or not right.is_finite() or not Vector3(geometry.pivot).is_finite() or absf(right.length()-1.0)>.001 or not plane.is_finite(): return {"supported":false,"reason":"invalid source basis"}
	if not is_finite(float(profile.from)) or not is_finite(float(profile.to)) or float(profile.to)<=float(profile.from): return {"supported":false,"reason":"requires canonical ascending profile"}
	var pivot:Vector3=geometry.pivot
	if plane.angle_to(Quaternion.IDENTITY)>.0001 or (not carried_resume and pivot.length()>.0001) or absf(right.z)>.0001: return unsupported
	if not from_world.is_finite() or not to_world.is_finite() or float(geometry.vertical)<=0 or to_world.z<=from_world.z+.01: return unsupported
	if carried_resume:
		if not geometry.has("bodyLeg") or int(geometry.get("bodyFootViewSteps",8)) not in [0,1]: return {"supported":false,"reason":"carried resume requires current or adjacent original foot view"}
		var current:Dictionary=geometry.leg
		var body:Dictionary=geometry.bodyLeg
		var current_ankle_z:float=float(current.solePixel[1])-float(current.ankle[1])+float(current.parts.foot[1])
		var body_ankle_z:float=float(body.solePixel[1])-float(body.ankle[1])+float(body.parts.foot[1])
		if absf(current_ankle_z-body_ankle_z)>.0001: return {"supported":false,"reason":"carried resume requires equal original vertical ankle offsets"}
		var actual_from:=Traversal.connector_ground(profile,from)
		var actual_to:=Traversal.connector_ground(profile,to)
		if actual_from.is_empty() or actual_to.is_empty() or float(actual_to.groundHeight)<=float(actual_from.groundHeight): return {"supported":false,"reason":"carried resume requires real ascending tread membership"}
		if not FootPlane.airborne_clear(renderer,from,geometry,from_world+pivot,plane): return {"supported":false,"reason":"current original carried foot is not airborne-clear"}
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
	if carried_resume: leading+=maxf(0,normal.dot(Vector2(pivot.x,pivot.y)))
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
		point.z=height-minf(0,pivot.z) if carried_resume else height
		knots.append(point)
	knots.append(to_world)
	var lengths:=PackedFloat64Array()
	var arc:=0.0
	for index in range(knots.size()-1):
		var length:=knots[index].distance_to(knots[index+1])
		if not is_finite(length) or length<.00001: return {"supported":false,"reason":"degenerate swept-support span"}
		lengths.append(length)
		arc+=length
	var pivot_reserve:=pivot.length()+4.0*STITCH_HEIGHT+absf(pivot.z) if carried_resume else 0.0
	var numerator:=1.5*arc+PI*3.0+pivot_reserve
	var duration:=maxf(minimum,ceilf(numerator/4.9*4.0)*.25)
	return {"supported":true,"valid":is_finite(duration),"curveType":"stair_swept_support","distance":duration,"curveOnly":true,"curveSpeedBound":numerator/duration,"knots":knots,"lengths":lengths,"arcXYZ":arc,"fromWorld":from_world,"toWorld":to_world,"fromLogical":from,"toLogical":to,"originalFootId":str(geometry.id),"originalPoints":points.size(),"leadingOriginalCorner":leading,"physicalRiserNormal":normal,"actorPhaseUnits":"accepted continuous world XY","intermediateWaypointsAreContacts":false,"planeScope":"ascending identity foot plane/current original mask; other modes use labelled legacy curve","baseCertificateIncludesSupportCorrection":false,"carriedResume":carried_resume,"initialPivot":pivot,"initialPivotAndStitchReserve":pivot_reserve,"floorStitch":"continuous_quadratic" if carried_resume else "legacy_constant","futureViewChangesIncludedInCertificate":false}

static func view_envelope(plan:Dictionary,geometry:Dictionary,correction:Vector3,plane:Quaternion) -> Dictionary:
	if str(plan.get("curveType",""))!="stair_swept_support": return {"supported":true,"scope":"not a frozen swept stair"}
	if not correction.is_finite() or not plane.is_finite() or plane.angle_to(Quaternion.IDENTITY)>.0001: return {"supported":false,"reason":"frozen stair view requires identity plane and finite pivot"}
	var normal:Vector2=plan.physicalRiserNormal
	var right:Vector3=geometry.right
	var vertical:float=geometry.vertical
	if not normal.is_finite() or not right.is_finite() or not is_finite(vertical) or vertical<=0: return {"supported":false,"reason":"invalid original source basis"}
	var sole:=Vector2(float(geometry.leg.solePixel[0]),float(geometry.leg.solePixel[1]))
	var leading:float=-INF
	var minimum_z:float=INF
	var points:PackedVector2Array=geometry.vertices.duplicate()
	for edge in geometry.leg.soleEdgePixels: points.append(Vector2(float(edge[0]),float(edge[1])))
	for pixel in points:
		var offset:=right*(float(pixel.x)-sole.x)+Vector3(0,0,(sole.y-float(pixel.y))/vertical)
		leading=maxf(leading,normal.dot(Vector2(offset.x,offset.y)))
		minimum_z=minf(minimum_z,offset.z)
	# C decays toward zero: use its worst one-sided envelope over the remaining path.
	leading+=maxf(0,normal.dot(Vector2(correction.x,correction.y)))
	minimum_z+=minf(0,correction.z)
	var old_minimum:=minf(0,Vector3(plan.get("initialPivot",Vector3.ZERO)).z)
	var allowed:bool=is_finite(leading) and is_finite(minimum_z) and leading<=float(plan.leadingOriginalCorner) and minimum_z>=old_minimum
	return {"supported":allowed,"scope":"remaining frozen ascending riser envelope; actual full-mask guards remain independent","leading":leading,"plannedLeading":plan.leadingOriginalCorner,"minimumZ":minimum_z,"plannedMinimumZ":old_minimum}

static func floor_stitch(plan:Dictionary,u:float) -> float:
	if not bool(plan.get("carriedResume",false)): return STITCH_HEIGHT
	return 4.0*STITCH_HEIGHT*u*(1.0-u)+maxf(0,-Vector3(plan.initialPivot).z*(1.0-u))

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
