extends RefCounted

static func vertices(node: Node, parent:=Transform3D.IDENTITY) -> PackedVector3Array:
	var transform:=parent
	if node is Node3D: transform*=node.transform
	var result:=PackedVector3Array()
	if node is MeshInstance3D and node.mesh:
		for surface in range(node.mesh.get_surface_count()):
			var arrays: Array=node.mesh.surface_get_arrays(surface)
			for point in arrays[Mesh.ARRAY_VERTEX]: result.append(transform*point)
	for child in node.get_children(): result.append_array(vertices(child,transform))
	return result

static func projected(point: Vector3, tilt: float) -> Vector2:
	return Vector2(point.x,-point.y+sin(tilt)*point.z)

static func front_at(mesh: MeshInstance3D, at: Vector2, tilt: float) -> Variant:
	var start:=Vector3(at.x,-at.y+sin(tilt)*1000,1000)
	var end:=Vector3(at.x,-at.y-sin(tilt)*1000,-1000)
	var nearest: Variant=null
	for surface in range(mesh.mesh.get_surface_count()):
		var arrays: Array=mesh.mesh.surface_get_arrays(surface)
		var points: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
		var count:=indices.size() if not indices.is_empty() else points.size()
		for offset in range(0,count,3):
			var a: Vector3=mesh.transform*points[indices[offset] if not indices.is_empty() else offset]
			var b: Vector3=mesh.transform*points[indices[offset+1] if not indices.is_empty() else offset+1]
			var c: Vector3=mesh.transform*points[indices[offset+2] if not indices.is_empty() else offset+2]
			var hit: Variant=Geometry3D.segment_intersects_triangle(start,end,a,b,c)
			if hit is Vector3 and (nearest==null or hit.z>nearest.z): nearest=hit
	return nearest

static func solve(terrain: Node3D, world: Dictionary, model: Node3D, at: Vector2, tilt: float) -> Dictionary:
	var points:=vertices(model)
	if points.is_empty(): return {"supported":false,"reason":"empty_model"}
	var rear: Vector3=points[0]
	var maximum:=rear.z
	for point in points:
		if point.z<rear.z:rear=point
		maximum=maxf(maximum,point.z)
	for index in range(world.get("terrainContours",[]).size()):
		var polygon:=PackedVector2Array()
		for point in world.terrainContours[index]:polygon.append(Vector2(point[0],point[1]))
		if not Geometry2D.is_point_in_polygon(at,polygon):continue
		var inside:=true
		for point in points:
			if not Geometry2D.is_point_in_polygon(at+projected(point,tilt),polygon):inside=false;break
		if not inside:continue
		var mesh:=terrain.get_node_or_null("ReefRelief%d"%index) as MeshInstance3D
		if mesh==null:continue
		var anchor:=at+projected(rear,tilt)
		var hit: Variant=front_at(mesh,anchor,tilt)
		if hit==null:continue
		var overlap:=clampf((maximum-rear.z)*.55,2.0,32.0)
		var depth: float=hit.z-rear.z-overlap
		var contact:=Vector3(at.x,-at.y+sin(tilt)*depth,depth)+rear
		return {"supported":true,"terrain":index,"at":[at.x,at.y],"depth":depth,"rearVertex":[rear.x,rear.y,rear.z],"contact":[contact.x,contact.y,contact.z],"surface":[hit.x,hit.y,hit.z],"penetration":overlap,"modelDepthRange":[rear.z,maximum],"allVerticesWithinTerrain":true}
	return {"supported":false,"at":[at.x,at.y],"reason":"no_existing_support_or_model_outside_footprint"}
