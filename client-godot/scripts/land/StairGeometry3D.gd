extends RefCounted

const Traversal = preload("res://scripts/SurfaceTraversal.gd")

static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]),float(value[1]))

static func contact_point(renderer: Node,profile: Dictionary,logical: Vector2) -> Vector3:
	var sample:=Traversal.connector_ground(profile,logical)
	assert(not sample.is_empty())
	var linear_height:=lerpf(float(profile.from),float(profile.to),float(sample.progress))
	var point: Vector3=renderer.map_point(logical,linear_height)
	point.z=float(sample.groundHeight)
	return point

static func logical_from_contact(renderer: Node,profile: Dictionary,point: Vector3) -> Vector2:
	var start: Vector2=profile.start
	var end: Vector2=profile.end
	var gradient: Vector2=(end-start)*(float(profile.to)-float(profile.from))/float(profile.lengthSquared)
	var tilt: float=renderer.TILT
	var denominator:=1.0/cos(tilt)+tan(tilt)*gradient.y
	if absf(denominator)<.000001: return Vector2.INF
	var y:=-(point.y+tan(tilt)*(float(profile.from)+gradient.x*(point.x-start.x)-gradient.y*start.y))/denominator
	var logical:=Vector2(point.x,y)
	var sample:=Traversal.connector_ground(profile,logical)
	if sample.is_empty() or absf(float(sample.groundHeight)-point.z)>.01: return Vector2.INF
	return logical

static func _boundary(renderer: Node,logical: Vector2,linear_height: float,tread_height: float) -> Vector3:
	var point: Vector3=renderer.map_point(logical,linear_height)
	point.z=tread_height
	return point

static func _xyz(point: Vector3) -> Array:
	return [point.x,point.y,point.z]

static func build(renderer: Node,stair: Dictionary) -> Dictionary:
	var profile:=Traversal.connector_profile(stair,renderer._level(str(stair.from)),renderer._level(str(stair.to)))
	var a: Vector2=profile.start
	var b: Vector2=profile.end
	var tangent: Vector2=(b-a).normalized()
	var side:=Vector2(-tangent.y,tangent.x)*float(stair.width)*.5
	var lower:=float(profile.from)
	var upper:=float(profile.to)
	var stairs:=str(stair.type)=="stairs"
	var count:=int(profile.steps) if stairs else 1
	var material: Material=renderer._materials.get_material(str(stair.get("material","stone")))
	var treads: Array=[]
	for index in range(count):
		var begin:=float(index)/count
		var finish:=float(index+1)/count
		var start:=a.lerp(b,begin)
		var end:=a.lerp(b,finish)
		var previous:=lerpf(lower,upper,begin)
		var top:=lerpf(lower,upper,finish)
		var start_height:=top if stairs else previous
		# XY follows one continuous connector plane; a height jump must not shear each tread backwards.
		var left_start:=_boundary(renderer,start-side,previous,start_height)
		var right_start:=_boundary(renderer,start+side,previous,start_height)
		var left_end:=_boundary(renderer,end-side,top,top)
		var right_end:=_boundary(renderer,end+side,top,top)
		var vertices: Array[Vector3]=[left_start,right_start,right_end,left_end]
		renderer._face("Tread",vertices,material)
		var serialized: Array=[]
		for point in vertices: serialized.append(_xyz(point))
		treads.append({"index":index,"height":top,"vertices":serialized})
		if stairs:
			var left_bottom:=Vector3(left_start.x,left_start.y,previous)
			var right_bottom:=Vector3(right_start.x,right_start.y,previous)
			var riser: Array[Vector3]=[left_start,right_start,right_bottom,left_bottom]
			renderer._face("Riser",riser,material)
		var base:=minf(lower,upper)-12
		var left_base_start:=Vector3(left_start.x,left_start.y,base)
		var left_base_end:=Vector3(left_end.x,left_end.y,base)
		var right_base_start:=Vector3(right_start.x,right_start.y,base)
		var right_base_end:=Vector3(right_end.x,right_end.y,base)
		var left_cheek: Array[Vector3]=[left_start,left_end,left_base_end,left_base_start]
		var right_cheek: Array[Vector3]=[right_end,right_start,right_base_start,right_base_end]
		renderer._face("StairSideCheek",left_cheek,material)
		renderer._face("StairSideCheek",right_cheek,material)
	return {"id":str(stair.id),"type":str(stair.type),"count":count,"treads":treads}
