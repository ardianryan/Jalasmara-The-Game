extends RefCounted

const FootPlane=preload("res://scripts/NalaFootPlane.gd")
const SAMPLE_COUNT:=32
const CANDIDATE_COUNT:=65

static func _common_height(hips:Dictionary,ankles:Dictionary,radii:Dictionary,lower:float,upper:float) -> bool:
	var allowed:Array[Vector2]=[Vector2(lower,upper)]
	for side in ["left","right"]:
		var ankle:Vector3=ankles[side]
		var horizontal:float=Vector2(hips[side].x-ankle.x,hips[side].y-ankle.y).length_squared()
		var limb:Vector2=radii[side]
		if horizontal>=limb.y*limb.y: return false
		var extent:=sqrt(limb.y*limb.y-horizontal)
		var remaining:Array[Vector2]=[]
		for interval in allowed:
			var first:=maxf(interval.x,ankle.z-extent)
			var last:=minf(interval.y,ankle.z+extent)
			if first>last: continue
			if horizontal>=limb.x*limb.x: remaining.append(Vector2(first,last))
			else:
				var hole:=sqrt(limb.x*limb.x-horizontal)
				if first<=minf(last,ankle.z-hole): remaining.append(Vector2(first,minf(last,ankle.z-hole)))
				if maxf(first,ankle.z+hole)<=last: remaining.append(Vector2(maxf(first,ankle.z+hole),last))
		allowed=remaining
		if allowed.is_empty(): return false
	return true

static func _path(knots:Array,lengths:PackedFloat64Array,total:float,fraction:float) -> Dictionary:
	var distance:=total*fraction
	for index in range(lengths.size()):
		var length:float=lengths[index]
		if distance<=length or index==lengths.size()-1:
			var weight:=clampf(distance/maxf(.000001,length),0,1)
			return {"world":Vector3(knots[index].world).lerp(knots[index+1].world,weight),"logical":Vector2(knots[index].logical).lerp(knots[index+1].logical,weight)}
		distance-=length
	return {}

static func propose(renderer:Node,plan:Dictionary,side:String,feet:Dictionary,geometry:Dictionary,at:Vector2,heading:Vector3,body_height:float,body_rate:float) -> Dictionary:
	var started:=Time.get_ticks_usec()
	var result:Dictionary={"valid":false,"conditionalPreview":true,"mode":"descending_ramp_restart","markerQueries":0,"samples":SAMPLE_COUNT,"candidates":CANDIDATE_COUNT,"frozenLandingChanged":false,"frozenTarget":plan.toWorld,"fullMaskProof":false}
	var foot:Dictionary=geometry[side]
	var vertical:float=foot.vertical
	var right:Vector3=foot.right
	var knots:Array=plan.groundKnots
	var lengths:=PackedFloat64Array()
	var total:=0.0
	var floor_height:=INF
	for knot in knots: floor_height=minf(floor_height,Vector3(knot.world).z)
	for index in range(knots.size()-1):
		var first:Vector3=knots[index].world
		var second:Vector3=knots[index+1].world
		var length:=Vector2(second.x-first.x,second.y-first.y).length()
		lengths.append(length)
		total+=length
	var rotation:Quaternion=foot.plane
	var target:=FootPlane.contact_rotation(renderer,knots[-1].logical,right)
	var correction:Vector3=foot.pivot
	var radius:=FootPlane.radius_about_ankle(foot.leg,vertical)
	var marker_geometry:Dictionary=foot.duplicate()
	marker_geometry.vertices=PackedVector2Array()
	var source_leg:Dictionary=foot.leg
	var markers:Array=source_leg.soleEdgePixels
	var origin:Vector3=renderer.ground_point(at)
	var radii:Dictionary={}
	var hip_offsets:Dictionary={}
	var support_ankles:Dictionary={}
	for limb_side in ["left","right"]:
		var current:Dictionary=geometry[limb_side]
		var leg:Dictionary=current.bodyLeg
		var hip:=Vector2(float(leg.hip[0]),float(leg.hip[1]))
		var knee:=Vector2(float(leg.knee[0]),float(leg.knee[1]))
		var ankle:=Vector2(float(leg.ankle[0]),float(leg.ankle[1]))
		var first:=hip.distance_to(knee)/vertical
		var second:=knee.distance_to(ankle)/vertical
		radii[limb_side]=Vector2(absf(first-second),first+second-.1)
		hip_offsets[limb_side]=right*(hip.x-64.0)
		support_ankles[limb_side]=Vector3(feet[limb_side].sole)+Vector3(current.pivot)+FootPlane.ankle_offset(current,current.plane)
	var cached:Array[Vector3]=[]
	var base:float=plan.distance
	for index in range(1,SAMPLE_COUNT+1):
		var u:=float(index)/SAMPLE_COUNT
		var previous:=float(index-1)/SAMPLE_COUNT
		var smooth:=u*u*(3.0-2.0*u)
		var path:=_path(knots,lengths,total,smooth)
		if path.is_empty(): break
		correction*=(1.0-u)/maxf(.000001,1.0-previous)
		var raw:Vector3=path.world
		raw.z+=float(plan.fromGroundOffset)*(1.0-smooth)+sin(u*PI)*3.0
		var ankle:=raw+correction+FootPlane.ankle_offset(foot,rotation)
		var next:=FootPlane.advance(rotation,target,base/SAMPLE_COUNT,radius)
		var support:=FootPlane.ankle_support(renderer,path.logical,marker_geometry,ankle,next)
		result.markerQueries+=markers.size()
		if not bool(support.valid): break
		ankle.z=float(support.height)+maxf(.02,3.0*sin(u*PI)+float(plan.fromSupportOffset)*(1.0-smooth))
		correction+=FootPlane.ankle_offset(foot,rotation)-FootPlane.ankle_offset(foot,next)
		rotation=next
		if index==SAMPLE_COUNT: ankle=Vector3(knots[-1].world)+FootPlane.ankle_offset(foot,rotation)
		cached.append(ankle)
	if cached.size()==SAMPLE_COUNT:
		for candidate in range(CANDIDATE_COUNT):
			var distance:=ceilf(base*4.0)*.25+candidate*.25
			var fits:=true
			for index in range(SAMPLE_COUNT):
				var accepted:=distance*float(index+1)/SAMPLE_COUNT
				var actor:=origin+heading*accepted
				var hips:Dictionary={}
				var ankles:=support_ankles.duplicate()
				ankles[side]=cached[index]
				for limb_side in ["left","right"]: hips[limb_side]=actor+Vector3(hip_offsets[limb_side])
				var optimistic:=maxf(floor_height,body_height-body_rate*accepted)
				if not _common_height(hips,ankles,radii,optimistic+20.0/vertical,optimistic+28.0/vertical):
					fits=false
					break
			if fits:
				result.valid=true
				result.distance=distance
				result.testedCandidates=candidate+1
				break
	result.elapsedMicroseconds=Time.get_ticks_usec()-started
	result.originalDistance=base
	return result
